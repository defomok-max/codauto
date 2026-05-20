#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$InstallDir = Join-Path $env:LOCALAPPDATA 'codex-account-manager'
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'codex-account.ps1') -Destination $InstallDir -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'codex-account.cmd') -Destination $InstallDir -Force
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $InstallDir).TrimStart(';'), 'User')
    Write-Host "Добавил в User PATH: $InstallDir"
    Write-Host 'Откройте новое окно PowerShell/Terminal, чтобы PATH обновился.'
}
Write-Host "Готово: $InstallDir\codex-account.cmd"
Write-Host 'Запуск меню: codex-account'
