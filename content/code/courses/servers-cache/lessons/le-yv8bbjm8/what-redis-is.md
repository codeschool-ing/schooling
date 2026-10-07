---
title: What Redis is
version: 1
---

Lessons 5 to 7 cached **responses**: whole answers to HTTP requests, kept by programs that know nothing
about what is inside them. This half of the course caches **data**: the book, the price, the list of
bestsellers, kept by the application in a form it chose, in a store built for it. The store most
applications reach for is Redis.

**Redis is a server that keeps everything in memory and answers commands about it over a network
socket.** It is a separate process, so every copy of the application shares it: the two shops of
lesson 2 see the same Redis, which is exactly what they cannot do with a dictionary in their own
memory. And it is a **data structure server**, not just a box of strings: a value can be a string, a
hash, a list, a set or a sorted set, each with commands that change it in place, one command at a time,
without anybody else's command getting in between.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Left: two copies of the shop, each with a dictionary in its own memory, holding different copies of book 2. Right: the same two copies talking over a socket to one Redis, which holds the one copy both read.\"><defs><marker id=\"fsh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a dictionary in each process</text><rect x=\"20\" y=\"30\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop1</text><text x=\"90.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">book:2 → 8990</text><rect x=\"180\" y=\"30\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop2</text><text x=\"250.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">book:2 → 7990</text><text x=\"170\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">two copies that disagree</text><text x=\"530\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one Redis, shared</text><rect x=\"390\" y=\"30\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop1</text><rect x=\"550\" y=\"30\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop2</text><rect x=\"450\" y=\"130\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">redis :6379</text><text x=\"530.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">book:2 → 7990</text><line x1=\"450\" y1=\"74\" x2=\"500\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsh-ah)\"></line><line x1=\"610\" y1=\"74\" x2=\"560\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsh-ah)\"></line></svg>", "caption": "An in-process cache is one copy per process. A shared server is one copy for all of them."}
```

That last property has a simple cause. Redis runs every command on **one thread**, in order. There are
no locks to take and no two commands half-done at once, so `INCR` on a counter is correct with a
thousand clients using it. The price is that one slow command delays every client, which is why a
command that walks every key, `KEYS *`, is a habit to drop on a production server.

Ubuntu's package installed it, stopped. Start it and ask it the two things worth knowing first:

```
ana@web:~$ sudo systemctl enable --now redis-server && systemctl is-active redis-server
Synchronizing state of redis-server.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable redis-server
active
ana@web:~$ redis-cli PING
PONG
ana@web:~$ redis-cli INFO server | grep -E '^(redis_version|redis_mode|process_id|tcp_port|config_file):'
redis_version:7.0.15
redis_mode:standalone
process_id:1400
tcp_port:6379
config_file:/etc/redis/redis.conf
ana@web:~$ sudo grep -nE '^(bind|protected-mode|port|save|appendonly|dir|dbfilename) ' /etc/redis/redis.conf
87:bind 127.0.0.1 -::1
111:protected-mode yes
138:port 6379
481:dbfilename dump.rdb
504:dir /var/lib/redis
1379:appendonly no
```

Version 7.0, one process, listening on port 6379, and **bound to `127.0.0.1` only**, with `protected-mode`
on. Out of the box, nothing but this machine can talk to it, and the last section of this lesson is
about keeping it that way. The other lines say where it keeps a copy on disk, `dump.rdb` in
`/var/lib/redis`, and that its second way of keeping one, the append-only file, is off. The section on
persistence turns it on.
