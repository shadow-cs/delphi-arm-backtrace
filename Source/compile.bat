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

::If you use different path make sure to register this variable
if "%NDK_PATH%"=="" (
	set NDK_PATH=D:\Google\PlatformSDKs\android-ndk-r8e
)

if "%TOOLS_PREFIX%"=="" (
	@set TOOLS_PREFIX=%NDK_PATH%\toolchains\arm-linux-androideabi-4.7\prebuilt\windows\bin\arm-linux-androideabi-
)
@set GCC="%TOOLS_PREFIX%gcc.exe"

%GCC% -O -fomit-frame-pointer -c "%~dp0\backtrace.c"
