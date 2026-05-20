# codauto

Красивый CLI/TUI-скрипт для переключения и авто-ротации аккаунтов Codex CLI без ручного копирования `~/.codex/auth.json`.

## Установка

```bash
tar -xzf codex-account-manager.tar.gz
cd codex-account-manager
./install.sh
```

Либо вручную:

```bash
chmod +x ./codex-account
sudo cp ./codex-account /usr/local/bin/codex-account
```

## Быстрый старт

Откройте красивое меню:

```bash
codex-account
```

В меню доступны: добавить аккаунт через `codex login`, сохранить текущий `auth.json`, переключиться, удалить аккаунт, запустить Codex с авто-ротацией и диагностика.

Можно пользоваться и командами напрямую.

1. Добавьте первый аккаунт Codex:

   ```bash
   codex-account add work
   ```

2. Добавьте второй аккаунт:

   ```bash
   codex-account add personal
   ```

3. Переключайтесь вручную:

   ```bash
   codex-account list
   codex-account switch work
   codex-account menu
   ```

4. Запускайте Codex с авто-сменой аккаунта при лимите:

   ```bash
   codex-account run -- exec "исправь failing tests"
   ```

`run` перебирает сохранённые аккаунты и переключается на следующий, если Codex завершился с ошибкой лимита (`rate limit`, `429`, `quota`, `usage limit`, `insufficient_quota` и похожие сообщения).

## Команды

```text
codex-account                  открыть главное меню
codex-account menu             открыть главное меню
codex-account add [name]       выполнить codex login и сохранить аккаунт
codex-account save <name>      сохранить текущий ~/.codex/auth.json как аккаунт
codex-account switch <name>    переключиться на аккаунт
codex-account list             показать сохранённые аккаунты
codex-account current          показать активный аккаунт
codex-account run [--] <args>  запустить Codex и сменить аккаунт при лимите
codex-account delete <name>    удалить сохранённый аккаунт
codex-account doctor           проверить окружение
```

## Переменные окружения

```text
CODEX_HOME          каталог Codex CLI, по умолчанию ~/.codex
CODEX_AUTH_FILE     файл авторизации, по умолчанию $CODEX_HOME/auth.json
CODEX_ACCOUNTS_DIR  каталог профилей, по умолчанию $CODEX_HOME/accounts
CODEX_BIN           бинарь Codex, по умолчанию codex
CODEX_RETRY_DELAY   пауза между аккаунтами в секундах, по умолчанию 2
NO_COLOR=1          выключить цвета
```

Скрипт не печатает содержимое токенов, хранит профили в отдельных директориях, выставляет права `600` на файлы авторизации и делает backup текущего `auth.json` перед переключением.
