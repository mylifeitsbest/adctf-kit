#!/usr/bin/env python3
"""
Запасной минимальный сабмиттер флагов в ForcAD — на случай, если ферма не поднялась.
Читает флаги из stdin или из файла, шлёт пачками с паузой, печатает ответ.
Протокол ForcAD ТИПОВОЙ — проверь URL / имя заголовка токена в /serp на игре.

Использование:
  cat flags.txt | python3 submit_min.py
  python3 submit_min.py flags.txt
"""
import sys, re, time, requests

SYSTEM_URL = "http://<host>/flags"     # <-- ВПИСАТЬ
TEAM_TOKEN = "<ВАШ_TOKEN>"             # <-- ВПИСАТЬ
TOKEN_HEADER = "X-Team-Token"          # <-- проверить имя заголовка
FLAG_RE = re.compile(r'[A-Z0-9]{31}=')  # <-- уточнить формат
BATCH = 100
PERIOD = 5

def read_flags():
    src = open(sys.argv[1]) if len(sys.argv) > 1 else sys.stdin
    text = src.read()
    return list(dict.fromkeys(FLAG_RE.findall(text)))   # уникальные, порядок сохранён

def submit(batch):
    try:
        r = requests.put(SYSTEM_URL, headers={TOKEN_HEADER: TEAM_TOKEN},
                         json=batch, timeout=10)
        print(r.status_code, r.text[:500], file=sys.stderr)
    except Exception as e:
        print("submit error:", e, file=sys.stderr)

def main():
    flags = read_flags()
    print(f"flags to send: {len(flags)}", file=sys.stderr)
    for i in range(0, len(flags), BATCH):
        submit(flags[i:i+BATCH])
        time.sleep(PERIOD)

if __name__ == "__main__":
    main()
