ECHO OFF

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
"%MSBuildLocation%" submodules\CinematicsBuddyPlugin\CinematicsBuddy.sln /t:Rebuild

ECHO.
ECHO Copying built dll into plugins folder
COPY "submodules\CinematicsBuddyPlugin\x64\Release\CinematicsBuddy.dll" "submodules\CinematicsBuddyPlugin\bakkesmod\plugins\"

if not exist "bakkesmod\" mkdir "bakkesmod"

ECHO.
ECHO Copying contents of plugin repo into root bakkesmod folder
XCOPY /e /v /s /y "submodules\CinematicsBuddyPlugin\bakkesmod\" "bakkesmod\"

ECHO.
ECHO Copying contents of maxscript repo into root bakkesmod folder
XCOPY /e /v /s /y "submodules\CinematicsBuddyMaxscript\bakkesmod\" "bakkesmod\"

ECHO.
ECHO Copying contents of after effects repo into root bakkesmod folder
XCOPY /e /v /s /y "submodules\CinematicsBuddyAE\bakkesmod\" "bakkesmod\"

ECHO.
ECHO Script successfully completed.
PAUSE