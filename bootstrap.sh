#!/usr/bin/env bash
# Запустить ОДИН раз на машине С ИНТЕРНЕТОМ, чтобы затащить DestructiveFarm в репо.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FARM="$HERE/DestructiveFarm"
if [ -d "$FARM" ]; then echo "DestructiveFarm уже есть, пропускаю"; exit 0; fi

echo "[*] Клонирую DestructiveFarm..."
git clone --depth 1 https://github.com/DestructiveVoice/DestructiveFarm "$FARM"
rm -rf "$FARM/.git"
echo "[OK] DestructiveFarm вложен. Теперь git add -A && commit && push."
