#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Install','Repair','Uninstall','Status')]
    [string]$Mode = 'Install',

    [switch]$NoDesktopShortcut,
    [switch]$NoStartMenuShortcut,
    [switch]$NoPath,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'Codex Account Manager'
$CommandName = 'codex-account'
$InstallDir = Join-Path $env:LOCALAPPDATA 'CodexAccountManager'
$StartMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Codex Account Manager'
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex Account Manager.lnk'
$StartMenuShortcut = Join-Path $StartMenuDir 'Codex Account Manager.lnk'
$UninstallCmd = Join-Path $InstallDir 'uninstall.cmd'
$RequiredFiles = @('codex-account.ps1', 'codex-account.cmd')

function Write-Step([string]$Text) {
    if (-not $Quiet) { Write-Host "[+] $Text" -ForegroundColor Cyan }
}

function Write-Done([string]$Text) {
    if (-not $Quiet) { Write-Host "[OK] $Text" -ForegroundColor Green }
}

function Write-Warn([string]$Text) {
    if (-not $Quiet) { Write-Host "[!] $Text" -ForegroundColor Yellow }
}

function Assert-SourceFiles {
    foreach ($file in $RequiredFiles) {
        $path = Join-Path $PSScriptRoot $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Не найден файл установщика: $path"
        }
    }
}

function Get-UserPathItems {
    $path = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrWhiteSpace($path)) { return @() }
    return @($path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Set-UserPathItems([string[]]$Items) {
    [Environment]::SetEnvironmentVariable('Path', ($Items -join ';'), 'User')
}

function Add-ToUserPath([string]$PathToAdd) {
    if ($NoPath) { return }
    $items = @(Get-UserPathItems)
    if ($items -contains $PathToAdd) {
        Write-Done 'PATH уже настроен'
        return
    }
    $items += $PathToAdd
    Set-UserPathItems $items
    $env:Path = (($env:Path.TrimEnd(';') + ';' + $PathToAdd).TrimStart(';'))
    Write-Done "Добавлено в User PATH: $PathToAdd"
}

function Remove-FromUserPath([string]$PathToRemove) {
    $items = @(Get-UserPathItems | Where-Object { $_ -ne $PathToRemove })
    Set-UserPathItems $items
    Write-Done 'PATH очищен'
}

function New-Shortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$Arguments = '',
        [string]$WorkingDirectory = $InstallDir,
        [string]$Description = $AppName
    )
    $parent = Split-Path -Parent $ShortcutPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.Description = $Description
    $shortcut.IconLocation = 'powershell.exe,0'
    $shortcut.Save()
}

function Install-Files {
    Assert-SourceFiles
    Write-Step "Установка в $InstallDir"
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    foreach ($file in $RequiredFiles) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $InstallDir $file) -Force
    }

    @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Mode Uninstall
pause
"@ | Set-Content -LiteralPath $UninstallCmd -Encoding ASCII

    Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $InstallDir 'setup.ps1') -Force
    Write-Done 'Файлы установлены'
}

function Install-Shortcuts {
    $cmd = Join-Path $InstallDir 'codex-account.cmd'
    if (-not $NoStartMenuShortcut) {
        New-Shortcut -ShortcutPath $StartMenuShortcut -TargetPath $cmd
        New-Shortcut -ShortcutPath (Join-Path $StartMenuDir 'Uninstall Codex Account Manager.lnk') -TargetPath $UninstallCmd
        Write-Done 'Ярлыки в меню Пуск созданы'
    }
    if (-not $NoDesktopShortcut) {
        New-Shortcut -ShortcutPath $DesktopShortcut -TargetPath $cmd
        Write-Done 'Ярлык на рабочем столе создан'
    }
}

function Install-App {
    Install-Files
    Add-ToUserPath $InstallDir
    Install-Shortcuts
    Write-Host ''
    Write-Done "$AppName установлен"
    Write-Host "Запуск меню: $CommandName" -ForegroundColor White
    Write-Host "Если команда не найдётся в старом окне терминала — откройте новое окно PowerShell/Windows Terminal." -ForegroundColor DarkGray
}

function Uninstall-App {
    Write-Step 'Удаление ярлыков и файлов'
    Remove-Item -LiteralPath $DesktopShortcut -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $StartMenuDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-FromUserPath $InstallDir
    if (Test-Path -LiteralPath $InstallDir) {
        Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Done "$AppName удалён"
    Write-Warn 'Сохранённые аккаунты в %USERPROFILE%\.codex\accounts не удалялись'
}

function Show-Status {
    $installed = Test-Path -LiteralPath (Join-Path $InstallDir 'codex-account.ps1')
    $inPath = @(Get-UserPathItems) -contains $InstallDir
    Write-Host "App: $AppName"
    Write-Host "InstallDir: $InstallDir"
    Write-Host "Installed: $installed"
    Write-Host "InUserPath: $inPath"
    Write-Host "StartMenuShortcut: $(Test-Path -LiteralPath $StartMenuShortcut)"
    Write-Host "DesktopShortcut: $(Test-Path -LiteralPath $DesktopShortcut)"
}

try {
    switch ($Mode) {
        'Install' { Install-App }
        'Repair' { Install-App }
        'Uninstall' { Uninstall-App }
        'Status' { Show-Status }
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
