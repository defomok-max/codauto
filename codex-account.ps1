#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'menu',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:Version = '3.0.0-windows'
$Script:CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$Script:AuthFile = if ($env:CODEX_AUTH_FILE) { $env:CODEX_AUTH_FILE } else { Join-Path $Script:CodexHome 'auth.json' }
$Script:AccountsDir = if ($env:CODEX_ACCOUNTS_DIR) { $env:CODEX_ACCOUNTS_DIR } else { Join-Path $Script:CodexHome 'accounts' }
$Script:ActiveFile = Join-Path $Script:AccountsDir '.active'
$Script:LockDir = Join-Path $Script:AccountsDir '.lock'
$Script:CodexBin = if ($env:CODEX_BIN) { $env:CODEX_BIN } else { 'codex' }
$Script:RetryDelay = if ($env:CODEX_RETRY_DELAY) { [int]$env:CODEX_RETRY_DELAY } else { 2 }
$Script:NoColor = [bool]$env:NO_COLOR

function Write-Color {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::White,
        [switch]$NoNewline
    )
    if ($Script:NoColor) {
        if ($NoNewline) { Write-Host $Text -NoNewline } else { Write-Host $Text }
        return
    }
    if ($NoNewline) { Write-Host $Text -ForegroundColor $Color -NoNewline } else { Write-Host $Text -ForegroundColor $Color }
}

function Ok([string]$Text) { Write-Color "✓ $Text" Green }
function Warn([string]$Text) { Write-Color "! $Text" Yellow }
function Note([string]$Text) { Write-Color "› $Text" Cyan }
function Fail([string]$Text) { Write-Color "Ошибка: $Text" Red; exit 1 }

function Show-Help {
@'
codex-account — Windows-менеджер аккаунтов Codex CLI с красивым меню.

Использование:
  codex-account                  открыть главное меню
  codex-account menu             открыть главное меню
  codex-account add [name]       выполнить codex login и сохранить аккаунт
  codex-account save <name>      сохранить текущий %USERPROFILE%\.codex\auth.json
  codex-account switch <name>    переключиться на аккаунт
  codex-account list             показать аккаунты
  codex-account current          показать активный аккаунт
  codex-account run [--] <args>  запустить Codex и сменить аккаунт при лимите
  codex-account delete <name>    удалить аккаунт
  codex-account doctor           проверить окружение

Примеры:
  codex-account add work
  codex-account add personal
  codex-account switch work
  codex-account run -- exec "исправь тесты"

Переменные окружения:
  CODEX_HOME          каталог Codex CLI, по умолчанию %USERPROFILE%\.codex
  CODEX_AUTH_FILE     файл авторизации, по умолчанию %CODEX_HOME%\auth.json
  CODEX_ACCOUNTS_DIR  каталог профилей, по умолчанию %CODEX_HOME%\accounts
  CODEX_BIN           бинарь Codex, по умолчанию codex
  CODEX_RETRY_DELAY   пауза между аккаунтами в секундах, по умолчанию 2
  NO_COLOR=1          выключить цвета
'@
}

function Initialize-Storage {
    New-Item -ItemType Directory -Force -Path $Script:AccountsDir | Out-Null
}

function Enter-Lock {
    Initialize-Storage
    for ($i = 0; $i -lt 30; $i++) {
        try {
            New-Item -ItemType Directory -Path $Script:LockDir -ErrorAction Stop | Out-Null
            return
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    Fail "не удалось получить lock $Script:LockDir"
}

function Exit-Lock {
    if (Test-Path -LiteralPath $Script:LockDir) {
        Remove-Item -LiteralPath $Script:LockDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Validate-AccountName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { Fail 'укажите имя аккаунта' }
    if ($Name -notmatch '^[A-Za-z0-9._-]+$') { Fail 'имя может содержать только A-Z, a-z, 0-9, точку, подчёркивание и дефис' }
}

function Get-ProfileDir([string]$Name) { Join-Path $Script:AccountsDir $Name }
function Get-ProfileAuthFile([string]$Name) { Join-Path (Get-ProfileDir $Name) 'auth.json' }

function Assert-AuthExists {
    if (-not (Test-Path -LiteralPath $Script:AuthFile -PathType Leaf)) {
        Fail "не найден $Script:AuthFile. Сначала войдите: $Script:CodexBin login"
    }
}

function Assert-ProfileExists([string]$Name) {
    if (-not (Test-Path -LiteralPath (Get-ProfileAuthFile $Name) -PathType Leaf)) { Fail "аккаунт '$Name' не найден" }
}

function Get-AccountNames {
    Initialize-Storage
    Get-ChildItem -LiteralPath $Script:AccountsDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne '.lock' } |
        Sort-Object Name |
        ForEach-Object { $_.Name }
}

function Get-CurrentAccount {
    if (Test-Path -LiteralPath $Script:ActiveFile -PathType Leaf) { (Get-Content -LiteralPath $Script:ActiveFile -Raw).Trim() } else { 'unknown' }
}

function Save-Account([string]$Name) {
    Validate-AccountName $Name
    Assert-AuthExists
    Enter-Lock
    try {
        $dir = Get-ProfileDir $Name
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Copy-Item -LiteralPath $Script:AuthFile -Destination (Get-ProfileAuthFile $Name) -Force
        Set-Content -LiteralPath $Script:ActiveFile -Value $Name -NoNewline
        Ok "Сохранён аккаунт: $Name"
    } finally {
        Exit-Lock
    }
}

function Add-Account([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { $Name = Read-Host 'Имя нового аккаунта' }
    Validate-AccountName $Name
    Note "Сейчас откроется '$Script:CodexBin login'. Войдите в нужный аккаунт Codex."
    & $Script:CodexBin login
    if ($LASTEXITCODE -ne 0) { Fail "codex login завершился с кодом $LASTEXITCODE" }
    Save-Account $Name
}

function Switch-Account([string]$Name) {
    Validate-AccountName $Name
    Assert-ProfileExists $Name
    Enter-Lock
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Script:AuthFile) | Out-Null
        if (Test-Path -LiteralPath $Script:AuthFile -PathType Leaf) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            Copy-Item -LiteralPath $Script:AuthFile -Destination "$($Script:AuthFile).backup-$stamp" -Force
        }
        Copy-Item -LiteralPath (Get-ProfileAuthFile $Name) -Destination $Script:AuthFile -Force
        Set-Content -LiteralPath $Script:ActiveFile -Value $Name -NoNewline
        Ok "Активный аккаунт: $Name"
    } finally {
        Exit-Lock
    }
}

function Show-Accounts {
    $active = Get-CurrentAccount
    $names = @(Get-AccountNames)
    if ($names.Count -eq 0) { Warn 'Нет сохранённых аккаунтов. Используйте: codex-account add <name>'; return }
    foreach ($name in $names) {
        $mark = if ($name -eq $active) { '*' } else { ' ' }
        Write-Host "$mark $name"
    }
}

function Remove-Account([string]$Name) {
    Validate-AccountName $Name
    Assert-ProfileExists $Name
    Enter-Lock
    try {
        Remove-Item -LiteralPath (Get-ProfileDir $Name) -Recurse -Force
        if ((Test-Path -LiteralPath $Script:ActiveFile) -and ((Get-CurrentAccount) -eq $Name)) {
            Remove-Item -LiteralPath $Script:ActiveFile -Force
        }
        Ok "Удалён аккаунт: $Name"
    } finally {
        Exit-Lock
    }
}

function Test-RotationError([string]$LogPath) {
    if (-not (Test-Path -LiteralPath $LogPath)) { return $false }
    $text = Get-Content -LiteralPath $LogPath -Raw -ErrorAction SilentlyContinue
    return $text -match '(?i)(rate limit|too many requests|429|quota|usage limit|limit reached|billing|insufficient_quota|exceeded)'
}

function Run-WithRotation([string[]]$Args) {
    Initialize-Storage
    $names = @(Get-AccountNames)
    if ($names.Count -eq 0) { Fail 'нет сохранённых аккаунтов' }
    if ($Args.Count -gt 0 -and $Args[0] -eq '--') { $Args = @($Args | Select-Object -Skip 1) }

    $attempt = 0
    foreach ($name in $names) {
        $attempt++
        Switch-Account $name | Out-Null
        Note "[$attempt/$($names.Count)] Codex аккаунт: $name"
        $log = [System.IO.Path]::GetTempFileName()
        try {
            & $Script:CodexBin @Args 2>&1 | Tee-Object -FilePath $log
            $code = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
            if ($code -eq 0) { Ok "Команда выполнена на аккаунте: $name"; return }
            if ((Test-RotationError $log) -and ($attempt -lt $names.Count)) {
                Warn "Похоже на лимит. Переключаю аккаунт через $Script:RetryDelay сек..."
                Start-Sleep -Seconds $Script:RetryDelay
                continue
            }
            exit $code
        } finally {
            Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-Doctor {
    Initialize-Storage
    $codexPath = (Get-Command $Script:CodexBin -ErrorAction SilentlyContinue | Select-Object -First 1).Source
    if (-not $codexPath) { $codexPath = 'not found' }
    $authState = if (Test-Path -LiteralPath $Script:AuthFile) { 'exists' } else { 'missing' }
    Write-Host "codex-account: $Script:Version"
    Write-Host "CODEX_HOME: $Script:CodexHome"
    Write-Host "AUTH_FILE: $Script:AuthFile ($authState)"
    Write-Host "ACCOUNTS_DIR: $Script:AccountsDir"
    Write-Host "CODEX_BIN: $Script:CodexBin ($codexPath)"
    Write-Host "ACTIVE: $(Get-CurrentAccount)"
    Write-Host "ACCOUNTS: $(@(Get-AccountNames).Count)"
}

function Show-Header {
    Clear-Host
    $active = Get-CurrentAccount
    $count = @(Get-AccountNames).Count
    $authState = if (Test-Path -LiteralPath $Script:AuthFile) { 'ok' } else { 'missing' }
    Write-Color '╭────────────────────────────────────────────────────╮' Cyan
    Write-Color ("│ Codex Account Manager for Windows v{0,-14} │" -f $Script:Version) Cyan
    Write-Color '├────────────────────────────────────────────────────┤' Cyan
    Write-Color ("│ Активный: {0,-20} Аккаунтов: {1,-6} │" -f $active, $count) Cyan
    Write-Color ("│ auth.json: {0,-19} Codex: {1,-9} │" -f $authState, $Script:CodexBin) Cyan
    Write-Color '╰────────────────────────────────────────────────────╯' Cyan
}

function Select-Account([string]$Title) {
    $names = @(Get-AccountNames)
    if ($names.Count -eq 0) { Warn 'Нет сохранённых аккаунтов'; return $null }
    $active = Get-CurrentAccount
    Write-Host ''
    Write-Color $Title White
    for ($i = 0; $i -lt $names.Count; $i++) {
        $suffix = if ($names[$i] -eq $active) { '  active' } else { '' }
        Write-Host ('  {0,2}) {1}{2}' -f ($i + 1), $names[$i], $suffix)
    }
    Write-Host '   0) Назад'
    $choice = Read-Host 'Выбор'
    if ($choice -eq '0') { return $null }
    if ($choice -notmatch '^\d+$') { Warn 'нужно число'; return $null }
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $names.Count) { Warn 'нет такого пункта'; return $null }
    return $names[$idx]
}

function Start-MenuRun {
    Write-Color 'Команда Codex' White
    Write-Color 'Пример: exec "исправь тесты"' DarkGray
    $line = Read-Host 'Аргументы после codex'
    if ([string]::IsNullOrWhiteSpace($line)) { Warn 'команда не указана'; return }
    $tokens = [System.Management.Automation.PSParser]::Tokenize($line, [ref]$null) |
        Where-Object { $_.Type -in @('CommandArgument', 'String', 'Command') } |
        ForEach-Object { $_.Content }
    Run-WithRotation @($tokens)
}

function Pause-Menu { Write-Host ''; Read-Host 'Нажмите Enter, чтобы продолжить' | Out-Null }

function Show-MainMenu {
    while ($true) {
        Show-Header
        Write-Host ''
        Write-Host '  1) Добавить аккаунт через codex login'
        Write-Host '  2) Сохранить текущий auth.json как аккаунт'
        Write-Host '  3) Переключить аккаунт'
        Write-Host '  4) Запустить Codex с авто-ротацией'
        Write-Host '  5) Показать аккаунты'
        Write-Host '  6) Удалить аккаунт'
        Write-Host '  7) Диагностика'
        Write-Host '  0) Выход'
        Write-Host ''
        $choice = Read-Host 'Выбор'
        switch ($choice) {
            '1' { Add-Account (Read-Host 'Имя нового аккаунта'); Pause-Menu }
            '2' { Save-Account (Read-Host 'Имя аккаунта для текущего auth.json'); Pause-Menu }
            '3' { $name = Select-Account 'Выберите аккаунт для переключения'; if ($name) { Switch-Account $name }; Pause-Menu }
            '4' { Start-MenuRun; Pause-Menu }
            '5' { Show-Accounts; Pause-Menu }
            '6' { $name = Select-Account 'Выберите аккаунт для удаления'; if ($name -and ((Read-Host "Удалить '$name'? y/N") -match '^[YyДд]$')) { Remove-Account $name }; Pause-Menu }
            '7' { Show-Doctor; Pause-Menu }
            { $_ -in @('0','q','quit','exit') } { return }
            default { Warn 'нет такого пункта'; Pause-Menu }
        }
    }
}

switch ($Command.ToLowerInvariant()) {
    'add' { Add-Account ($RemainingArgs | Select-Object -First 1) }
    'save' { Save-Account ($RemainingArgs | Select-Object -First 1) }
    { $_ -in @('switch','use') } { Switch-Account ($RemainingArgs | Select-Object -First 1) }
    { $_ -in @('list','ls') } { Show-Accounts }
    { $_ -in @('current','status') } { Get-CurrentAccount }
    'menu' { Show-MainMenu }
    'run' { Run-WithRotation $RemainingArgs }
    { $_ -in @('delete','rm') } { Remove-Account ($RemainingArgs | Select-Object -First 1) }
    'doctor' { Show-Doctor }
    { $_ -in @('help','-h','--help') } { Show-Help }
    { $_ -in @('version','-v','--version') } { $Script:Version }
    default { Fail "неизвестная команда '$Command'. Запустите: codex-account help" }
}
