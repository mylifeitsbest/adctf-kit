#!/usr/bin/env bash
# Что торчит наружу. Решение по каждому порту: сервис (оставить) / внутреннее (закрыть на localhost).
# Докера нет — сервисы это локальные процессы/systemd.
set -euo pipefail
echo "=== Слушающие сокеты (процессы) ==="
ss -tulpn 2>/dev/null || sudo ss -tulpn

echo; echo "=== Запущенные systemd-сервисы ==="
systemctl list-units --type=service --state=running | head -40

echo; echo "ПОДСКАЗКА:"
echo " - 0.0.0.0:<БД/redis/mongo/mysql/postgres> -> перебиндить на 127.0.0.1 и перезапустить"
echo " - порт сервиса (к нему ходит чекер) -> оставить открытым"
echo " - SSH (22) -> ограничить своей сетью (см. 02_firewall.md)"
