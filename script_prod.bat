@echo off

:: last 13 positions of the path
set endPath=%cd:~-13%

echo Production environment

if NOT "%endPath%"=="no_solo_padel" (
	echo Wrong environment!!!
	goto end
)


set /p resp="git pull from repository (s/N)?: "
if /I "%resp%"=="s" (
    git pull origin master
)

set /p resp="Copy pubspec_prod to pubspec (s/N)?: "
if /I "%resp%"=="s" (
    dart run "utilities\production.dart"
)

:end

