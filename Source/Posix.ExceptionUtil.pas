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

{$IFDEF CPUARM}
type
	PExceptionStackInfo = ^TExceptionStackInfo;
	TExceptionStackInfo = record
	private const
		STACK_SKIP	= 5; //Number of frames to drop (our and Delphi internals)
		STACK_DEPTH = 32;
		STACK_ALL	= STACK_SKIP + STACK_DEPTH;
	private class var
		FProcEntries	: TPosixProcEntryList;
	private
		class function GetExceptionStackInfoProc(P: PExceptionRecord): Pointer; static;
		class function GetStackInfoStringProc(Info: Pointer): string; static;
		class procedure CleanUpStackInfoProc(Info: Pointer); static;
	public
		class procedure Attach; static;
		class procedure Detach; static;
	private
		Count	: Integer;
		Stack	: array[0..STACK_ALL - 1] of Pointer;
	end;
{$ENDIF CPUARM}

implementation

{$IFDEF CPUARM}
uses
	Posix.Backtrace;

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
begin
	if (HandlingException <> 0) then Exit(nil);

	Inc(HandlingException);
	try
		New(Info);
		Info^.Count:=StackWalk(@Info^.Stack, STACK_ALL);
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

	Inc(HandlingException);
	try
		//TODO threadsafe
		if (FProcEntries = nil) then begin
			FProcEntries:=TPosixProcEntryList.Create;
			FProcEntries.LoadFromCurrentProcess;
		end;
		Result:=FProcEntries.ConvertStackTrace(@PExceptionStackInfo(Info)^.Stack,
			STACK_SKIP, PExceptionStackInfo(Info)^.Count - STACK_SKIP);
	finally
		Dec(HandlingException);
	end;
end;
{$ENDIF CPUARM}


end.
