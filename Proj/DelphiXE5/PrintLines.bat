::******************************************************************************
::
::            Copyright (c) 2014 Jan Rames
::
::******************************************************************************
::
::            This Source Code Form is subject to the terms of the
::
::                       Mozilla Public License, v. 2.0.
::
::            If a copy of the MPL was not distributed with this file,
::            You can obtain one at http://mozilla.org/MPL/2.0/.
::
::******************************************************************************

::Set the environmental vars
call ..\..\Source\compile.bat

::First convert object to symbol table
%TOOLS_PREFIX%objcopy --only-keep-debug Android\Debug\libBacktraceTestProj.so a.out

::Then use these symbols as a map, we could also load the so itself but this
::better demonstrates how to preserve symbols only - for release purposes
%TOOLS_PREFIX%addr2line -f -s -C -p
