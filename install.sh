#!/usr/bin/env bash
set -Eeuo pipefail

PREFIX="${PREFIX:-/usr/local/bin}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$PREFIX/codex-account"

if [[ ! -f "$SCRIPT_DIR/codex-account" ]]; then
  printf 'Не найден %s/codex-account\n' "$SCRIPT_DIR" >&2
  exit 1
fi

if [[ -w "$PREFIX" ]]; then
  install -m 0755 "$SCRIPT_DIR/codex-account" "$TARGET"
else
  sudo install -m 0755 "$SCRIPT_DIR/codex-account" "$TARGET"
fi

printf 'Готово: %s\n' "$TARGET"
printf 'Запуск меню: codex-account\n'
