#!/usr/bin/env bash
# Бэкап сервиса: код + (если docker) образ и volume. Запускать на vulnbox ДО открытия сети.
# Использование: ./backup.sh <путь_к_сервису> <имя>
set -euo pipefail
SRC="${1:?путь к сервису}"; NAME="${2:?имя}"
DEST="/backups/${NAME}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DEST"

echo "[*] архив кода..."
tar czf "$DEST/code.tgz" -C "$(dirname "$SRC")" "$(basename "$SRC")"

if command -v docker >/dev/null 2>&1; then
  echo "[*] docker образы/volume (если есть)..."
  docker ps --format '{{.Names}}' | while read -r c; do
    docker commit "$c" "backup/${c}:$(date +%s)" || true
  done
  docker volume ls -q | while read -r v; do
    docker run --rm -v "$v":/v -v "$DEST":/b alpine \
      sh -c "tar czf /b/vol_${v}.tgz -C /v . " || true
  done
fi

echo "[OK] бэкап в $DEST"
echo "!!! Скопируй на СВОЮ машину:  scp -r vulnbox:$DEST ./"
