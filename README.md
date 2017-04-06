Delphi ARM Backtrace library
============================
This is a simple library that allows you to create a stack trace and transform
it into format that can be fed to `addr2line` to convert it to function/line no.
information.

Usage
-----
Add the functions to your project and add compile.bat from sources to your
pre-build events. (Make sure compile.bat can find your NDK.)

Create a back trace by one of the functions from `Posix.Backtrace` and translate
it to symbol addresses using `TPosixProcEntryList`.

Feed the generated lines to `addr2line` to get symbolic function names and line
information. (See `PrintLines.bat` how to do that.)

The result will look like this:

```
0x001FC9BE (0xC972A9BE) /data/app/com.embarcadero.TestProject-2/lib/arm/libTestProject.so
System::_GetMem(NativeInt) at System.pas:4588
0x001F60F8 (0xC97240F8) /data/app/com.embarcadero.TestProject-2/lib/arm/libTestProject.so
System::TObject::NewInstance() at System.pas:16452
0x001FDAE0 (0xC972BAE0) /data/app/com.embarcadero.TestProject-2/lib/arm/libTestProject.so
System::_ClassCreate(void*, signed char) at System.pas:17777
0x001F61DA (0xC97241DA) /data/app/com.embarcadero.TestProject-2/lib/arm/libTestProject.so
System::TObject::TObject() at System.pas:16516
```

Known issues
------------
 * There are no unit tests right now as this project is currently in proof of
   concept state.
 * Tested on Android, MacOS, Linux no iOS support right now (patches welcome ;-) ).

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
