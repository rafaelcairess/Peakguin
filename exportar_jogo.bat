@echo off
echo Iniciando a exportacao do jogo...

if not exist "downloads" mkdir downloads

echo Gerando o executavel...
godot.windows.opt.tools.64.exe --headless --export-release "Joguin" "downloads\Peakguin-v0.02-pre-alpha.exe"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Sucesso! O jogo foi exportado para a pasta "downloads".
) else (
    echo.
    echo Ocorreu um erro. Verifique se voce baixou os Export Templates no Godot e se o preset "Windows Desktop" foi criado!
)

pause
