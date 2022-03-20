@echo off

:: last 17 positions of the path
set endPath=%cd:~-18%

if "%endPath%" == "\no_solo_padel_dev" (
   echo Development environment
   dart run utilities\development.dart
	goto end
)

:: last 13 positions of the path
set endPath=%cd:~-14%

if "%endPath%" == "\no_solo_padel" (
   echo Production environment
   dart run utilities\production.dart
   goto end
)

echo Wrong folder!!!

:end
