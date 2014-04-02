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

program BacktraceTestProj;

uses
  System.StartUpCopy,
  FMX.MobilePreview,
  FMX.Forms,
  BacktraceTest in '..\..\Tests\BacktraceTest.pas' {TestForm},
  Posix.Backtrace in '..\..\Source\Posix.Backtrace.pas',
  Posix.Proc in '..\..\Source\Posix.Proc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TTestForm, TestForm);
  Application.Run;
end.
