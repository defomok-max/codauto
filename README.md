# codauto

Удобный скрипт для переключения и авто-ротации аккаунтов Codex CLI без ручного копирования `~/.codex/auth.json`.

## Установка

```bash
chmod +x ./codex-account
sudo cp ./codex-account /usr/local/bin/codex-account
```

## Быстрый старт

1. Войдите в первый аккаунт Codex:

   ```bash
   codex login
   codex-account save work
   ```

2. Войдите во второй аккаунт и сохраните его:

   ```bash
   codex login
   codex-account save personal
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
codex-account save <name>          сохранить текущий ~/.codex/auth.json как аккаунт
codex-account switch <name>        переключиться на аккаунт
codex-account list                 показать сохранённые аккаунты
codex-account current              показать активный аккаунт
codex-account menu                 интерактивное меню переключения
codex-account run [--] <args...>   запустить Codex и сменить аккаунт при лимите
codex-account delete <name>        удалить сохранённый аккаунт
codex-account doctor               проверить окружение
```

## Переменные окружения

```text
CODEX_HOME          каталог Codex CLI, по умолчанию ~/.codex
CODEX_AUTH_FILE     файл авторизации, по умолчанию $CODEX_HOME/auth.json
CODEX_ACCOUNTS_DIR  каталог профилей, по умолчанию $CODEX_HOME/accounts
CODEX_BIN           бинарь Codex, по умолчанию codex
CODEX_RETRY_DELAY   пауза между аккаунтами в секундах, по умолчанию 2
```

Скрипт не печатает содержимое токенов, хранит профили в отдельных директориях и выставляет права `600` на файлы авторизации.
