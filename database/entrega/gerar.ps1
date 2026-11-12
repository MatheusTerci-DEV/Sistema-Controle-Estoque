# Gera pim_estoque_completo.sql juntando database/001..004 (rodar após alterar qualquer script).
# Uso: powershell -File database\entrega\gerar.ps1
$db = Split-Path $PSScriptRoot
$cabecalho = @"
-- PIM Estoque — script completo do banco (gerado por database/entrega/gerar.ps1; não editar à mão).
-- Cria o banco PimEstoque e executa 001_schema, 002_triggers, 003_procedures e 004_seed.
-- Usado pela API ASP.NET Core, pelo painel web e pelo app mobile. Gerado em $(Get-Date -Format 'yyyy-MM-dd').
IF DB_ID(N'PimEstoque') IS NULL CREATE DATABASE PimEstoque;
GO
USE PimEstoque;
GO
"@
$partes = Get-ChildItem $db -Filter '0*.sql' | Sort-Object Name | ForEach-Object {
    "`r`n-- ============================== $($_.Name) ==============================`r`n" +
    [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
}
$saida = Join-Path $PSScriptRoot 'pim_estoque_completo.sql'
[IO.File]::WriteAllText($saida, $cabecalho + ($partes -join ''), (New-Object Text.UTF8Encoding $true))
Write-Output "Gerado $saida"
