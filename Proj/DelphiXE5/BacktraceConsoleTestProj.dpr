program BacktraceConsoleTestProj;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes,
  Posix.Backtrace in '..\..\Source\Posix.Backtrace.pas',
  Posix.Proc in '..\..\Source\Posix.Proc.pas',
  Posix.ExceptionUtil in '..\..\Source\Posix.ExceptionUtil.pas';


procedure Proc4;
var b	: array[0..7] of Pointer;
	c	: Integer;
begin
	asm
		mov c, ebp
	end;
	c:=backtrace2(c, @b, Length(b)); //a98
	Writeln(TExceptionStackInfo.GetSymbols(@b, c));
	raise Exception.Create('Test exception');
end;

var a : procedure;

procedure Proc3;
begin
	Proc4;
end;

procedure Proc2;
begin
	a:=proc3;
	a();
	//Proc3;
end;

procedure Proc1;
begin
	Proc2;
end;

begin
	try
		TExceptionStackInfo.Attach;
		TThread.NameThreadForDebugging('Main');
		Proc1;
	except
		on E: Exception do begin
			Writeln(E.ClassName, ': ', E.Message);
			Writeln(E.StackTrace);
		end;
	end;
end.
