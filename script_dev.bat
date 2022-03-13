@echo off

:: last 17 positions of the path
set end=%cd:~-17%

if "%end%" == "no_solo_padel_dev" (
	:: development
	echo Copiar pubspec.yaml a dev y prod
	dart run utilities\development.dart
) else (
	echo Wrong environment!!!
	echo %end%
)
