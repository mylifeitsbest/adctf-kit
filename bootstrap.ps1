# Запустить ОДИН раз на машине С ИНТЕРНЕТОМ, чтобы затащить DestructiveFarm в репо.
$ErrorActionPreference = "Stop"
$farm = Join-Path $PSScriptRoot "DestructiveFarm"
if (Test-Path $farm) { Write-Host "DestructiveFarm уже есть, пропускаю"; exit 0 }

Write-Host "[*] Клонирую DestructiveFarm..."
git clone --depth 1 https://github.com/DestructiveVoice/DestructiveFarm $farm
Remove-Item -Recurse -Force (Join-Path $farm ".git")
Write-Host "[OK] DestructiveFarm вложен."
