---
title: The price that did not change
version: 1
---

## Where this lesson starts

Lesson 5 left a log format, an `expires` for the static files and a second access log in the site.
This lesson starts without them, from the site with the cache on:

```sh
sudo rm /etc/nginx/conf.d/cache-log.conf
```

`/etc/nginx/sites-available/ipelivros`:

```conf
upstream shop {
    zone shop 64k;
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 443 ssl;
    include snippets/ipelivros-tls.conf;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://shop;
        proxy_cache api_cache;
        proxy_cache_bypass $http_authorization;
        proxy_no_cache     $http_authorization;
        add_header X-Cache-Status $upstream_cache_status always;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    location /.well-known/acme-challenge/ {
        root /var/www/ipe;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
```

```sh
sudo nginx -t && sudo systemctl reload nginx
```

## The price that did not change

Lesson 5 ended with a cache that answers seventeen times faster than the application behind it. This
lesson starts with what it costs. The shop's owner lowers the price of a book:

```
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":8990}
X-Cache-Status: MISS
ana@web:~$ curl -s -X PUT -d '{"price_cents": 7990}' https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7990}
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":8990}
X-Cache-Status: HIT
ana@web:~$ curl -s localhost:8001/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7990}
```

**The database says 7,990 cents and every visitor is told 8,990.** Nothing failed. The cache did exactly
what it was told: the shop said the answer was good for sixty seconds, Nginx kept it for sixty seconds,
and the `PUT` that changed the price went straight to the shop without the cache ever hearing of it.
Asked directly, past the cache, the shop gives the new price.

That is the whole problem of this lesson, and the reason for the old joke that there are only two hard
things in computer science, cache invalidation and naming things. **A cache is a copy, and a copy does not
know when the original changes.** Something has to tell it, or it has to stop believing itself after a
while, and every technique in this lesson is one of those two.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 190\" role=\"img\" aria-label=\"A timeline of sixty seconds. At second 0 the cache stores the price 8,990. At second 20 the database changes to 7,990. From second 20 to second 60 the cache keeps answering 8,990: forty seconds of a wrong answer. At second 60 the copy expires and the next request fetches 7,990.\"><defs><marker id=\"fsw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"120\" x2=\"640\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsw-ah)\"></line><line x1=\"60.0\" y1=\"114\" x2=\"60.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"60.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><line x1=\"225.71428571428572\" y1=\"114\" x2=\"225.71428571428572\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"225.71428571428572\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 s</text><line x1=\"557.1428571428571\" y1=\"114\" x2=\"557.1428571428571\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"557.1428571428571\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60 s</text><rect x=\"60.0\" y=\"70\" width=\"165.71428571428572\" height=\"30\" fill=\"var(--phosphor-dim)\" stroke=\"none\" fill-opacity=\"0.5\"></rect><rect x=\"225.71428571428572\" y=\"70\" width=\"331.4285714285714\" height=\"30\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.35\"></rect><text x=\"142.85714285714286\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cache: 8,990, correct</text><text x=\"391.42857142857144\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cache: 8,990 while the database says 7,990</text><text x=\"225.71428571428572\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the price changes</text><line x1=\"225.71428571428572\" y1=\"56\" x2=\"225.71428571428572\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsw-ah)\"></line><text x=\"557.1428571428571\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the copy expires</text><line x1=\"557.1428571428571\" y1=\"56\" x2=\"557.1428571428571\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsw-ah)\"></line><text x=\"391.42857142857144\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the stale window: at most one lifetime</text></svg>", "caption": "A copy with a sixty-second lifetime, and a change at second 20. Without invalidation, the wrong answer lives until the copy expires."}
```

Two numbers describe the risk. **How long a copy may be wrong**, which is at most its lifetime: sixty
seconds here. And **how wrong it may be**: a price a minute out of date on a catalogue page is a
nuisance; the same price on the page that takes the payment is a complaint, and on the page that
confirms an order it is a legal problem. The next section turns those into a decision.
