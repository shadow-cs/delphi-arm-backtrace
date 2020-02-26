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

{$LEGACYIFEND ON}

{$IF (Defined(CPUX86) OR Defined(CPUX64)) AND Defined(POSIX)}
  {$DEFINE INTELABI} // x32 ABI or System V (AMD64) ABI
{$IFEND}

type
  TBacktraceMode = (bmARM, bmIntelABI, bmLibc);

const
  BacktraceMode =
{$IF Defined(CPUARM) AND (Defined(ANDROID) OR Defined(IOS))}
    bmARM
{$ELSEIF Defined(MACOS)}
    bmLibc
  {$IFDEF CPUX86}
    {$DEFINE EXC_BACKTRACE}
  {$ENDIF}
{$ELSEIF Defined(POSIX) AND Defined(INTELABI)}
    // Libc - Causes segfault
    bmIntelABI
{$ELSE}
  {$MESSAGE FATAL 'Unsupported OS'}
{$IFEND}
  ;
  BacktraceSupportsIgnore = BacktraceMode in [bmARM, bmIntelABI];

function StackWalk(Data: PPointer; Size, IgnoredFrames: Integer): Integer; inline;
// execinfo.h shadow procedure
function backtrace(buffer: PPointer; size: Integer
  {$IF BacktraceSupportsIgnore}; ignored: Integer = 0{$IFEND}): Integer;
  {$IF BacktraceMode = bmLibc}cdecl;{$IFEND}
{$IFDEF EXC_BACKTRACE}
// Exception stack frame gets corrupted while handling exceptions and own
// backtrace have to be used
function backtrace2(base: NativeUInt; buffer: PPointer; size: Integer;
  ignored: Integer = 0): Integer;
{$ENDIF}

{$IF BacktraceMode = bmLibc}
function backtrace_symbols(buffer: PPointer; size: Integer): PPointer{PPAnsiChar}; cdecl;
procedure backtrace_symbols_free(ptr: Pointer); cdecl;
{$IFEND}

implementation

{$IF BacktraceMode = bmLibc}
uses
  Posix.Base;
{$IFEND}

{$IFDEF INTELABI}
function ABIX86_64Backtrace(base: NativeUInt; buffer: PPointer;
  size: Integer; ignored: Integer): Integer;
const
  STACK_MAX_SIZE = 2 * 1024 * 1024;
var
  SPMin: NativeUInt;
begin
  SPMin := base;
  Result := 0;
  while (size > 0) and (base >= SPMin) and (base <> 0) do
  begin
    // We can rewrite the buffer as long as we don't increment Result during
    // ignoring.
    buffer^ := PPointer(base + SizeOf(Pointer))^;
    base := PNativeInt(base)^;
    if ignored > 0 then
    begin
      Dec(ignored);
      Continue;
    end;

    Inc(Result);

    Inc(buffer);
    Dec(size);
  end;
  if (size > 0) then
    buffer^ := nil;
end;

{$IFDEF CPUX86}
function GetESP: Pointer;
asm
  mov eax, ebp
end;
{$ENDIF CPUX64}

{$IFDEF CPUX64}
function GetRSP: Pointer;
begin
  // Grab RBP of this frame.
  Result := PByte(@Result) + 8;
  // Return RBP of previous frame.
  Result := PPointer(Result)^;
end;
{$ENDIF CPUX64}
{$ENDIF INTELABI}

{$IF BacktraceMode = bmARM}
const BacktraceLibName = 'backtrace.o';
function get_frame: NativeUInt; cdecl; external BacktraceLibName;
{$WARN SYMBOL_PLATFORM OFF}
{$LINK BacktraceLibName}
{$WARN SYMBOL_PLATFORM ON}

function backtrace(buffer: PPointer; size: Integer; ignored: Integer): Integer;
const
  MEM_MASK = $FFF00000;
  STACK_MAX_SIZE = 2 * 1024 * 1024; // Default UNIX stack size
var
  FP: NativeUInt;
  LR: Pointer;
  SPMax: NativeUInt;
  SPMin: NativeUInt;
begin
  // Push instruction decrements SP, we're walking stack up
  FP := get_frame;
  SPMin := FP;
  SPMax := SPMin + STACK_MAX_SIZE;
  Result := 0;
  // FP = nil should indicate parent most Stack Frame
  while (size > 0) and (FP <= SPMax) and (FP >= SPMin) and (FP <> 0{nil}) do
  begin
    // This is how Delphi compiler uses stack, but depends on ABI.
    // Delphi probably uses R7 as Frame pointer since it is the least register
    // accessible by THUMB (16-bit) instructions in comparison to ARM (32-bit)
    // instructions see backtrace.c.
    LR := PPointer(FP + 4)^;
    FP := PNativeUInt(FP)^;
    if ignored > 0 then
    begin
      Dec(ignored);
      Continue;
    end;

    // LR is set to PC + 3 (branch instruction size is 2 and is adjusted for
    // prefetch).
    NativeUInt(buffer^) := NativeUInt(LR) - 3;
    Inc(Result);

    Inc(buffer);
    Dec(size);
  end;
  if (size > 0) then
    buffer^ := nil;
end;
{$IFEND ARM}

{$IF BacktraceMode = bmIntelABI}
function backtrace(buffer: PPointer; size: Integer; ignored: Integer): Integer;
begin
  Result := ABIX86_64Backtrace(NativeUInt(GetRSP), buffer, size, ignored);
end;
{$IFEND INTELABI}

{$IF BacktraceMode = bmLibc}
function backtrace; external libc name _PU + 'backtrace';
function backtrace_symbols; external libc name _PU + 'backtrace_symbols';
procedure backtrace_symbols_free; external libc name _PU + 'free';
{$IFEND}

{$IFDEF EXC_BACKTRACE}
function backtrace2(base: NativeUInt; buffer: PPointer; size, ignored: Integer): Integer;
begin
  Result := ABIX86_64Backtrace(base, buffer, size, ignored);
end;
{$ENDIF}

function StackWalk(Data: PPointer; Size, IgnoredFrames: Integer): Integer; inline;
begin
{$IF BacktraceSupportsIgnore}
  Result := backtrace(Data, Size, IgnoredFrames);
{$ELSE}
  Result := backtrace(Data, Size);
  if IgnoredFrames > 0 then
  begin
    if Result <= IgnoredFrames then
      Exit(0);
    Move(PPointer(NativeInt(Data) + (IgnoredFrames * SizeOf(Pointer)))^, Data^,
      (Result - IgnoredFrames) * SizeOf(Pointer));
    Dec(Result, IgnoredFrames);
  end;
{$IFEND}
end;

end.
