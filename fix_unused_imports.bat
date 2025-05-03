@echo off
echo ===================================================
echo BoxMagic - Limpeza de Codigo
echo ===================================================
echo.

echo [1/3] Verificando importacoes nao utilizadas...
call flutter analyze --no-fatal-infos --no-fatal-warnings > analyze_results.txt
findstr /C:"unused_import" analyze_results.txt

echo.
echo [2/3] Verificando variaveis nao utilizadas...
findstr /C:"unused_local_variable" analyze_results.txt
findstr /C:"unused_field" analyze_results.txt

echo.
echo [3/3] Gerando relatorio de limpeza...
echo # Relatorio de Limpeza de Codigo > code_cleanup_report.md
echo. >> code_cleanup_report.md
echo ## Importacoes nao utilizadas >> code_cleanup_report.md
findstr /C:"unused_import" analyze_results.txt >> code_cleanup_report.md
echo. >> code_cleanup_report.md
echo ## Variaveis nao utilizadas >> code_cleanup_report.md
findstr /C:"unused_local_variable" analyze_results.txt >> code_cleanup_report.md
findstr /C:"unused_field" analyze_results.txt >> code_cleanup_report.md

echo.
echo ===================================================
echo Verificacao concluida!
echo Relatorio gerado em: code_cleanup_report.md
echo ===================================================
echo.
echo NOTA: Para corrigir as importacoes nao utilizadas, edite
echo os arquivos listados e remova as importacoes marcadas.
echo.
echo IMPORTANTE: Siga as regras de commits:
echo - Faca commits pequenos e focados
echo - Use mensagens claras e padronizadas (tipo(escopo): descricao)
echo - Teste antes de commitar
echo ===================================================

pause
