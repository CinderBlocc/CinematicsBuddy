ECHO OFF

ECHO.
ECHO This script currently does nothing. The goal is to write this script to automate the pull/build/copy process for all submodules into the bakkesmod folder

ECHO.
ECHO Creating CommandVar to store vswhere execution command
SET CommandVar="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

ECHO.
ECHO Running vswhere to store path to MSBuild.exe
FOR /F "tokens=*" %%F IN ('%CommandVar%') DO SET MSBuildLocation=%%F
ECHO Found MSBuild.exe: %MSBuildLocation%

ECHO.
ECHO Rebuilding CinematicsBuddy.sln
"%MSBuildLocation%" submodules/CinematicsBuddyPlugin/CinematicsBuddy.sln /t:Rebuild

PAUSE