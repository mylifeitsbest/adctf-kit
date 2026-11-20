# Ферма флагов, сабмит в ForcAD, attack_data

## Зачем ферма
Флаги надо сдавать массово, пачками, с рейт-лимитом. Руками один человек не потянет. Эксплойты печатают флаги в stdout → ферма собирает и сдаёт. Стандарт — **DestructiveFarm**.

## Поток
```
attack_data (flag_id'ы)  ->  эксплойт  ->  stdout: флаги  ->  ферма  ->  сабмит ForcAD
```

## DestructiveFarm — настройка
1. `git clone https://github.com/DestructiveVoice/DestructiveFarm` (СЕГОДНЯ).
2. `server/config.py`, ВПИСАТЬ НА ИГРЕ:
```python
CONFIG = {
    'TEAMS': { 'team10': '10.60.10.2' },     # IP жертв (или из attack_data)
    'FLAG_FORMAT': r'[A-Z0-9]{31}=',         # уточнить
    'SYSTEM_PROTOCOL': 'forcad',
    'SYSTEM_URL': 'http://<host>/flags',
    'SYSTEM_TOKEN': '<ВАШ_TEAM_TOKEN>',
    'SUBMIT_FLAG_LIMIT': 100,
    'SUBMIT_PERIOD': 5,
    'FLAG_LIFETIME': 5 * 60,                 # 5 раундов ~2 мин
}
```
> Точные поля/протокол — в `server/config.py` и `server/app/protocols/forcad*.py`. Бывают `forcad` (HTTP) и `forcad_tcp`.
3. Запуск: `docker compose up -d` или `python3 server/app.py`. Веб-морда `http://127.0.0.1:5000`.
4. Эксплойт под фермой: `python3 start_sploit.py sploit.py -u http://127.0.0.1:5000 --pool-size 8` (флаги см. --help).

## Сабмит ForcAD (типовой, ПРОВЕРИТЬ)
```
PUT /flags
Header: X-Team-Token: <токен>
Body JSON: ["FLAG1=", "FLAG2="]
Ответ: [{"flag":"FLAG1=","msg":"...","status":true}]
```
`msg`: accepted — засчитан; invalid — не тот формат; own flag — свой; too old/expired — протух; already submitted — дубль. Запасной: `scripts/submit_min.py`.

## attack_data
В UI нет, адрес дадут на слайде. GET, формат ТИПОВОЙ:
```json
{ "service_name": { "10.60.10.2": ["flag_id_or_username"] } }
```
flag_id — что надо достать. Эксплойт берёт по IP жертвы её flag_id (не угадывать).
```bash
curl -s http://<host>/<attack_data_path> | jq .
```

## Тайминги
- Флаг живёт 5 раундов (~10 мин). Сдавай свежие сразу.
- Перезапуск сервиса → пару раундов attack_data может не находиться — норма.
- По 2 флага на уязвимость за раунд: 3 бага = до 6 флагов с жертвы.
