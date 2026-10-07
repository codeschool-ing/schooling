---
title: Replacing one copy now
version: 1
---

Open-source Nginx has no `PURGE` command; the module for it is part of the commercial NGINX Plus. What
it does have is `proxy_cache_bypass`, already used in lesson 5 to send requests with credentials past
the cache. A bypassed request goes to the shop, and **its answer is stored**, replacing whatever was
there. So a request that only the site's operator can make becomes a refresh button for one URL.

```
ana@web:~$ cat /etc/nginx/conf.d/refresh.conf
# A request carrying this header is sent to the shop, and its answer replaces
# the cached copy. The token keeps strangers from emptying the cache at will.
map $http_x_cache_refresh $cache_refresh {
    default                    0;
    "lab-refresh-token-2026"   1;
}
ana@web:~$ sudo sed -i 's|        proxy_cache_bypass $http_authorization;|        proxy_cache_bypass $http_authorization $cache_refresh;|' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache_bypass' /etc/nginx/sites-available/ipelivros
24:        proxy_cache_bypass $http_authorization $cache_refresh;
```

`map` turns a header into a variable: `1` when the request carries the right token, `0` otherwise, and
`proxy_cache_bypass` skips the cache whenever any of its values is neither empty nor `0`. Then:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'X-Cache-Refresh: lab-refresh-token-2026' https://ipelivros.example/api/books/2 | grep -i x-cache-status
X-Cache-Status: BYPASS
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":7990}
X-Cache-Status: HIT
ana@web:~$ curl -s -o /dev/null -D - -H 'X-Cache-Refresh: guess' https://ipelivros.example/api/books/2 | grep -i x-cache-status
X-Cache-Status: HIT
```

`BYPASS` fetched the new price and stored it, and the next ordinary request is a `HIT` with 7,990. A
wrong token is an ordinary request, served from the copy.

**The token matters.** Without it, anybody who learns the header's name can send every request past the
cache, which turns a cache that protects the application into a way of aiming traffic at it. A token in
a header is the minimum; a refresh endpoint that only listens on an internal address, or that only
accepts requests from the machines that publish content, is better. And the refresh is per URL: a price
that appears on twenty pages needs twenty refreshes, which is where the next lesson's purge by tag
comes in.
