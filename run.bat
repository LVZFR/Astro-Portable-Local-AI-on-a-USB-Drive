@echo off
setlocal enabledelayedexpansion
set "DIR=%~dp0"
set "RUNTIME=%DIR%bin\llamafile.exe"
set "MODELS_DIR=%DIR%models"

if not exist "%RUNTIME%" (
    echo ERROR: runtime not found at %RUNTIME%
    echo Download llamafile from https://github.com/Mozilla-Ocho/llamafile/releases
    echo and place it at bin\llamafile.exe
    exit /b 1
)

if not "%~1"=="" (
    set "SELECTED=%~1"
    goto :launch
)

set count=0
for %%F in ("%MODELS_DIR%\*.gguf") do (
    set /a count+=1
    set "model!count!=%%F"
    echo   [!count!] %%~nxF
)

if %count%==0 (
    echo No .gguf models found in %MODELS_DIR%
    echo Run download-models.sh ^(via WSL or Git Bash^) first, or download manually.
    exit /b 1
)

set /p CHOICE="Select a model [1-%count%]: "
set "SELECTED=!model%CHOICE%!"

if "!SELECTED!"=="" (
    echo Invalid selection.
    exit /b 1
)

:launch
echo Launching %SELECTED% ...
echo Web UI will be available at http://127.0.0.1:8080 once loaded.
"%RUNTIME%" -m "%SELECTED%" -c 4096 --host 127.0.0.1 --port 8080
endlocal
