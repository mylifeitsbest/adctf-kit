#!/usr/bin/env bash
# Ротационный захват трафика. Запустить на vulnbox в 10:00 (до открытия сети).
# Использование: sudo ./capture.sh "port 80 or port 5000"
set -euo pipefail
FILTER="${1:-tcp and not port 22}"
OUT=/data/pcap
mkdir -p "$OUT"

echo "[*] tcpdump -> $OUT, фильтр: $FILTER"
# -G 300: новый файл каждые 5 мин; -W 288: хранить ~сутки; крути под свой диск.
exec tcpdump -i any -s 0 -Z root \
  -w "$OUT/d_%Y%m%d_%H%M%S.pcap" -G 300 -W 288 \
  $FILTER
# Разбор потом:
#   tcpdump -r d_*.pcap -A | grep -E '[A-Z0-9]{31}='
#   tshark -r d.pcap -Y 'http.request' -T fields -e ip.src -e http.user_agent -e http.request.uri
