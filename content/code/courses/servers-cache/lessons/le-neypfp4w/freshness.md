---
title: Fresh, for how long
version: 1
---

## Where this lesson starts

Lesson 4's hardening belongs on a real server, and two parts of it get in the way of what this lesson
measures: the rate limit refuses most of a benchmark's requests, and the API's own `Cache-Control:
no-store` hides the headers this lesson is about. Keep a copy of lesson 4's site, take its additions
out, and start from the site as lesson 3 left it:

```sh
sudo cp /etc/nginx/sites-available/ipelivros ~/ipelivros.lesson-4
sudo rm /etc/nginx/sites-enabled/catch-all /etc/nginx/conf.d/limits.conf
sudo rm -r /var/www/ipe/.git /etc/systemd/system/shop@.service.d
sudo sed -i 's/server_tokens off;/# server_tokens off;/' /etc/nginx/nginx.conf
sudo systemctl daemon-reload && sudo systemctl restart shop@1 shop@2
```

`/etc/nginx/sites-available/ipelivros`, in place of what is there:

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

## How long a copy is good for

A cache needs one answer before it can keep anything: **for how long is this copy still good?** A copy
that is still good is **fresh**, and a cache serves it without asking anybody. Once its time runs out
it is **stale**, and the cache has to check with the origin before using it again, which is the next
section.

Right now neither the stylesheet nor the API says:

```
ana@web:~$ curl -sI https://ipelivros.example/css/site.css | grep -iE '^(HTTP|cache-control|expires|last-modified|etag)'
HTTP/1.1 200 OK
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
ETag: "6a96cc50-ed"
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE '^(HTTP|cache-control|expires|last-modified|etag)'
HTTP/1.1 200 OK
ETag: "806121fbab2ee803"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
```

No `Cache-Control`, no `Expires`. A browser left with only `Last-Modified` falls back on a
**heuristic**: the RFC suggests treating a copy as fresh for a tenth of the time since the file last
changed. The stylesheet was last changed five weeks before this capture, so a browser could keep it for
three and a half days on that guess, without asking, and whether it does is up to the browser. **A
response without an explicit lifetime is cached by whatever rule the reader prefers**, which is the one
outcome nobody chose.

## Saying it explicitly

For static files, Nginx's `expires` writes both headers. A location for the site's own assets:

```
ana@web:~$ sudo sed -i '0,/    location \/ {/s||    location ~* \\.(css\|js\|svg)$ {\n        expires 1h;\n    }\n\n    location / {|' /etc/nginx/sites-available/ipelivros && grep -n -A2 'location ~' /etc/nginx/sites-available/ipelivros
17:    location ~* \.(css|js|svg)$ {
18-        expires 1h;
19-    }
ana@web:~$ curl -sI https://ipelivros.example/css/site.css | grep -iE '^(date|cache-control|expires|last-modified)'
Date: Wed, 07 Oct 2026 04:00:45 GMT
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Expires: Wed, 07 Oct 2026 05:00:45 GMT
Cache-Control: max-age=3600
```

`Cache-Control: max-age=3600` says "fresh for 3,600 seconds from when it was received", and it is the
header every modern cache reads. `Expires` says the same thing as a date, computed from the response's
own `Date` header plus an hour; it is the older header, kept for the oldest clients, and when both are
present `max-age` wins. Relative time is the better design: it does not depend on the clock of the
machine reading it being right.

The application decides for its own responses. The shop reads `SHOP_CACHE_CONTROL` from its
environment file and sends whatever it says:

```
ana@web:~$ echo 'SHOP_CACHE_CONTROL=max-age=60' | sudo tee /etc/shop/shop.env && sudo systemctl restart shop@1 shop@2
SHOP_CACHE_CONTROL=max-age=60
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE '^(cache-control|etag|last-modified)'
ETag: "806121fbab2ee803"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Cache-Control: max-age=60
```

A book is now fresh for a minute after any copy of it is taken. The number is a decision about the
business, not about servers: a price that is a minute out of date is acceptable on a catalogue page and
not on the page that takes the payment. Lesson 6 is about what to do when a minute is too long.
