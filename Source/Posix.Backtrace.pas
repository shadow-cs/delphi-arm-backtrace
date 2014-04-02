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

unit Posix.Backtrace;

interface

{$IFDEF CPUARM}
function StackWalk(Data : PPointer; Count : Integer) : Integer;
// execinfo.h shadow procedure
function backtrace(buffer : PPointer; size : Integer) : Integer; inline;
{$ENDIF CPUARM}

implementation

{$IFDEF CPUARM}
{$IFDEF ANDROID}
const BacktraceLibName = 'backtrace.o';
{$ELSE ANDROID}
	{$MESSAGE FATAL 'Platform not supported'}
{$ENDIF ANDROID}

{$WARN SYMBOL_PLATFORM OFF}
{$LINK LibName}
{$WARN SYMBOL_PLATFORM ON}

function get_frame : NativeUInt; cdecl; external BacktraceLibName;

function StackWalk(Data : PPointer; Count : Integer) : Integer;
const
	MEM_MASK = $FFF00000;
	STACK_MAX_SIZE = 2 * 1024 * 1024; //Default UNIX stack size
var FPp	: Pointer;
	FP	: NativeUInt absolute FPp;
	LR	: Pointer;
	SPMax : NativeUInt;
	SPMin : NativeUInt;
begin
	//Push instruction decrements SP, we're walking stack up
	FP:=get_frame;
	SPMin:=FP;
	SPMax:=SPMin + STACK_MAX_SIZE;
	Result:=0;
	//FP = nil should indicate parent most Stack Frame
	while (Count > 0) and (FP <= SPMax) and (FP >= SPMin) and (FP <> 0{nil}) do begin
		//This is how Delphi compiler uses stack, but depends on ABI
		//Delphi probably uses R7 as Frame pointer since it is the least register
		//accessible by THUMB (16-bit) instructions in comparison to ARM (32-bit)
		//instructions see backtrace.c
		LR:=PPointer(FP + 4)^;
		FP:=PNativeUInt(FP)^;

		NativeUInt(Data^):=NativeUInt(LR) - 3; //LR is set to PC + 3 (branch instruction size is 2 and is adjusted for prefetch)
		Inc(Result);

		Inc(Data);
		Dec(Count);
	end;
	if (Count > 0) then Data^:=nil;
end;

function backtrace(buffer : PPointer; size : Integer) : Integer; inline;
begin
	Result:=StackWalk(buffer, size);
end;

{$ENDIF CPUARM}

end.
