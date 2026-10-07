---
title: The same stampede at the proxy
version: 1
---

This section uses the site and the shop as lesson 5 left them: the cache on, and the shop's lifetime
at sixty seconds. If you went on through lessons 6 and 7, put them back, and stop the edge:

```sh
echo 'SHOP_CACHE_CONTROL=public, max-age=60' | sudo tee /etc/shop/shop.env
sudo systemctl restart shop@1 shop@2
sudo systemctl stop varnish
sudo rm /etc/nginx/sites-enabled/origin
sudo nginx -t && sudo systemctl reload nginx
```

The shop counts its database queries per copy, at `/api/stats`. Set both counts to zero before each run
below, as the transcripts did:

```sh
curl -s -X POST http://127.0.0.1:8001/api/stats/reset
curl -s -X POST http://127.0.0.1:8002/api/stats/reset
```

Nginx's cache from lesson 5 has the same problem, one layer up. This program is forty visitors, each in
its own thread. Each one connects first, then waits at a barrier, so that all forty ask at the same
instant for a page that is not yet cached:

```schooling-example
{"language": "python", "file": "visitors.py", "parts": [{"code": "import http.client\nimport sys\nimport threading\nfrom collections import Counter\n\nhost, path, visitors = sys.argv[1], sys.argv[2], int(sys.argv[3])\ngate = threading.Barrier(visitors)\nseen = Counter()\n\n\ndef visitor():\n    conn = http.client.HTTPSConnection(host)\n    conn.connect()                      # the TLS handshake, before the start\n    gate.wait()                         # then everybody asks at the same moment\n    conn.request(\"GET\", path)\n    response = conn.getresponse()\n    seen[response.status, response.getheader(\"X-Cache-Status\")] += 1\n\n\nthreads = [threading.Thread(target=visitor) for _ in range(visitors)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(sorted(seen.items()))\n", "note": "Visitors that each connect first and then all ask for one page at the same instant."}]}
```

```
ana@web:~/work$ python3 visitors.py ipelivros.example /api/books/3 40
[((200, 'MISS'), 40)]
ana@web:~/work$ curl -s http://127.0.0.1:8001/api/stats; curl -s http://127.0.0.1:8002/api/stats
{"server": "shop1", "db_queries": 20}
{"server": "shop2", "db_queries": 20}
```

**Forty visitors, forty misses, forty queries**, twenty on each copy of the shop. Nginx forwarded every
one, because each found nothing in the cache when it arrived. The fix is one directive:

```
ana@web:~/work$ sudo sed -i 's/^\( *\)proxy_cache api_cache;$/&\n\1proxy_cache_lock on;/' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache' /etc/nginx/sites-available/ipelivros
23:        proxy_cache api_cache;
24:        proxy_cache_lock on;
25:        proxy_cache_bypass $http_authorization;
ana@web:~/work$ sudo nginx -t && sudo systemctl reload nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

`proxy_cache_lock on` is this lesson's lock, built into Nginx: **the first request for a missing entry
goes to the upstream, and the rest wait for it to fill the cache.** Another page, another forty visitors, with both counts set to zero first:

```
ana@web:~/work$ python3 visitors.py ipelivros.example /api/books/4 40
[((200, 'HIT'), 39), ((200, 'MISS'), 1)]
ana@web:~/work$ curl -s http://127.0.0.1:8001/api/stats; curl -s http://127.0.0.1:8002/api/stats
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 0}
```

**One miss, thirty-nine hits, one query.** The waiting requests were answered from the cache as soon as
the first one filled it. `proxy_cache_lock_timeout`, 5 seconds by default, is the lock's lifetime: a
request that has waited that long goes to the upstream itself, and its answer is not cached.

Two other layers of this course already had an answer. **Lesson 6's `proxy_cache_use_stale updating`**
with `proxy_cache_background_update on` is serving stale, in Nginx: an expired entry is served while one
request refreshes it. And **Varnish, from lesson 7, coalesces by default**: concurrent requests for an
object it is already fetching wait on a list for that one fetch, which is the lock above with nothing to
switch on.
