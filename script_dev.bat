@echo off

:: last 17 positions of the path
set endPath=%cd:~-17%

echo Development environment

if NOT "%endPath%" == "no_solo_padel_dev" (
	echo Wrong environment!!!
	goto end
)


dart run utilities\development.dart

goto end

set /p resp="Copy pubspec to pubspec dev & prod (s/N)?: "
if /I "%resp%"=="s" (
   ddart run utilities\development.dart
)

git status

set /p resp="Commit changes as new version (s/N)?: "
if /I "%resp%"=="s" (
   dgit add *
   dgit commit -m "new version"
)


set /p resp="git push to repository (s/N)?: "
if /I "%resp%"=="s" (
    dgit push origin master
)

:end
