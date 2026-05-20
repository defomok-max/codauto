# Codex Account Manager для Windows

PowerShell-меню для управления несколькими аккаунтами Codex CLI на Windows.

## Нормальная установка

1. Распакуйте `codex-account-manager-windows.zip` в любую папку.
2. Дважды кликните `install.cmd`.
3. Откройте новое окно PowerShell/Windows Terminal.
4. Запустите:

```powershell
codex-account
```

Инсталлятор делает всё сам:

- ставит файлы в `%LOCALAPPDATA%\CodexAccountManager`;
- добавляет команду `codex-account` в User PATH;
- создаёт ярлык в Start Menu;
- создаёт ярлык на рабочем столе;
- создаёт `uninstall.cmd` для удаления;
- не трогает сохранённые аккаунты в `%USERPROFILE%\.codex\accounts` при удалении.

## Управление установкой

```powershell
.\install.cmd       # установка двойным кликом или из терминала
.\repair.cmd        # переустановка/починка PATH и ярлыков
.\uninstall.cmd     # удаление программы
```

Продвинутый режим:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode Install
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode Repair
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode Uninstall
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode Status
```

Опции:

```powershell
-NoDesktopShortcut      не создавать ярлык на рабочем столе
-NoStartMenuShortcut    не создавать ярлык в Start Menu
-NoPath                 не добавлять папку установки в User PATH
-Quiet                  меньше вывода
```

## Главное меню

Запуск:

```powershell
codex-account
```

В меню можно:

1. Добавить аккаунт через `codex login`.
2. Сохранить текущий `%USERPROFILE%\.codex\auth.json` как профиль.
3. Переключить активный аккаунт.
4. Запустить Codex с авто-ротацией при лимите.
5. Показать аккаунты.
6. Удалить аккаунт.
7. Проверить окружение.

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
