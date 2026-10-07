---
title: Choosing which copy answers
version: 1
---

Round robin assumes every member is the same and every request costs the same. When either is
false, the upstream block has three other answers.

## Weights, when the members differ

If `shop1` ran on a machine three times the size of `shop2`'s, it should take three times the
requests:

```
ana@web:~$ sudo sed -i 's/server 127.0.0.1:8001;/server 127.0.0.1:8001 weight=3;/' /etc/nginx/sites-available/ipelivros && sed -n '1,6p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    server 127.0.0.1:8001 weight=3;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ for i in $(seq 100); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c
     75 shop1
     25 shop2
```

Seventy-five and twenty-five, exactly. A weight is a ratio, and it is the tool for moving traffic on
purpose too: a new version on one member at `weight=1` against nine others at `weight=9` receives a
tenth of the requests, which is the simplest form of a canary release.

## `least_conn`, when the requests differ

Round robin counts requests and ignores how long each one takes. Start one slow request, four
seconds of work, and send four quick ones while it runs:

```
ana@web:~$ (curl -s "http://ipelivros.example/api/slow?s=4" > /dev/null &); sleep 0.5; for i in 1 2 3 4; do curl -s http://ipelivros.example/api/echo | jq -r .server; done
shop2
shop1
shop2
shop1
```

The slow request went to `shop1`, and round robin carried on taking turns, sending half of the quick
ones to the member that was still busy. Here that cost nothing, because the shop has threads to
spare. A member with a fixed number of workers, all busy with slow requests, would have queued them.
`least_conn` sends each request to the member with the fewest requests in progress:

```
ana@web:~$ sudo sed -i 's/^    zone shop 64k;/    zone shop 64k;\n    least_conn;/' /etc/nginx/sites-available/ipelivros && sed -n '1,7p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ (curl -s "http://ipelivros.example/api/slow?s=4" > /dev/null &); sleep 0.5; for i in 1 2 3 4; do curl -s http://ipelivros.example/api/echo | jq -r .server; done
shop2
shop2
shop2
shop2
```

All four went to `shop2`, the member with nothing in progress. **`least_conn` is the better default
whenever request times vary a lot**, which is true of most APIs: a list page and a search are not the
same amount of work. It needs `zone` even more than round robin does, since "in progress" counted by
each worker alone is a quarter of the truth.

## `hash`, when the same client should reach the same copy

```
ana@web:~$ sudo sed -i 's/    least_conn;/    hash $remote_addr;/' /etc/nginx/sites-available/ipelivros && sed -n '1,7p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    hash $remote_addr;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ for i in $(seq 20); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c
     20 shop2
```

`hash $remote_addr` picks the member from the client's address, so the same client always lands on
the same copy: here, every one of twenty requests from `127.0.0.1` went to `shop2`. That is called
**session affinity**, and it is for an application that keeps something per user in its own memory,
a login session or a half-filled basket, which the other copy cannot see.

It is also a workaround rather than a design. Many clients behind one office network share one
address and land on one member together; when a member goes away, its clients move and lose what it
held. **The application that keeps its sessions in a shared store, such as Redis in lesson 8, needs no
affinity at all**, and every member can answer every request.

| method | picks | good for |
|---|---|---|
| round robin (default) | each in turn | identical members, similar requests |
| `weight=` | in proportion | members of different sizes, a canary |
| `least_conn` | fewest in progress | requests of very different cost |
| `hash` / `ip_hash` | the same member for the same key | state kept in a member's memory |
