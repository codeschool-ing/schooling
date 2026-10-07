#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 10`, with Redis running as lesson 8 left it and the
# shop's database as `lab.sh` writes it, book 2 at 8,990 cents. The Python
# files the lesson shows are written into ~/work by this script. The races
# are timed with sleeps, which the files show and the lesson explains; times
# in milliseconds differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 10
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

put /home/ana/work/stale.py <<'EOF'
import catalogue
from bookcache import get_book, r, update_price

r.delete("book:2")
print("cached:", get_book(2)["price_cents"])

catalogue.set_price(2, 7990)
print("database changed, cache says:", get_book(2)["price_cents"], "for", r.ttl("book:2"), "more seconds")

update_price(2, 6990)
print("update_price, cache says:", get_book(2)["price_cents"])
EOF

block aside
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 bookcache.py'
run 'redis-cli TTL book:2'
run 'python3 stale.py'

put /home/ana/work/writers.py <<'EOF'
import json
import threading
import time

import catalogue
from bookcache import get_book, r

base = catalogue.get_book(2)


def set_on_write(price, before_db, before_cache):
    time.sleep(before_db)
    catalogue.set_price(2, price)
    time.sleep(before_cache)
    r.set("book:2", json.dumps(dict(base, price_cents=price)), ex=300)


def delete_on_write(price, before_db, before_cache):
    time.sleep(before_db)
    catalogue.set_price(2, price)
    time.sleep(before_cache)
    r.delete("book:2")


for name, write in (("set on write", set_on_write), ("delete on write", delete_on_write)):
    a = threading.Thread(target=write, args=(7990, 0.0, 0.2))
    b = threading.Thread(target=write, args=(6990, 0.1, 0.0))
    a.start(); b.start(); a.join(); b.join()
    print(f"{name:>15}: database {catalogue.get_book(2)['price_cents']}, cache {get_book(2)['price_cents']}")
EOF

put /home/ana/work/readers.py <<'EOF'
import json
import threading
import time

import catalogue
from bookcache import get_book, r, update_price


def slow_reader():
    book = catalogue.get_book(2)        # the cache missed; this is the old price
    time.sleep(0.2)                     # a pause: a busy CPU, a garbage collection
    r.set("book:2", json.dumps(book), ex=300)


def writer(price, delete_again):
    time.sleep(0.2)                     # the reader has its row by now
    update_price(2, price)
    if delete_again:
        time.sleep(0.5)                 # longer than any read takes
        r.delete("book:2")


for price, delete_again in ((7990, False), (6990, True)):
    r.delete("book:2")
    threads = [threading.Thread(target=slow_reader), threading.Thread(target=writer, args=(price, delete_again))]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    print(f"delete again {delete_again!s:>5}: database {price}, cache {get_book(2)['price_cents']}, ttl {r.ttl('book:2')}")
EOF

block writes
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 writers.py'
run 'python3 readers.py'

put /home/ana/work/through.py <<'EOF'
import json

import redis

import catalogue


class BookCache:
    """Read-through and write-through: the application talks only to this."""

    def __init__(self, client, ttl=300):
        self.r, self.ttl = client, ttl

    def get(self, book_id):
        cached = self.r.get(f"book:{book_id}")
        if cached is not None:
            return json.loads(cached)
        book = catalogue.get_book(book_id)
        self.r.set(f"book:{book_id}", json.dumps(book), ex=self.ttl)
        return book

    def set_price(self, book_id, price_cents):
        catalogue.set_price(book_id, price_cents)
        book = catalogue.get_book(book_id)
        self.r.set(f"book:{book_id}", json.dumps(book), ex=self.ttl)


books = BookCache(redis.Redis(decode_responses=True))
books.r.delete("book:2")
books.set_price(2, 5990)
print("after the write: ttl", books.r.ttl("book:2"), "queries", catalogue.queries)
print("read:", books.get(2)["price_cents"], "queries", catalogue.queries)
EOF

put /home/ana/work/behind.py <<'EOF'
import json

import redis

import catalogue

r = redis.Redis(decode_responses=True)


def set_price(book_id, price_cents):
    with r.pipeline() as pipe:          # MULTI ... EXEC: both or neither
        pipe.set(f"price:{book_id}", price_cents)
        pipe.rpush("pending-prices", json.dumps([book_id, price_cents]))
        pipe.execute()


def flush():
    written = 0
    while (item := r.lpop("pending-prices")) is not None:
        catalogue.set_price(*json.loads(item))
        written += 1
    return written


r.delete("pending-prices")
for price in (5490, 4990, 4490):
    set_price(2, price)
print("cache", r.get("price:2"), "| database", catalogue.get_book(2)["price_cents"], "| pending", r.llen("pending-prices"))
print("flushed", flush(), "writes | database", catalogue.get_book(2)["price_cents"])
EOF

block through
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 through.py'
run 'python3 behind.py'

put /home/ana/work/missing.py <<'EOF'
import json

import catalogue
from bookcache import r

MISSING = "missing"


def get_book(book_id, negative_ttl=None):
    key = f"book:{book_id}"
    cached = r.get(key)
    if cached == MISSING:
        return None
    if cached is not None:
        return json.loads(cached)
    book = catalogue.get_book(book_id)
    if book is None:
        if negative_ttl:
            r.set(key, MISSING, ex=negative_ttl)
        return None
    r.set(key, json.dumps(book), ex=300)
    return book


for negative_ttl in (None, 30):
    r.delete("book:99")
    before = catalogue.queries
    for _ in range(10):
        get_book(99, negative_ttl)
    print(f"negative_ttl={negative_ttl}: 10 reads of book 99, queries: {catalogue.queries - before}")
EOF

put /home/ana/work/versions.py <<'EOF'
import json

import catalogue
from bookcache import r

r.set("catalogue:version", 1, nx=True)


def key(book_id):
    return f"v{r.get('catalogue:version')}:book:{book_id}"


def get_book(book_id):
    cached = r.get(key(book_id))
    if cached is not None:
        return json.loads(cached)
    book = catalogue.get_book(book_id)
    r.set(key(book_id), json.dumps(book), ex=300)
    return book


def read_three():
    before = catalogue.queries
    for book_id in (1, 2, 3):
        get_book(book_id)
    return catalogue.queries - before


print("first pass, queries:", read_three())
print("second pass, queries:", read_three())
print("version is now", r.incr("catalogue:version"))
print("third pass, queries:", read_three())
EOF

block keys
quiet 'sudo chown -R ana: /home/ana/work'
at '~/work'
run 'python3 missing.py'
run 'redis-cli GET book:99; redis-cli TTL book:99'
run 'python3 versions.py'
run "redis-cli --scan --pattern 'v*:book:*' | sort"
