#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 11`, with Redis running, Nginx caching the API as lesson 5
# left it, and `bookcache.py` from lesson 10 written into ~/work again,
# unchanged. The Python files this lesson shows are written by this script.
# Each stampede is fifty threads of one Python process, not fifty visitors;
# `ab` is the visitors at the HTTP layer. `early.py` is a simulation and says
# so. Times differ on every run; query counts should not.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 11
quiet 'redis-cli FLUSHALL'

put /home/ana/work/bookcache.py <<'EOF'
import json
import time

import redis

import catalogue

r = redis.Redis(decode_responses=True)
TTL = 300


def get_book(book_id):
    key = f"book:{book_id}"
    cached = r.get(key)
    if cached is not None:
        return json.loads(cached)
    book = catalogue.get_book(book_id)
    r.set(key, json.dumps(book), ex=TTL)
    return book


def update_price(book_id, price_cents):
    catalogue.set_price(book_id, price_cents)
    r.delete(f"book:{book_id}")


if __name__ == "__main__":
    r.delete("book:2")
    for attempt in (1, 2, 3):
        start = time.perf_counter()
        book = get_book(2)
        ms = (time.perf_counter() - start) * 1000
        print(f"read {attempt}: {book['price_cents']} in {ms:.1f} ms, queries {catalogue.queries}")
EOF

put /home/ana/work/stampede.py <<'EOF'
import importlib
import sys
import threading
import time

import catalogue

readers, module = int(sys.argv[1]), importlib.import_module(sys.argv[2])
if "--keep" not in sys.argv:
    module.r.delete("book:2")

before = catalogue.queries
start = time.perf_counter()
threads = [threading.Thread(target=module.get_book, args=(2,)) for _ in range(readers)]
for t in threads:
    t.start()
for t in threads:
    t.join()
ms = (time.perf_counter() - start) * 1000
print(f"{sys.argv[2]}, readers at once: {readers}, database queries: {catalogue.queries - before}, {ms:.0f} ms")
EOF

block stampede
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 stampede.py 1 bookcache'
run 'python3 stampede.py 50 bookcache'
run 'python3 stampede.py 50 bookcache --keep'

put /home/ana/work/lockcache.py <<'EOF'
import json
import secrets
import time

import redis

import catalogue

r = redis.Redis(decode_responses=True)
TTL = 300
LOCK_MS = 2000

RELEASE = r.register_script("""
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
end
return 0
""")


def get_book(book_id):
    key, lock = f"book:{book_id}", f"lock:book:{book_id}"
    while True:
        cached = r.get(key)
        if cached is not None:
            return json.loads(cached)
        token = secrets.token_hex(8)
        if r.set(lock, token, nx=True, px=LOCK_MS):
            try:
                cached = r.get(key)
                if cached is not None:
                    return json.loads(cached)
                book = catalogue.get_book(book_id)
                r.set(key, json.dumps(book), ex=TTL)
                return book
            finally:
                RELEASE(keys=[lock], args=[token])
        time.sleep(0.02)
EOF

block lock
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 stampede.py 50 lockcache'
run 'redis-cli SET lock:book:2 crashed PX 2000 && python3 stampede.py 50 lockcache'

put /home/ana/work/swrcache.py <<'EOF'
import json
import threading
import time

import redis

import catalogue

r = redis.Redis(decode_responses=True)
FRESH, STALE = 300, 3600
REFRESH_MS = 2000


def load(book_id):
    book = catalogue.get_book(book_id)
    entry = {"book": book, "fresh_until": time.time() + FRESH}
    r.set(f"book:{book_id}", json.dumps(entry), ex=FRESH + STALE)
    return book


def get_book(book_id):
    cached = r.get(f"book:{book_id}")
    if cached is None:
        return load(book_id)
    entry = json.loads(cached)
    if entry["fresh_until"] < time.time():
        if r.set(f"refresh:book:{book_id}", 1, nx=True, px=REFRESH_MS):
            threading.Thread(target=load, args=(book_id,)).start()
    return entry["book"]
EOF

put /home/ana/work/stale_demo.py <<'EOF'
import json
import threading
import time

import catalogue
import swrcache

book = catalogue.get_book(2)
stale = {"book": dict(book, price_cents=8990), "fresh_until": time.time() - 60}
swrcache.r.set("book:2", json.dumps(stale), ex=3600)
catalogue.set_price(2, 7990)

prices, slowest = set(), 0.0
before = catalogue.queries


def visitor():
    global slowest
    start = time.perf_counter()
    prices.add(swrcache.get_book(2)["price_cents"])
    slowest = max(slowest, (time.perf_counter() - start) * 1000)


threads = [threading.Thread(target=visitor) for _ in range(50)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(f"50 readers: prices {sorted(prices)}, slowest {slowest:.1f} ms")
time.sleep(0.3)
print(f"a moment later: {swrcache.get_book(2)['price_cents']}, queries {catalogue.queries - before}")
EOF

block stale
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 stale_demo.py'

put /home/ana/work/early.py <<'EOF'
import math
import random

random.seed(2026)
EXPIRY, DELTA, GAP = 300.0, 0.12, 0.01  # expires at 300 s; a refresh takes 120 ms; a read every 10 ms


def should_refresh(now, expiry, delta, beta=1.0):
    return now - delta * beta * math.log(1 - random.random()) >= expiry


for beta in (1.0, 2.0):
    early = []
    for trial in range(1000):
        now = EXPIRY - 5
        while not should_refresh(now, EXPIRY, DELTA, beta):
            now += GAP
        early.append(EXPIRY - now)
    early.sort()
    print(f"beta {beta}: median {early[500]:.2f} s before expiry, latest {early[0]:.2f} s before, "
          f"{sum(e <= 0 for e in early)} of 1000 reached expiry")
EOF

put /home/ana/work/jitter.py <<'EOF'
import random
from collections import Counter

import redis

r = redis.Redis(decode_responses=True)
random.seed(7)

for name, ttl in (("fixed", lambda: 300), ("jittered", lambda: 300 + random.randint(0, 60))):
    with r.pipeline() as pipe:
        for i in range(1000):
            pipe.set(f"{name}:book:{i}", "x", ex=ttl())
        pipe.execute()
    with r.pipeline() as pipe:
        for i in range(1000):
            pipe.ttl(f"{name}:book:{i}")
        per_second = Counter(pipe.execute())
    print(f"{name:>8}: different expiry seconds: {len(per_second):>2}, most keys expiring in one second: {max(per_second.values())}")
EOF

block spread
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 early.py'
run 'python3 jitter.py'
at '~'

put /home/ana/work/visitors.py <<'EOF'
import http.client
import sys
import threading
from collections import Counter

host, path, visitors = sys.argv[1], sys.argv[2], int(sys.argv[3])
gate = threading.Barrier(visitors)
seen = Counter()


def visitor():
    conn = http.client.HTTPSConnection(host)
    conn.connect()                      # the TLS handshake, before the start
    gate.wait()                         # then everybody asks at the same moment
    conn.request("GET", path)
    response = conn.getresponse()
    seen[response.status, response.getheader("X-Cache-Status")] += 1


threads = [threading.Thread(target=visitor) for _ in range(visitors)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(sorted(seen.items()))
EOF

block http
quiet 'sudo chown -R ana: /home/ana/work'
quiet 'curl -s -X POST http://127.0.0.1:8001/api/stats/reset; curl -s -X POST http://127.0.0.1:8002/api/stats/reset'
at '~/work'
run 'python3 visitors.py ipelivros.example /api/books/3 40'
run 'curl -s http://127.0.0.1:8001/api/stats; curl -s http://127.0.0.1:8002/api/stats'
run "sudo sed -i 's/^\\( *\\)proxy_cache api_cache;\$/&\\n\\1proxy_cache_lock on;/' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache' /etc/nginx/sites-available/ipelivros"
run 'sudo nginx -t && sudo systemctl reload nginx'
quiet 'sleep 1; curl -s -X POST http://127.0.0.1:8001/api/stats/reset; curl -s -X POST http://127.0.0.1:8002/api/stats/reset'
run 'python3 visitors.py ipelivros.example /api/books/4 40'
run 'curl -s http://127.0.0.1:8001/api/stats; curl -s http://127.0.0.1:8002/api/stats'

put /home/ana/work/warm.py <<'EOF'
import sys
import time

import catalogue
from bookcache import get_book

start = time.perf_counter()
for book_id in map(int, sys.argv[1:]):
    get_book(book_id)
ms = (time.perf_counter() - start) * 1000
print(f"warmed {len(sys.argv) - 1} books in {ms:.0f} ms, {catalogue.queries} queries, one at a time")
EOF

block warm
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'redis-cli FLUSHALL && redis-cli DBSIZE'
run 'python3 warm.py $(seq 1 12)'
run 'python3 stampede.py 50 bookcache --keep'
