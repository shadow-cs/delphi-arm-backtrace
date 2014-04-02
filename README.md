Delphi ARM Backtrace library
============================
This is a simple library that allows you to create a stack trace and transform
it into format that can be fed to addr2line to convert it to function/line no.
information.

Usage
-----
Add the functions to your project and add compile.bat from sources to your
pre-build events. (Make sure compile.bat can find your NDK.)

Create a back trace by one of the functions from Posix.Backtrace and translate
it to symbol addresses using TPosixProcEntryList.

Feed the generated lines to addr2line to get symbolic function names and line
information. (See PrintLines.bat how to do that.)

The result will look like this:

	0x00AC5AC6 (0x75A48AC6) /data/app-lib/com.embarcadero.BacktraceTestProj-1/libBacktraceTestProj.so
	_ZN13Backtracetest9SomeFunc2Ei at D:\Documents\RAD Studio\Projects\ArmBacktrace\Tests/BacktraceTest.pas:57
	0x00AC5E90 (0x75A48E90) /data/app-lib/com.embarcadero.BacktraceTestProj-1/libBacktraceTestProj.so
	_ZN13Backtracetest9SomeFunc1Ei at D:\Documents\RAD Studio\Projects\ArmBacktrace\Tests/BacktraceTest.pas:92
	0x00AC5EA8 (0x75A48EA8) /data/app-lib/com.embarcadero.BacktraceTestProj-1/libBacktraceTestProj.so
	_ZN13Backtracetest4TObj4TestEv at D:\Documents\RAD Studio\Projects\ArmBacktrace\Tests/BacktraceTest.pas:118
	0x00AC5EC0 (0x75A48EC0) /data/app-lib/com.embarcadero.BacktraceTestProj-1/libBacktraceTestProj.so
	_ZN13Backtracetest5TObj24TestEv at D:\Documents\RAD Studio\Projects\ArmBacktrace\Tests/BacktraceTest.pas:111
	0x00AC5A60 (0x75A48A60) /data/app-lib/com.embarcadero.BacktraceTestProj-1/libBacktraceTestProj.so
	_ZN13Backtracetest9TTestForm12cmdTestClickEPN6System7TObjectE at D:\Documents\RAD Studio\Projects\ArmBacktrace\Tests/BacktraceTest.pas:125
	0x009EF360 (0x75972360) /data/app-lib/com.embarcadero.BacktraceTestProj-1/libBacktraceTestProj.so
	_ZN3Fmx8Controls8TControl5ClickEv at C:\Builds\TP\runtime\fmx/FMX.Controls.pas:3455
	0x000022E9 (0x400B52E9) {Not executable} /system/lib/libc.so
	??
	??:0

Known issues
------------
 * There are no unit tests right now as this project is currently in proof of
   concept state.
 * Only tested on Android (Nexus 7, let me know if it works on your device),
   no iOS support right now (patches welcome ;-) ).

TODO
----
iOS support. On iOS we may not need to open /proc/self/maps as there is only one
executable so reading base address from elf might be enough. Returning symbols
and line numbers from XCode is another question.

License
-------
This Source Code Form is subject to the terms of the Mozilla Public License,
v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
