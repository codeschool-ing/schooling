---
title: A shared cache in front of the application
version: 1
---

Freshness lets a browser skip a request. To spare the application the requests of **every** visitor,
the copy has to be kept somewhere they all pass through, and Nginx is already in that place. Two pieces
of configuration make it a cache: where to keep the copies, at the `http` level, and which location
uses them.

```
ana@web:~$ cat /etc/nginx/conf.d/cache.conf
proxy_cache_path /var/cache/nginx/shop levels=1:2 keys_zone=api_cache:10m
                 max_size=100m inactive=10m use_temp_path=off;
ana@web:~$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
2026/10/07 01:00:48 [emerg] 1445#1445: mkdir() "/var/cache/nginx/shop" failed (2: No such file or directory)
nginx: configuration file /etc/nginx/nginx.conf test failed
ana@web:~$ sudo mkdir -p /var/cache/nginx && sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

The test caught something before any request was made: Nginx creates the cache's own directory and
not the directories above it, and Ubuntu has no `/var/cache/nginx`. `levels=1:2` spreads the files over
two levels of subdirectories, so that no single directory ends up holding a million files.
`keys_zone=api_cache:10m` is shared memory for the index of what is stored, about eight thousand keys
per megabyte; `max_size` bounds the disk, and `inactive=10m` throws out anything nobody asked for in ten
minutes, fresh or not. The zone needs a name of its own: `shop` was already taken by the upstream.

In the location, `proxy_cache` switches the cache on, and an extra header reports what it did for each
request, which is the only way to see a cache working from outside:

```
ana@web:~$ sudo sed -i 's|        proxy_pass http://shop;|        proxy_pass http://shop;\n        proxy_cache api_cache;\n        add_header X-Cache-Status $upstream_cache_status always;|' /etc/nginx/sites-available/ipelivros && grep -n -A2 'proxy_pass' /etc/nginx/sites-available/ipelivros
26:        proxy_pass http://shop;
27-        proxy_cache api_cache;
28-        add_header X-Cache-Status $upstream_cache_status always;
ana@web:~$ for i in 1 2 3; do curl -s -o /dev/null -D - -w 'took %{time_total} s\n' https://ipelivros.example/api/books/2 | grep -iE '^x-cache-status|^took'; done
X-Cache-Status: MISS
took 0.151113 s
X-Cache-Status: HIT
took 0.041534 s
X-Cache-Status: HIT
took 0.030108 s
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 0}
```

**`MISS`, then `HIT`, `HIT`, and the shops counted one database query between them**, where three
requests without the cache made three. The first request paid the 120 ms of the database; the next two
took 42 and 30 milliseconds, and nearly all of that is `curl` opening a new TLS connection each time,
since the copy itself came off Nginx's disk.

Nginx took the lifetime from the shop's own `Cache-Control: max-age=60`, so nothing in Nginx's
configuration says for how long: **the origin decides, and every cache on the path obeys the same
line**. The copy is a file, and its first line is the **key** it is stored under:

```
ana@web:~$ sudo find /var/cache/nginx/shop -type f
/var/cache/nginx/shop/9/67/e8fb3bb9dc4188361a54f7d7c9036679
ana@web:~$ sudo find /var/cache/nginx/shop -type f -exec grep -a -m1 '^KEY' {} \;
KEY: http://shop/api/books/2
```

`http://shop/api/books/2`: the default key is the scheme and name **of the upstream**, followed by the
request's path and query. Two sites proxying to the same upstream group would therefore share copies,
which is right for a site under two names and wrong for two different sites; a key written as
`$scheme$host$request_uri` keeps them apart.

## When the copy runs out

With a lifetime of five seconds:

```
ana@web:~$ grep SHOP /etc/shop/shop.env
SHOP_CACHE_CONTROL=max-age=5
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: MISS
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: HIT
ana@web:~$ sleep 6; curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: EXPIRED
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: HIT
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 1}
```

`MISS` stores it, `HIT` serves it, and six seconds later `EXPIRED`: the copy was stale, so Nginx went to
the shop for a new one and stored that. Two database queries for four requests. Nginx could also have
**revalidated** the stale copy with a conditional request, sending the shop the `ETag` it held, by
adding `proxy_cache_revalidate on`; with the shop's `304` costing as much as a `200`, that would save
nothing here, and lesson 6 has a better use for a stale copy.

## What it does not store

```
ana@web:~$ grep SHOP /etc/shop/shop.env
SHOP_CACHE_CONTROL=private, max-age=60
ana@web:~$ for i in 1 2 3; do curl -s -o /dev/null -D - https://ipelivros.example/api/books/4 | grep -iE '^(cache-control|x-cache-status)'; done
Cache-Control: private, max-age=60
X-Cache-Status: MISS
Cache-Control: private, max-age=60
X-Cache-Status: MISS
Cache-Control: private, max-age=60
X-Cache-Status: MISS
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 2}
```

`private` means no shared cache may keep it, and Nginx obeyed: `MISS` three times, because it looked,
found nothing and stored nothing, and three database queries for three requests. The next section is about
why that refusal matters more than any hit ratio.
