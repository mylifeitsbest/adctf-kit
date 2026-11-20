# Как пользоваться репо на игре

Репо уже публичный. На боевой машине (Kali/Ubuntu, там git есть):
```bash
git clone https://github.com/mylifeitsbest/adctf-kit.git
cd adctf-kit
cp SECRETS.template.txt secrets.txt   # заполнить реальными значениями (в репо не попадёт)
```
Затем затянуть ферму:
```bash
git clone https://github.com/DestructiveVoice/DestructiveFarm
```
Дальше по [00_prep_3h.md](00_prep_3h.md) и [README.md](README.md).

## Безопасность
- Репо публичный → токены/пароли только в `secrets.txt` (он в `.gitignore`).
- Не коммить pcap/бэкапы/флаги.
- После игры репо можно удалить или сделать приватным.
