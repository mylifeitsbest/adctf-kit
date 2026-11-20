# Порты и фаервол

## Главная мысль про фаервол в A/D
Нельзя тупо «забанить атакующих». Чекер/jury ходит с того же диапазона, что и команды,
и его IP не блокируется (так сказали на открытии). Забанишь подсеть → уронишь SLA → минус очки.

Поэтому фаервол здесь для:
1. **Закрыть служебные порты** (БД, админки, SSH снаружи) — это безопасно и важно.
2. **LOG** на сервисных портах для анализа.
3. Тонкая фильтрация (по user-agent/поведению) — опционально и поздно; сначала разведай трафик jury (см. [05_traffic.md](05_traffic.md)), потом фильтруй.

**Основная защита — патч уязвимости в коде сервиса, а не фаервол.**

## Аудит портов
```bash
ss -tulpn          # TCP/UDP listen + процессы
# см. scripts/portaudit.sh
```
Решение по каждому порту:
- порт сервиса (чекер к нему ходит) → оставить открытым всем;
- БД/кеш/внутреннее → забиндить на 127.0.0.1 или закрыть фаерволом;
- SSH → только своей команде.

### Забиндить БД на localhost (примеры)
```
Postgres  /etc/postgresql/*/main/postgresql.conf : listen_addresses = 'localhost'
MySQL     /etc/mysql/**/*.cnf                      : bind-address = 127.0.0.1
Redis     /etc/redis/redis.conf                    : bind 127.0.0.1
Mongo     /etc/mongod.conf                         : bindIp: 127.0.0.1
```
Если сервис в docker — проверь проброс портов в `docker-compose.yml` (`"0.0.0.0:5432:5432"` → `"127.0.0.1:5432:5432"`), перезапусти контейнер.

---

## Вариант iptables (Kali и старые системы)
```bash
SVC_PORTS="80,443,5000"        # <-- порты ваших сервисов
TEAM_NET="10.0.0.0/8"          # <-- откуда ваша команда ходит по SSH (уточнить)

iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH только своим
iptables -A INPUT -p tcp --dport 22 -s $TEAM_NET -j ACCEPT

# Сервисы — всем (чекер тоже из этой сети), но логируем
iptables -A INPUT -p tcp -m multiport --dports $SVC_PORTS -j LOG --log-prefix "SVC: " --log-level 4
iptables -A INPUT -p tcp -m multiport --dports $SVC_PORTS -j ACCEPT

# остальное молча дропается (политика DROP)
iptables -nvL --line-numbers       # проверка
```
> НЕ отрубите себе SSH до того, как добавили правило для него. Держите вторую сессию открытой.

---

## Вариант nftables (Ubuntu 26 — новая схема, netfilter/nft)
На Ubuntu 26 по умолчанию nftables. Проверь: `nft list ruleset`.
```bash
cat >/etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept
    ct state established,related accept
    # SSH только своим (поправь сеть):
    tcp dport 22 ip saddr 10.0.0.0/8 accept
    # сервисные порты всем, с логом:
    tcp dport { 80, 443, 5000 } log prefix "SVC " accept
    # ICMP для чекера аптайма часто нужен:
    ip protocol icmp accept
  }
  chain forward { type filter hook forward priority 0; policy drop; }
  chain output  { type filter hook output  priority 0; policy accept; }
}
EOF
nft -f /etc/nftables.conf
systemctl enable --now nftables
nft list ruleset        # проверка
```

## Если решили фильтровать атакующих (поздняя стадия)
Сначала по дампам (05_traffic.md) пойми, чем jury-чекер отличается от атак:
- стабильный User-Agent / набор заголовков у чекера;
- чекер ходит ровно раз в раунд по предсказуемым ручкам;
- атака — всплеск однотипных запросов к одной уязвимой ручке.
Тогда можно дропать по строке в payload (nftables `@th`/`string` match в iptables) ИЛИ, что надёжнее,
чинить логику в самом сервисе (rate-limit, валидация). Патч лучше фильтра — фильтр ломается об изменённый эксплойт.
