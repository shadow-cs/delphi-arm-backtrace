unit Posix.Libc;

interface

uses
  Posix.Base;

type
  TFile = NativeUInt;
  PFile = ^TFile;

function popen(command, mode: MarshaledAString): PFile
  cdecl; external libc name _PU + 'popen';
function pclose(stream: PFile): Integer;
  cdecl; external libc name _PU + 'pclose';

function feof(stream: PFile): LongBool
  cdecl; external libc name _PU + 'feof';
function fgets(buff: MarshaledAString; buffSize: Integer;
  stream: PFile): MarshaledAString
  cdecl; external libc name _PU + 'fgets';

implementation

end.
