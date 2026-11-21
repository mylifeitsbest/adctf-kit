# Хардненинг: своя машина + сервисы (окно 10:00–10:40, сеть закрыта)

Порядок важен. Пока сеть закрыта — вы в безопасности, но в 10:40 всё открывается. Успеть защититься и сделать бэкапы.

## ЧАСТЬ A. Своя Kali-машина (и vulnbox) — закрыть вход

### A1. Сменить пароль
Пароли дефолтные и одинаковые на всех ноутах — значит соседи их знают.
```bash
passwd                 # свой пользователь
sudo passwd root       # root, если есть sudo
```
Если пароль не знаете и sudo нет — сброс через GRUB (нужен доступ к консоли/загрузке, диск не зашифрован):
```
1. Reboot, в меню GRUB нажать 'e' на нужной записи.
2. В строке linux ... заменить "ro quiet" на:  rw init=/bin/bash
3. Ctrl+X (загрузка).
4. mount -o remount,rw /
5. passwd <user>        # задать новый
6. exec /sbin/init        (или reboot -f)
```
Диск зашифрован (LUKS спросит пароль при загрузке) — этот трюк не сработает, спроси организаторов.

### A2. SSH-ключи
На ЧУЖОЙ машине мог остаться сгенерённый ключ — он есть и у всех остальных.
```bash
ls -la ~/.ssh /root/.ssh
rm -f ~/.ssh/authorized_keys /root/.ssh/authorized_keys   # снести чужие доступы
rm -f ~/.ssh/id_*                                         # снести чужие приватные ключи
ssh-keygen -t ed25519                                     # свой свежий ключ
# положить свой pubkey в authorized_keys там, куда нужен доступ
```

### A3. Выключить парольный вход по SSH (ГЛАВНЫЙ прошлогодний провал)
```bash
sudoedit /etc/ssh/sshd_config
#   PasswordAuthentication no
#   PermitRootLogin prohibit-password
#   KbdInteractiveAuthentication no
#   ChallengeResponseAuthentication no

# !!! ОБЯЗАТЕЛЬНО проверить оверрайды — тут и была дыра в прошлом году:
grep -rniE 'passwordauth|permitroot' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/

sudo systemctl restart ssh    # или sshd
# ПРОВЕРКА эффективного конфига (не файла!):
sudo sshd -T | grep -iE 'passwordauthentication|permitrootlogin|kbdinteractive'
# должно быть: passwordauthentication no
```

### A4. Выключить лишние сервисы и помнить про broadcast
Нет OpenVPN → вы в одной L2-подсети, бродкасты ходят, до вашего Kali-IP достучатся.
```bash
ss -tulpn                 # что слушает наружу
# заглушить что не нужно, например:
sudo systemctl disable --now smbd nmbd avahi-daemon cups 2>/dev/null
```

## ЧАСТЬ B. Vulnbox — сервисы

### B1. Осмотреться
```bash
ls -la /                 # где лежат сервисы (часто /opt, /srv, /home, /var/www)
systemctl list-units --type=service   # сервисы как systemd-юниты
cat /etc/systemd/system/*.service     # чем и откуда запускаются
ss -tulpn                # какие порты торчат
```

### B2. БЭКАП КАЖДОГО СЕРВИСА (до открытия сети!)
Железо физическое, отката «снапшотом» нет. Бэкапим сами.
```bash
# см. scripts/backup.sh — делает tar кода + дамп БД (postgres/mysql)
./backup.sh <путь_к_сервису> <имя>
# И скопировать бэкап на СВОЮ Kali-машину (не только на vulnbox):
scp -r vulnbox:/backups ./backups_local
```

### B3. Поднять исходники под git (чтобы видеть свои патчи и дифать атаки)
```bash
cd <сервис>; git init -q && git add -A && git commit -qm round0
# после каждого патча: git commit -am "patch: <что>"
```

### B4. Закрыть лишние порты
БД (Postgres/Mysql/Redis/Mongo) наружу не нужна — забиндить на localhost. См. [02_firewall.md](02_firewall.md).

### B5. Сменить дефолтные креды сервисов
БД `admin/admin`, админки с дефолтным паролем — поменять ДО сети (у всех они одинаковые).
Но осторожно: если чекер ходит под этими кредами — сломаешь SLA. Сначала посмотри, как чекер логинится (в дампах/коде), потом меняй только то, что не трогает чекер.

## Чеклист окна 10:00–10:40
- [ ] пароль сменён (Kali + vulnbox)
- [ ] чужие SSH-ключи снесены, свой добавлен
- [ ] парольный SSH выключен и ПРОВЕРЕН через `sshd -T`
- [ ] tcpdump запущен (`scripts/capture.sh`) — см. [05_traffic.md](05_traffic.md)
- [ ] бэкап всех сервисов сделан и скопирован на свою машину
- [ ] `ss -tulpn` просмотрен, БД/лишнее закрыто на localhost
- [ ] сервисы под git
- [ ] все чекеры зелёные (ничего не сломали защитой)
