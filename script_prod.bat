@echo off

:: last 13 positions of the path
set endPath=%cd:~-13%

echo Copiar pubspec_prod.yaml a pubspec.yaml

if NOT "%endPath%"=="no_solo_padel" ( 
	echo Wrong environment!!!
	goto end
)

set /p resp="Continuar (s/N)?: "
if /I NOT "%resp%"=="s" (goto end)

dart run "utilities\production.dart"

:end
