---
title: HTTPS, and what the application believes
version: 1
---

A real certificate needs a real domain: **certbot** asks Let's Encrypt for one, proves the domain is
yours, and renews it, and the `servers-cache` course does exactly that. `agenda.example.org` is not
yours or anybody's, so this section makes a **self-signed** certificate, which no browser trusts and
which is otherwise the same file in the same place:

```
ana@vm:~/agenda$ sudo install -d -m 755 /etc/ssl/agenda
ana@vm:~/agenda$ sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 90 -subj "/CN=agenda.example.org" -addext "subjectAltName=DNS:agenda.example.org,DNS:api.agenda.example.org" -keyout /etc/ssl/agenda/agenda.key -out /etc/ssl/agenda/agenda.crt
-----
ana@vm:~/agenda$ openssl x509 -in /etc/ssl/agenda/agenda.crt -noout -subject -ext subjectAltName -enddate
subject=CN = agenda.example.org
X509v3 Subject Alternative Name: 
    DNS:agenda.example.org, DNS:api.agenda.example.org
notAfter=Jan 21 00:55:58 2027 GMT
```

The certificate covers both names, for ninety days. Replace the site with a version that redirects
port 80 and serves 443:

```conf
# /etc/nginx/sites-available/agenda
server {
    listen 80;
    server_name agenda.example.org api.agenda.example.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name agenda.example.org;

    ssl_certificate /etc/ssl/agenda/agenda.crt;
    ssl_certificate_key /etc/ssl/agenda/agenda.key;

    location /static/ {
        alias /var/www/agenda/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl;
    server_name api.agenda.example.org;

    ssl_certificate /etc/ssl/agenda/agenda.crt;
    ssl_certificate_key /etc/ssl/agenda/agenda.key;

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy same-origin always;
    add_header Strict-Transport-Security "max-age=3600" always;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```
ana@vm:~/agenda$ sudo nginx -t && sudo systemctl reload nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@vm:~/agenda$ curl -sI http://127.0.0.1/events/ -H "Host: agenda.example.org" | grep -iE "^(HTTP|location)"
HTTP/1.1 301 Moved Permanently
Location: https://agenda.example.org/events/
```

Port 80 now only redirects. Over HTTPS, curl refuses the certificate until it is told to trust it,
which is what a browser would do, and **the right answer is to trust it, never to switch the check
off**:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
000
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
200
ana@vm:~/agenda$ curl -sI --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/admin/login/ | grep -iE "^(HTTP|strict|set-cookie)" | cut -c1-90
HTTP/1.1 200 OK
Strict-Transport-Security: max-age=3600
Set-Cookie: csrftoken=AG0hJHgnhth2uWK7iqNL66uEFnHdBHUg; expires=Fri, 22 Oct 2027 00:55:59 
```

`000` was curl giving up on an unknown certificate. With `--cacert` the page is a 200, and the login
page carries Django's HSTS header and a cookie marked `Secure`, both from the settings this lesson
added. Lesson 15's check again, now with the service's own environment through `systemd-run`:

```
ana@vm:~/agenda$ sudo systemd-run --quiet --wait --pipe --uid=ana -p EnvironmentFile=/etc/agenda/agenda.env -p WorkingDirectory=/home/ana/agenda /home/ana/agenda/.venv/bin/python manage.py check --deploy
System check identified some issues:

WARNINGS:
?: (security.W005) You have not set the SECURE_HSTS_INCLUDE_SUBDOMAINS setting to True. Without this, your site is potentially vulnerable to attack via an insecure connection to a subdomain. Only set this to True if you are certain that all subdomains of your domain should be served exclusively via SSL.
?: (security.W021) You have not set the SECURE_HSTS_PRELOAD setting to True. Without this, your site cannot be submitted to the browser preload list.

System check identified 2 issues (0 silenced).
```

The four HTTPS warnings are gone. The two left are deliberate: **include subdomains** and **preload**
extend HSTS to every name under the domain and into browsers' built-in lists, and both are hard to
take back, so a site raises them after HSTS has run without trouble for a while, as the short
`max-age` of an hour is meant to allow.

## What the application believes

Behind a proxy, every request reaches the application from `127.0.0.1`, over plain HTTP. Two headers
tell it otherwise, and **only because nginx is trusted to write them**.

`X-Forwarded-Proto` is what `SECURE_PROXY_SSL_HEADER` reads: Django treats a request as HTTPS when
that header says `https`, which is why the secure cookie was set. Without it, `SECURE_SSL_REDIRECT`
would send every request back to HTTPS, forever; the next section shows that loop.

`X-Forwarded-For` is the client's address. Ask the API from another local address, `127.0.0.2`, once
plainly and once with a forged header:

```
ana@vm:~/agenda$ curl -s -o /dev/null --interface 127.0.0.2 --cacert /etc/ssl/agenda/agenda.crt --resolve api.agenda.example.org:443:127.0.0.1 https://api.agenda.example.org/events/django-night
ana@vm:~/agenda$ curl -s -o /dev/null --interface 127.0.0.2 -H "X-Forwarded-For: 203.0.113.9" --cacert /etc/ssl/agenda/agenda.crt --resolve api.agenda.example.org:443:127.0.0.1 https://api.agenda.example.org/events/django-night
ana@vm:~/agenda$ journalctl -u agenda-api -n 2 --no-pager -o cat
INFO:     127.0.0.2:0 - "GET /events/django-night HTTP/1.0" 200 OK
INFO:     127.0.0.2:0 - "GET /events/django-night HTTP/1.0" 200 OK
ana@vm:~/agenda$ sudo tail -2 /var/log/nginx/access.log | cut -c1-110
127.0.0.2 - - [23/Oct/2026:00:56:00 +0000] "GET /events/django-night HTTP/1.1" 200 162 "-" "curl/8.5.0"
127.0.0.2 - - [23/Oct/2026:00:56:00 +0000] "GET /events/django-night HTTP/1.1" 200 162 "-" "curl/8.5.0"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 194\" role=\"img\" aria-label=\"curl, connecting from 127.0.0.2, sends a forged X-Forwarded-For of 203.0.113.9. nginx appends the address it saw, giving 203.0.113.9, 127.0.0.2. Uvicorn, which trusts only 127.0.0.1, where nginx connects from, takes the last untrusted entry, 127.0.0.2, as the client.\"> <defs><marker id=\"fw-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"10\" y=\"60\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"105\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">curl, from 127.0.0.2</text> <text x=\"105\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">X-Forwarded-For: 203.0.113.9</text> <path d=\"M200 90 L226 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-a)\"></path> <rect x=\"230\" y=\"60\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"330\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nginx appends the peer it saw</text> <text x=\"330\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.9, 127.0.0.2</text> <path d=\"M430 90 L486 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-a)\"></path> <rect x=\"490\" y=\"60\" width=\"210\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"595\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uvicorn trusts only 127.0.0.1</text> <text x=\"595\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">client = 127.0.0.2</text> <text x=\"360\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Read from the right, and stop at the first address you do not trust:</text> <text x=\"360\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">everything to its left is whatever the client chose to write.</text> </svg>", "caption": "Why the forged address did not reach the API's log: the header is a list, and only its right end is written by something trusted."}
```

**Both requests are logged as 127.0.0.2**, in nginx's log and in Uvicorn's. `--proxy-headers` makes
Uvicorn read the header; `--forwarded-allow-ips 127.0.0.1` says only nginx's entries are believed, so
the forged `203.0.113.9` to their left is ignored. Django has no equivalent setting: `REMOTE_ADDR` is
always the proxy's address, and a view that needs the client's must read the header the same careful
way, from the right.
