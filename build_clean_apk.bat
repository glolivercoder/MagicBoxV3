@echo off
echo ===================================================
echo BoxMagic - Script de Compilacao Otimizado
echo ===================================================
echo.

echo [1/5] Limpando cache e arquivos temporarios...
call flutter clean
if %ERRORLEVEL% neq 0 (
    echo Erro ao limpar o projeto. Abortando.
    exit /b %ERRORLEVEL%
)
echo.

echo [2/5] Atualizando dependencias...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo Erro ao atualizar dependencias. Abortando.
    exit /b %ERRORLEVEL%
)
echo.

echo [3/5] Executando analise de codigo...
call flutter analyze
echo.

echo [4/5] Compilando versao de debug para testes...
call flutter build apk --debug
if %ERRORLEVEL% neq 0 (
    echo Erro ao compilar versao de debug. Abortando.
    exit /b %ERRORLEVEL%
)
echo.

echo [5/5] Compilando versao de release...
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo Erro ao compilar versao de release. Abortando.
    exit /b %ERRORLEVEL%
)
echo.

echo ===================================================
echo Compilacao concluida com sucesso!
echo.
echo APK de debug: build\app\outputs\flutter-apk\app-debug.apk
echo APK de release: build\app\outputs\flutter-apk\app-release.apk
echo ===================================================

pause
