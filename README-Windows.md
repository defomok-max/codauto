# Codex Account Manager для Windows

PowerShell-меню для управления несколькими аккаунтами Codex CLI на Windows.

## Установка

1. Распакуйте архив `codex-account-manager-windows.zip`.
2. В PowerShell откройте папку архива.
3. Запустите:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

После установки откройте новое окно PowerShell/Windows Terminal и запустите:

```powershell
codex-account
```

Можно запускать без установки:

```powershell
.\codex-account.cmd
```

## Главное меню

В меню можно управлять аккаунтами:

1. Добавить аккаунт через `codex login`.
2. Сохранить текущий `%USERPROFILE%\.codex\auth.json` как профиль.
3. Переключить активный аккаунт.
4. Запустить Codex с авто-ротацией при лимите.
5. Показать аккаунты.
6. Удалить аккаунт.
7. Диагностика окружения.

## Быстрый старт

```powershell
codex-account add work
codex-account add personal
codex-account list
codex-account switch work
codex-account run -- exec "исправь тесты"
```

`run` перебирает сохранённые аккаунты и переключается на следующий, если Codex вернул лимит: `rate limit`, `429`, `quota`, `usage limit`, `insufficient_quota` и похожие сообщения.

## Где хранятся аккаунты

По умолчанию:

```text
%USERPROFILE%\.codex\auth.json
%USERPROFILE%\.codex\accounts\<name>\auth.json
```

Перед переключением текущий `auth.json` сохраняется как backup рядом с исходным файлом.

## Команды

```text
codex-account                  открыть главное меню
codex-account menu             открыть главное меню
codex-account add [name]       выполнить codex login и сохранить аккаунт
codex-account save <name>      сохранить текущий auth.json как аккаунт
codex-account switch <name>    переключиться на аккаунт
codex-account list             показать аккаунты
codex-account current          показать активный аккаунт
codex-account run [--] <args>  запустить Codex и сменить аккаунт при лимите
codex-account delete <name>    удалить аккаунт
codex-account doctor           проверить окружение
```

## Настройки

```text
CODEX_HOME          каталог Codex CLI, по умолчанию %USERPROFILE%\.codex
CODEX_AUTH_FILE     файл авторизации, по умолчанию %CODEX_HOME%\auth.json
CODEX_ACCOUNTS_DIR  каталог профилей, по умолчанию %CODEX_HOME%\accounts
CODEX_BIN           бинарь Codex, по умолчанию codex
CODEX_RETRY_DELAY   пауза между аккаунтами в секундах, по умолчанию 2
NO_COLOR=1          выключить цвета
```
