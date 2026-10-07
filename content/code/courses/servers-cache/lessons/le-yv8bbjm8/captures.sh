#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 8`, with Redis started (`systemctl enable --now
# redis-server`, which the lesson shows) and its configuration as Ubuntu
# ships it. The Python files the lesson shows are written into ~/work by this
# script. The `sleep 1` before each SHUTDOWN gives the append-only file its
# once-a-second fsync. Times, memory figures and ids differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 8
quiet 'redis-cli FLUSHALL'

block start
run 'sudo systemctl enable --now redis-server && systemctl is-active redis-server'
run 'redis-cli PING'
run "redis-cli INFO server | grep -E '^(redis_version|redis_mode|process_id|tcp_port|config_file):'"
run "sudo grep -nE '^(bind|protected-mode|port|save|appendonly|dir|dbfilename) ' /etc/redis/redis.conf"

block strings
run 'redis-cli SET greeting "Bem-vindo à Ipê Livros"'
run 'redis-cli GET greeting'
run 'redis-cli GET nothing-here'
run 'redis-cli SET views:book:2 0 && redis-cli INCR views:book:2 && redis-cli INCRBY views:book:2 10'
run 'redis-cli SET lock:report ana NX; redis-cli SET lock:report bruno NX; redis-cli GET lock:report'
run 'redis-cli TYPE views:book:2; redis-cli OBJECT ENCODING views:book:2'

block expiry
run 'redis-cli SET session:7f3a ana EX 30'
run 'redis-cli TTL session:7f3a; redis-cli PTTL session:7f3a'
run 'redis-cli TTL greeting; redis-cli TTL nothing-here'
run 'redis-cli EXPIRE greeting 2 && sleep 3 && redis-cli GET greeting'
run 'redis-cli PERSIST session:7f3a && redis-cli TTL session:7f3a'

block structures
run 'redis-cli HSET book:2 title "Grande Sertão: Veredas" price_cents 8990 stock 4'
run 'redis-cli HGET book:2 price_cents; redis-cli HINCRBY book:2 stock -1; redis-cli HGETALL book:2'
run 'for b in 3 7 2 9 3; do redis-cli LPUSH recent:ana book:$b > /dev/null; done; redis-cli LTRIM recent:ana 0 2; redis-cli LRANGE recent:ana 0 -1'
run 'redis-cli SADD tag:classic book:4 book:11 book:2; redis-cli SADD tag:sertao book:2 book:12 book:1; redis-cli SINTER tag:classic tag:sertao'
run 'redis-cli ZINCRBY bestsellers 5 book:9; redis-cli ZINCRBY bestsellers 3 book:2; redis-cli ZINCRBY bestsellers 4 book:4; redis-cli ZINCRBY bestsellers 2 book:2'
run 'redis-cli ZREVRANGE bestsellers 0 2 WITHSCORES'
run 'redis-cli --scan --pattern "book:*"; redis-cli DBSIZE'

put /home/ana/work/redis_books.py <<'EOF'
import json

import redis

from catalogue import get_book

r = redis.Redis(host="127.0.0.1", port=6379, decode_responses=True)

book = get_book(2)
r.set("book:2:json", json.dumps(book), ex=60)
print("ttl", r.ttl("book:2:json"))

cached = json.loads(r.get("book:2:json"))
print(cached["title"], cached["price_cents"])

with r.pipeline() as pipe:
    for book_id in (1, 3, 5):
        pipe.zincrby("bestsellers", 1, f"book:{book_id}")
    pipe.zrevrange("bestsellers", 0, 2, withscores=True)
    print(pipe.execute()[-1])
EOF

block python
quiet 'sudo chown ana: /home/ana/work/redis_books.py'
at '~/work'
run 'python3 redis_books.py'
run 'redis-cli GET book:2:json'
at '~'

put /home/ana/work/fill.py <<'EOF'
import sys

import redis

r = redis.Redis()
written = 0
try:
    for i in range(int(sys.argv[1])):
        r.set(f"filler:{i}", "x" * 1000)
        written += 1
except redis.exceptions.ResponseError as e:
    print("error after", written, "keys:", e)
print("written", written)
EOF

block memory
quiet 'sudo chown ana: /home/ana/work/fill.py'
at '~/work'
run "redis-cli CONFIG SET maxmemory 2mb; redis-cli CONFIG GET maxmemory-policy"
run 'python3 fill.py 5000'
run "redis-cli CONFIG SET maxmemory-policy allkeys-lru && python3 fill.py 5000"
run "redis-cli INFO stats | grep -E '^evicted_keys'; redis-cli DBSIZE; redis-cli INFO memory | grep -E '^(used_memory_human|maxmemory_human|maxmemory_policy):'"
run 'redis-cli EXISTS bestsellers book:2'
at '~'

block persistence
run 'redis-cli FLUSHALL && redis-cli CONFIG SET maxmemory 0 && redis-cli CONFIG SET maxmemory-policy noeviction'
run 'redis-cli SET before-snapshot 1 && redis-cli BGSAVE && sleep 1 && sudo ls -l /var/lib/redis'
run 'redis-cli SET after-snapshot 2 && redis-cli DBSIZE'
run 'redis-cli SHUTDOWN NOSAVE; sleep 1; sudo systemctl start redis-server; sleep 1; redis-cli KEYS "*"'
run 'redis-cli CONFIG SET appendonly yes && redis-cli CONFIG REWRITE && sleep 2 && sudo ls /var/lib/redis /var/lib/redis/appendonlydir'
run 'redis-cli SET after-aof 3 && sleep 1 && redis-cli SHUTDOWN NOSAVE; sleep 1; sudo systemctl start redis-server; sleep 1; redis-cli KEYS "*" | sort'

block security
run 'redis-cli ACL LIST'
run 'redis-cli ACL SETUSER shop on ">lab-shop-password" "~cache:*" +@read +@write -@dangerous'
run 'redis-cli --user shop --pass lab-shop-password --no-auth-warning SET cache:book:2 "{}" EX 60'
run 'redis-cli --user shop --pass lab-shop-password --no-auth-warning GET bestsellers'
run 'redis-cli --user shop --pass lab-shop-password --no-auth-warning FLUSHALL'
run 'redis-cli --user shop --pass lab-shop-password --no-auth-warning CONFIG GET requirepass'
run 'redis-cli ACL DELUSER shop'
