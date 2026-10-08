#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 9`, with memcached installed as Ubuntu ships it except
# for the `-l ::1` line, which the lab's machine cannot open (lab.sh says
# why). The Python files the lesson shows are written into ~/work by this
# script, and the two extra memcached processes of the last blocks are
# stopped by pid at the end. CAS tokens, pids and times differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 9
quiet 'printf "flush_all\r\n" | nc -q1 127.0.0.1 11211'

block start
run 'sudo systemctl enable --now memcached && systemctl is-active memcached'
run "grep -vE '^(#|$)' /etc/memcached.conf"
run "printf 'version\r\n' | nc -q1 127.0.0.1 11211"

block protocol
run "printf 'set greeting 0 0 5\r\nhello\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'get greeting\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'get nothing-here\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'add greeting 0 0 3\r\nbye\r\nreplace nothing-here 0 0 3\r\nbye\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'set views 0 0 1\r\n0\r\nincr views 5\r\ndecr views 9\r\nincr greeting 1\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'delete greeting\r\ndelete greeting\r\n' | nc -q1 127.0.0.1 11211"

block cas
run "printf 'set stock:2 0 0 1\r\n4\r\ngets stock:2\r\n' | nc -q1 127.0.0.1 11211"
run "t=\$(printf 'gets stock:2\r\n' | nc -q1 127.0.0.1 11211 | awk 'NR==1{print \$5}'); echo \"token \$t\"; printf \"cas stock:2 0 0 1 \$t\r\n3\r\n\" | nc -q1 127.0.0.1 11211; printf \"cas stock:2 0 0 1 \$t\r\n3\r\n\" | nc -q1 127.0.0.1 11211"
run "printf 'get stock:2\r\n' | nc -q1 127.0.0.1 11211"

block expiry
run "printf 'set session:7f3a 0 3 3\r\nana\r\nget session:7f3a\r\n' | nc -q1 127.0.0.1 11211; sleep 4; printf 'get session:7f3a\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'set month 0 2592000 1\r\nx\r\nset month-and-a-second 0 2592001 1\r\ny\r\nget month month-and-a-second\r\n' | nc -q1 127.0.0.1 11211"
run "printf \"set until 0 \$(( \$(date +%s) + 60 )) 1\r\nz\r\nget until\r\n\" | nc -q1 127.0.0.1 11211"
run "printf 'set note 0 5 2\r\nhi\r\ntouch note 600\r\n' | nc -q1 127.0.0.1 11211; sleep 6; printf 'get note\r\n' | nc -q1 127.0.0.1 11211"

put /home/ana/work/fill_mc.py <<'EOF'
import sys

from pymemcache.client.base import Client

mc = Client(("127.0.0.1", 11211))
count, size = int(sys.argv[1]), int(sys.argv[2])
for i in range(count):
    mc.set(f"filler:{i}", b"x" * size, noreply=False)
print("written", count, "values of", size, "bytes")
EOF

block memory
quiet 'sudo chown ana: /home/ana/work/fill_mc.py'
run "timeout 1 memcached -u memcache -vv -p 11299 -l 127.0.0.1 2>&1 | grep 'slab class' | sed -n '1,4p;\$p'"
run "sudo sed -i 's/^-m 64\$/-m 8/' /etc/memcached.conf && sudo systemctl restart memcached"
run "printf 'get stock:2 views\r\n' | nc -q1 127.0.0.1 11211"
at '~/work'
run 'python3 fill_mc.py 20000 1000'
run "printf 'stats\r\n' | nc -q1 127.0.0.1 11211 | grep -E ' (limit_maxbytes|bytes|curr_items|total_items|evictions) '"
run "printf 'stats slabs\r\n' | nc -q1 127.0.0.1 11211 | grep -E ':(chunk_size|total_pages|used_chunks) '"
run "printf 'get filler:0\r\nget filler:19999\r\n' | nc -q1 127.0.0.1 11211 | cut -c1-40"
run "python3 -c 'from pymemcache.client.base import Client; Client((\"127.0.0.1\", 11211)).set(\"big\", b\"x\" * 2_000_000, noreply=False)' 2>&1 | tail -1"
quiet "sudo sed -i 's/^-m 8\$/-m 64/' /etc/memcached.conf && sudo systemctl restart memcached"
at '~'

put /home/ana/work/memcache_books.py <<'EOF'
import json

from pymemcache.client.base import Client

import catalogue

JSON = 1


class JsonSerde:
    def serialize(self, key, value):
        return json.dumps(value).encode(), JSON

    def deserialize(self, key, value, flags):
        if flags != JSON:
            raise ValueError(f"{key}: flags {flags}, not JSON")
        return json.loads(value)


mc = Client(("127.0.0.1", 11211), serde=JsonSerde(), default_noreply=False)

mc.set("book:2", catalogue.get_book(2), expire=60)
print(mc.get("book:2")["title"])

print("add again:", mc.add("book:2", {}))

mc.set_many({f"book:{i}": catalogue.get_book(i) for i in (3, 4, 5)}, expire=60)
found = mc.get_many(["book:3", "book:4", "book:99"])
print(sorted(found), "queries:", catalogue.queries)
EOF

block python
quiet 'sudo chown ana: /home/ana/work/memcache_books.py'
at '~/work'
run 'python3 memcache_books.py'
run "printf 'get book:2\r\n' | nc -q1 127.0.0.1 11211 | cut -c1-70"
run "python3 -c 'from pymemcache.client.base import Client; mc = Client((\"127.0.0.1\", 11211)); print(mc.add(\"book:2\", b\"{}\"), mc.add(\"book:2\", b\"{}\", noreply=False))'"
at '~'

put /home/ana/work/spread.py <<'EOF'
from pymemcache.client.hash import HashClient

servers = [("127.0.0.1", 11211), ("127.0.0.1", 11212)]
mc = HashClient(servers, default_noreply=False)
for i in range(1000):
    mc.set(f"book:{i}", b"1")
print("book:7 lives on", mc.hasher.get_node("book:7"))
EOF

put /home/ana/work/moves.py <<'EOF'
import zlib

from pymemcache.client.rendezvous import RendezvousHash

keys = [f"book:{i}" for i in range(10000)]


def modulo(key, n):
    return zlib.crc32(key.encode()) % n


def rendezvous(key, n):
    return RendezvousHash(nodes=list(range(n))).get_node(key)


for name, place in (("modulo", modulo), ("rendezvous", rendezvous)):
    moved = sum(place(k, 2) != place(k, 3) for k in keys)
    print(f"{name:>10}: {moved} of {len(keys)} keys move ({moved / len(keys):.0%})")
EOF

block many
quiet 'sudo chown ana: /home/ana/work/spread.py /home/ana/work/moves.py'
quiet 'printf "flush_all\r\n" | nc -q1 127.0.0.1 11211'
run 'sudo memcached -d -u memcache -l 127.0.0.1 -p 11212 -m 64 && sudo memcached -d -u memcache -l 127.0.0.1 -p 11213 -m 64 && pgrep -a memcached'
at '~/work'
run 'python3 spread.py'
run "for p in 11211 11212; do printf 'stats\r\n' | nc -q1 127.0.0.1 \$p | grep ' curr_items '; done"
run 'python3 moves.py'
at '~'

block security
run "printf 'stats settings\r\n' | nc -q1 127.0.0.1 11211 | grep -E ' (tcpport|udpport|inter|auth_enabled_ascii|item_size_max) '"
run "sudo ss -ltnup | grep -E 'Local|11211' | sed 's/ *\$//'"
run "echo 'shop:Ipe-2026-cache-only' | sudo tee /etc/memcached-auth >/dev/null && sudo chown memcache: /etc/memcached-auth && sudo chmod 600 /etc/memcached-auth"
run "echo '-Y /etc/memcached-auth' | sudo tee -a /etc/memcached.conf && sudo systemctl restart memcached"
run "printf 'get book:7\r\n' | nc -q1 127.0.0.1 11211"
run "printf 'set auth 0 0 24\r\nshop Ipe-2026-cache-only\r\nset book:7 0 0 1\r\n1\r\nget book:7\r\n' | nc -q1 127.0.0.1 11211"
quiet "sudo sed -i '/^-Y /d' /etc/memcached.conf && sudo systemctl restart memcached && sudo rm -f /etc/memcached-auth"

asroot 'for p in $(pgrep -f "memcached -d -u memcache -l 127.0.0.1 -p 1121[23]"); do kill $p; done'
