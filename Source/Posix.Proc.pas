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

unit Posix.Proc;

interface

uses
	System.SysUtils,
	System.Math,
	System.Classes,
	System.Generics.Defaults,
	System.Generics.Collections,
	System.RegularExpressions;

type
	TPosixProcEntryPermissions = set of (peRead, peWrite, peExecute, peShared,
		pePrivate {copy on write});

	TPosixProcEntry = record
		RangeStart,
		RangeEnd	: NativeUInt;
		Perms		: TPosixProcEntryPermissions;
		Path		: string;
	end;
	PPosixProcEntry = ^TPosixProcEntry;

	TPosixProcEntryList = class
	private type
		TPosixProcEntryComparer = class(TInterfacedObject, IComparer<TPosixProcEntry>)
		public
			function Compare(const Left, Right: TPosixProcEntry): Integer;
		end;
	private class var
		FComparer	: IComparer<TPosixProcEntry>;
		FRegExp		: TRegEx;
	private
		FList		: TArray<TPosixProcEntry>;
	protected
		function ProcessLine(const Line : string; out Entry : TPosixProcEntry) : Boolean;
	public
		constructor Create;
		procedure LoadFromStrings(const Str : TStrings);
{$IFDEF POSIX}
		procedure LoadFromCurrentProcess;
{$ENDIF}
		function FindEntry(const Address : NativeUInt) : PPosixProcEntry;
		///<summary>
		///    Return symbol address and file name
		///</summary>
		function GetStackLine(const Address : NativeUInt) : string;
		function ConvertStackTrace(Stack : PPointer; Offset, Count : Integer) : string;
	end;

{$IFDEF POSIX}
procedure LoadProcMaps(const Maps : TStrings);
{$ENDIF}

implementation

{$IFDEF POSIX}
procedure LoadProcMaps(const Maps : TStrings);
var st	: TFileStream;
	b	: TBytes;
	i	: Integer;
	s	: string;
begin
	//We cannot get sream size so we have to copy manually
	st:=TFileStream.Create('/proc/self/maps', fmOpenRead);
	SetLength(b, 1024);
	repeat
		i:=st.Read(b, 1024);
		s:=s + TEncoding.ANSI.GetString(b, 0, i);
	until (i < Length(b));
	Maps.Text:=s;
end;
{$ENDIF}

{ TPosixProcEntryList }

{$ZEROBASEDSTRINGS OFF}
function TPosixProcEntryList.ConvertStackTrace(Stack : PPointer;
	Offset, Count: Integer): string;
const EOL = {$IFDEF MSWINDOWS}#$D + {$ENDIF} #$A;
begin
	Result:='';
	while Offset > 0 do begin
		Inc(Stack);
		Dec(Offset);
	end;
	while Count > 0 do begin
		Result:=Result + GetStackLine(NativeUInt(Stack^)) + EOL;
		Inc(Stack);
		Dec(Count);
	end;
	SetLength(Result, Length(Result) - Length(EOL));
end;

constructor TPosixProcEntryList.Create;
//Format: address perms offset dev inode pathname
const REG_EXP =
	//Start           -        End      Perms        Offset
	'^ *([0-9a-fA-F]+)-([0-9a-fA-F]+) +([rwxps\-]+) +[0-9a-fA-F]+ +' +
	//Dev                       Inode          Path
	'[0-9a-fA-F]+:[0-9a-fA-F]+ +[0-9a-fA-F]+ *(.*)$';
begin
	inherited;
	//TODO threadsafe
	if (FComparer = nil) then begin
		FComparer:=TPosixProcEntryComparer.Create;
		FRegExp:=TRegEx.Create(REG_EXP);
	end;
end;

function TPosixProcEntryList.FindEntry(
  const Address: NativeUInt): PPosixProcEntry;
var Token	: TPosixProcEntry;
	Index	: Integer;
begin
	Token.RangeEnd:=Address;
	//This will most likely return false all the time since we won't have address
	//at the end of range
	TArray.BinarySearch<TPosixProcEntry>(FList, Token, Index, FComparer);
	Result:=@FList[Index];
	if (not InRange(Address, Result^.RangeStart, Result^.RangeEnd)) then
		Result:=nil;
end;

function TPosixProcEntryList.GetStackLine(const Address: NativeUInt): string;
const CHARS = sizeof(NativeInt) * 2;
var E   : PPosixProcEntry;
begin
	E:=FindEntry(Address);
	if (E = nil) then begin
		Exit('0x' + IntToHex(Address, CHARS) + '            ' + ' {Unknown address}');
	end;

	if (peExecute in E^.Perms) then
		Result:='0x' + IntToHex(Address - E^.RangeStart, CHARS) +
			' (0x' + IntToHex(Address, CHARS)+ ')' +
			' ' + E^.Path
	else Result:='0x' + IntToHex(Address - E^.RangeStart, CHARS) +
			' (0x' + IntToHex(Address, CHARS)+ ')' +
			' {Not executable} ' + E^.Path;
end;

{$IFDEF POSIX}
procedure TPosixProcEntryList.LoadFromCurrentProcess;
var s	: TStrings;
begin
	s:=TStringList.Create;
	LoadProcMaps(s);
	LoadFromStrings(s);
end;
{$ENDIF}

procedure TPosixProcEntryList.LoadFromStrings(const Str: TStrings);
var s	: string;
	i	: Integer;
begin
	i:=0;
	SetLength(FList, Str.Count);
	for s in Str do begin
		if (ProcessLine(s, FList[i])) then Inc(i);
	end;
	SetLength(FList, i);
end;

function TPosixProcEntryList.ProcessLine(const Line: string;
	out Entry : TPosixProcEntry) : Boolean;
var M	: TMatch;
	s	: string;
begin
	M:=FRegExp.Match(Line);
	if (not M.Success) then begin
		Exit(false);
	end;
	Entry.RangeStart:=StrToInt('$' + M.Groups[1].Value);
	Entry.RangeEnd:=StrToInt('$' + M.Groups[2].Value);

	s:=M.Groups[3].Value.ToLower;
	Entry.Perms:=[];
	if (s.Contains('r')) then Include(Entry.Perms, peRead);
	if (s.Contains('w')) then Include(Entry.Perms, peWrite);
	if (s.Contains('x')) then Include(Entry.Perms, peExecute);
	if (s.Contains('p')) then Include(Entry.Perms, pePrivate);
	if (s.Contains('s')) then Include(Entry.Perms, peShared);

	Entry.Path:=M.Groups[4].Value;
	Result:=true;
end;

{ TUnixProcentryList.TUnixProcEntryComparer }

function TPosixProcEntryList.TPosixProcEntryComparer.Compare(const Left,
  Right: TPosixProcEntry): Integer;
begin
	//We're using end since we will never hit the exact value and we want the
	//closest result to be returned, additional range check is done later
	if Left.RangeEnd < Right.RangeEnd then
		Result := -1
	else if Left.RangeEnd > Right.RangeEnd then
		Result := 1
	else Result := 0;
end;

end.
