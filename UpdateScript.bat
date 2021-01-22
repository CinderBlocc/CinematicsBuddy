ECHO OFF

ECHO.
ECHO TODO
ECHO - Automatically update submodules
ECHO - Copy built dll into plugin repo's bakkesmod plugins folder
ECHO - Copy each submodules' bakkesmod folder contents into the root bakkesmod folder

ECHO.
ECHO Initializing and updating submodules
git submodule update --init --recursive

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