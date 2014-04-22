{******************************************************************************}
{                                                                              }
{            Copyright (c) 2014 Jan Rames                                      }
{                                                                              }
{******************************************************************************}
{                                                                              }
{            This Source Code Form is subject to the terms of the              }
{                                                                              }
{                       Mozilla Public License, v. 2.0.                        }
{                                                                              }
{            If a copy of the MPL was not distributed with this file,          }
{            You can obtain one at http://mozilla.org/MPL/2.0/.                }
{                                                                              }
{******************************************************************************}

unit Posix.ExceptionUtil;

interface

uses
	System.SysUtils,
	Posix.Proc;

type
	PExceptionStackInfo = ^TExceptionStackInfo;
	TExceptionStackInfo = record
	private const
		STACK_SKIP	= 5; //Number of frames to drop (our and Delphi internals)
		STACK_DEPTH = 32;
		STACK_ALL	= STACK_SKIP + STACK_DEPTH;
	private class var
{$IF Defined(ANDROID) OR Defined(IOS)}
		FProcEntries	: TPosixProcEntryList;
{$ENDIF}
	private
		class function GetExceptionStackInfoProc(P: PExceptionRecord): Pointer; static;
		class function GetStackInfoStringProc(Info: Pointer): string; static;
		class procedure CleanUpStackInfoProc(Info: Pointer); static;
	public
		class procedure Attach; static;
		class procedure Detach; static;
		class function GetSymbols(Stack : PPointer; Count : Integer) : string; static;
	private
		Count	: Integer;
		Stack	: array[0..STACK_ALL - 1] of Pointer;
	end;

implementation

{$IFDEF POSIX}
uses
	Posix.Backtrace;
{$ELSE}
	{$MESSAGE FATAL 'Unsupported OS'}
{$ENDIF}

threadvar
	//Incremented by each internal handler, we don't want our code to be called
	//if there is an exception in it (there should be none only in extreme
	//cases like stack overflow and out of memory situations - in which the
	//application will most likely crash anyway)
	HandlingException : Integer;


{ TExceptionStackInfo }

class procedure TExceptionStackInfo.Attach;
begin
	Exception.GetExceptionStackInfoProc:=GetExceptionStackInfoProc;
	Exception.CleanUpStackInfoProc:=CleanUpStackInfoProc;
	Exception.GetStackInfoStringProc:=GetStackInfoStringProc;
end;

class procedure TExceptionStackInfo.Detach;
begin
	Exception.GetExceptionStackInfoProc:=nil;
	Exception.CleanUpStackInfoProc:=nil;
	Exception.GetStackInfoStringProc:=nil;
end;

class function TExceptionStackInfo.GetExceptionStackInfoProc(
  P: PExceptionRecord): Pointer;
var Info	: PExceptionStackInfo absolute Result;
{$IF Defined(MACOS) AND Defined(CPUX86)}
	b		: NativeUInt;
{$ENDIF}
begin
	if (HandlingException <> 0) then Exit(nil);

	Inc(HandlingException);
	try
		New(Info);
{$IF Defined(MACOS) AND Defined(CPUX86)}
		asm
			mov b, ebp
		end;
		//We know there is invalid stack frame so we need to correct it by
		//0x14 bytes which is compiler dependant value
		Info^.Count:=backtrace2(b + $14, @Info^.Stack, STACK_ALL);
{$ELSE}
		Info^.Count:=StackWalk(@Info^.Stack, STACK_ALL);
{$ENDIF}
	except
		//Shouldn't happen but still we'll rather have a small leak then stop
		//exception propagation
		Result:=nil;
	end;
	Dec(HandlingException);
end;

class procedure TExceptionStackInfo.CleanUpStackInfoProc(Info: Pointer);
begin
	Dispose(PExceptionStackInfo(Info));
end;

class function TExceptionStackInfo.GetStackInfoStringProc(
  Info: Pointer): string;
begin
	//This should be called from outside of raise exception system call
	if (Info = nil) then Exit('');
	if (HandlingException <> 0) then Exit('');
	if (PExceptionStackInfo(Info)^.Count <= 0) then Exit('');

	Inc(HandlingException);
	try
		Result:=GetSymbols(@PExceptionStackInfo(Info)^.Stack,
			PExceptionStackInfo(Info)^.Count);
	finally
		Dec(HandlingException);
	end;
end;

class function TExceptionStackInfo.GetSymbols(Stack: PPointer;
  Count: Integer): string;
{$IF Defined(MACOS) AND NOT Defined(IOS)}
var Res	: PPointer;
	P	: PPointer;
	i	: Integer;
{$ENDIF}
begin
{$IF Defined(ANDROID) OR Defined(IOS)}
	//TODO threadsafe
	if (FProcEntries = nil) then begin
		FProcEntries:=TPosixProcEntryList.Create;
		FProcEntries.LoadFromCurrentProcess;
	end;
	Result:=FProcEntries.ConvertStackTrace(Stack, STACK_SKIP,
		Count - STACK_SKIP);
{$ELSEIF Defined(MACOS)}
	Res:=backtrace_symbols(Stack, Count);
	try
		P:=Res;
		Result:='';
		for i:=1 to Count do begin
			if (i > 1) then Result:=Result + #$A;
			Result:=Result + UTF8ToString(P^);
			Inc(P);
		end;
	finally
		backtrace_symbols_free(Res);
	end;
{$ELSE}
	{$MESSAGE FATAL 'Unsupported OS'}
{$ENDIF}
end;

end.
