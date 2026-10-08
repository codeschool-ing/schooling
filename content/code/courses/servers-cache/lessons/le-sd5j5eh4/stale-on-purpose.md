---
title: Serving the stale copy on purpose
version: 1
---

So far a stale copy has been the problem. There are two moments when it is the best answer available.

## When the application is down

`proxy_cache_use_stale` names the failures for which Nginx may serve an expired copy instead of an
error. With a lifetime of five seconds, let the copy expire and stop both shops:

```
ana@web:~$ sudo sed -i 's|        proxy_cache api_cache;|        proxy_cache api_cache;\n        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;|' /etc/nginx/sites-available/ipelivros && grep -n 'use_stale' /etc/nginx/sites-available/ipelivros
25:        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/3 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"A Hora da Estrela","price_cents":3990}
X-Cache-Status: MISS
ana@web:~$ sleep 6; sudo systemctl stop shop@1 shop@2
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/3 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"A Hora da Estrela","price_cents":3990}
X-Cache-Status: STALE
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/books/4
502
ana@web:~$ sudo systemctl start shop@1 shop@2
```

**`STALE`, and a price that was correct six seconds ago, instead of a `502`.** For a catalogue, a page
with prices a few seconds old is far better than an error page, and the shops being down is invisible
to anybody whose request has a copy. A book that was never cached has nothing to fall back on, and gets
the `502`. Whether this is right depends on the data: a stale catalogue during an outage is a kindness,
and a stale account balance is a lie. Lesson 5's `must-revalidate` is how an origin asks every cache never
to do this for a response; whether a particular cache honours it is worth testing, and the safe place to
decide is the cache's own configuration, with no `proxy_cache_use_stale` in the locations that serve such
responses.

## While a new copy is being fetched

When a copy expires and requests keep coming, the first one waits for the shop, 120 ms here, and so
does every other request that arrives before the new copy is in. `updating` in the same directive, with
`proxy_cache_background_update on`, changes that: the expired copy is served at once, and the fetch
happens behind it.

```
ana@web:~$ sudo sed -i 's|        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;|        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;\n        proxy_cache_background_update on;|' /etc/nginx/sites-available/ipelivros && grep -n 'use_stale\|background' /etc/nginx/sites-available/ipelivros
25:        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
26:        proxy_cache_background_update on;
ana@web:~$ curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' https://ipelivros.example/api/books/5
200 in 0.149338 s
ana@web:~$ sleep 6; for i in 1 2 3; do curl -s -o /dev/null -D /tmp/h -w '%{time_total} s ' https://ipelivros.example/api/books/5; grep -i x-cache-status /tmp/h; sleep 0.5; done
0.027254 s X-Cache-Status: STALE
0.027737 s X-Cache-Status: HIT
0.027568 s X-Cache-Status: HIT
```

The first request after expiry got `STALE` in 27 milliseconds, the time of a cached answer, not the
150 of the shop; the copy was refreshed in the background, and the next requests are `HIT`s again. The
cost is that one visitor saw an answer up to one lifetime plus one fetch old. This is HTTP's
**stale-while-revalidate**, and an origin can ask for it in its own header, `Cache-Control: max-age=60,
stale-while-revalidate=30`, which many browsers and CDNs honour too.

Lesson 11 comes back to this moment from the other side: what happens to the shop when the copy of a
popular page expires and a thousand requests arrive in the same second.
