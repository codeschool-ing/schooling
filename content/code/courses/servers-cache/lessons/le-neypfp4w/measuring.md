---
title: Measuring what the cache does
version: 1
---

A cache nobody measures is a cache nobody can defend, or tune, or notice failing. The number that
matters is the **hit ratio**: the share of requests answered from the cache. Nginx knows it for every
request in `$upstream_cache_status`, and a log format of its own writes it down:

```
ana@web:~$ cat /etc/nginx/conf.d/cache-log.conf
log_format cache '$remote_addr [$time_local] "$request" $status '
                 'cache=$upstream_cache_status upstream_time=$upstream_response_time';
ana@web:~$ sudo sed -i 's|    access_log /var/log/nginx/ipelivros.access.log;|    access_log /var/log/nginx/ipelivros.access.log;\n    access_log /var/log/nginx/ipelivros.cache.log cache;|' /etc/nginx/sites-available/ipelivros
```

The same site can write two logs, one in the ordinary format and one for the cache. Two hundred
requests, spread over ten books, after emptying the cache, which is deleting its files:

```sh
sudo find /var/cache/nginx/shop -type f -delete
```

Then the requests:

```
ana@web:~$ for i in $(seq 200); do curl -s -o /dev/null https://ipelivros.example/api/books/$(( (i % 10) + 1 )); done; tail -n 3 /var/log/nginx/ipelivros.cache.log
127.0.0.1 [07/Oct/2026:01:01:12 -0300] "GET /api/books/9 HTTP/1.1" 200 cache=HIT upstream_time=-
127.0.0.1 [07/Oct/2026:01:01:12 -0300] "GET /api/books/10 HTTP/1.1" 200 cache=HIT upstream_time=-
127.0.0.1 [07/Oct/2026:01:01:12 -0300] "GET /api/books/1 HTTP/1.1" 200 cache=HIT upstream_time=-
ana@web:~$ awk '{print $8}' /var/log/nginx/ipelivros.cache.log | sort | uniq -c
    190 cache=HIT
     10 cache=MISS
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 5}
{"server": "shop2", "db_queries": 5}
```

**190 hits and 10 misses: a hit ratio of 95 percent**, and the shops made one database query per book,
ten in all, where two hundred requests without the cache would have made two hundred. A hit shows
`upstream_time=-`, because no upstream was asked.

Two things move that number, and neither is in Nginx's configuration. **How many different things are
asked for**: ten books cached for a minute is easy; a hundred thousand books, each asked for once a day,
would almost never hit, whatever the cache's size. And **how long a copy may live**: a lifetime shorter
than the gap between two requests for the same thing turns every request into a miss. A low hit ratio
is a fact about the traffic and the lifetimes before it is a fact about the cache.

## And what it buys

`ab`, ten at a time, two hundred requests for one book: first straight at the shop, then through Nginx
with the copy in its cache.

```
ana@web:~$ ab -q -n 200 -c 10 http://localhost:8001/api/books/6 | grep -E 'Requests per second|Time per request.*mean\)$'
Requests per second:    68.51 [#/sec] (mean)
Time per request:       145.967 [ms] (mean)
ana@web:~$ ab -q -n 200 -c 10 https://ipelivros.example/api/books/6 | grep -E 'Requests per second|Time per request.*mean\)$'
Requests per second:    1184.88 [#/sec] (mean)
Time per request:       8.440 [ms] (mean)
```

68.51 requests a second against 1,184.88. The shop's number is the database's: every request waits
120 ms for its query, and ten at a time gives the ceiling of about 80 a second, minus the overhead. The
cached number is Nginx's, including a TLS handshake for every request, since `ab` does not reuse
connections. The ratio between them, about seventeen times on this machine, is what a cache in front of a
slow application is for, and it is also why the next lesson exists: every one of those fast answers is
only as current as the copy it was served from.
