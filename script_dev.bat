@echo off

:: last 17 positions of the path
set endPath=%cd:~-17%

echo Development environment

if NOT "%endPath%" == "no_solo_padel_dev" (
	echo Wrong environment!!!
	goto end
)


set /p resp="Copy pubspec to pubspec dev & prod (s/N)?: "
if /I "%resp%"=="s" (
   dart run utilities\development.dart
)


set /p resp="git push to repository (s/N)?: "
if /I "%resp%"=="s" (
    git push origin master
)

:end
