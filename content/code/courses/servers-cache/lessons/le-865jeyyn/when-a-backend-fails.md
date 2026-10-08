---
title: When one copy fails
version: 1
---

Stop the second copy of the shop, as a crash would, and keep asking:

```
ana@web:~$ sudo systemctl stop shop@2
ana@web:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} " http://ipelivros.example/api/books/1; done; echo
200 200 200 200 200 200 
ana@web:~$ tail -n 2 /var/log/nginx/ipelivros.error.log
2026/10/07 00:26:07 [error] 1212#1212: *288 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.1, server: ipelivros.example, request: "GET /api/books/1 HTTP/1.1", upstream: "http://127.0.0.1:8002/api/books/1", host: "ipelivros.example"
```

**Every request succeeded.** The error log shows what happened to the first one that was sent to the
stopped copy: the connection was refused, and Nginx tried the next member of the group before the
client noticed anything. That is `proxy_next_upstream`, which by default retries on an error or a
timeout before any of the response has been sent. Then the member was marked unavailable, and
nothing else was sent to it.

This is a **passive health check**: Nginx learns that a member is down from real requests failing,
and the two settings that govern it go on each `server` line, `max_fails` (default 1) and
`fail_timeout` (default 10 seconds). After `max_fails` failures within `fail_timeout`, the member is
left alone for `fail_timeout`, and then tried again with one real request.

Stop the other copy as well:

```
ana@web:~$ sudo systemctl stop shop@1
ana@web:~$ curl -si http://ipelivros.example/api/books/1 | head -n 4
HTTP/1.1 502 Bad Gateway
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:26:08 GMT
Content-Type: text/html
ana@web:~$ tail -n 1 /var/log/nginx/ipelivros.error.log
2026/10/07 00:26:08 [error] 1209#1209: *297 no live upstreams while connecting to upstream, client: 127.0.0.1, server: ipelivros.example, request: "GET /api/books/1 HTTP/1.1", upstream: "http://shop/api/books/1", host: "ipelivros.example"
```

**`502 Bad Gateway` means Nginx could not get an answer from the application at all**, and the log
says why in three words: `no live upstreams`. Now start both copies again and ask at once:

```
ana@web:~$ sudo systemctl start shop@1 shop@2
ana@web:~$ curl -s -o /dev/null -w "%{http_code}\n" http://ipelivros.example/api/books/1
502
ana@web:~$ sleep 10; curl -s -o /dev/null -w "%{http_code}\n" http://ipelivros.example/api/books/1
200
```

Still `502` with both copies running, and `200` ten seconds later. Both members were inside their
`fail_timeout`, so Nginx did not try them yet. That is ten seconds of outage after the application
had recovered, and it is the price of a check that only learns from real traffic.

## Active checks, and a member kept in reserve

An **active health check** asks each member on a timer whether it is well, before any real
request is risked. Open-source Nginx does not have one; it is part of the commercial NGINX Plus, and
HAProxy, Traefik and Caddy all do it in their free versions. With open-source Nginx, the usual answer
is that whatever starts the application (systemd here, Kubernetes elsewhere) watches its health and
restarts it, and Nginx's passive check covers the seconds in between.

Two more settings on a `server` line help:

```conf
upstream shop {
    zone shop 64k;
    server 127.0.0.1:8001 max_fails=3 fail_timeout=5s;
    server 127.0.0.1:8002 max_fails=3 fail_timeout=5s;
    server 127.0.0.1:8003 backup;
}
```

`max_fails=3` stops one unlucky request from taking a member out. `backup` names a member that
receives nothing while any other is up: a maintenance page, or a smaller copy elsewhere. There is no
`8003` in this lab, so this block was not loaded here; it is shown for the shape.
