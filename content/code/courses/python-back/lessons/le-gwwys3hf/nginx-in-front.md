---
title: nginx in front of both applications
version: 1
---

nginx's configuration for a site is a file in `/etc/nginx/sites-available`, enabled by a link in
`sites-enabled`. One file holds both of agenda's names. `/etc/nginx/sites-available/agenda`:

```conf
# /etc/nginx/sites-available/agenda
server {
    listen 80;
    server_name agenda.example.org;

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
    listen 80;
    server_name api.agenda.example.org;

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy same-origin always;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

| directive | does |
|---|---|
| `server_name` | which `Host` this block answers: the site, or the API |
| `location /static/` with `alias` | the files `collectstatic` gathered, served by nginx without reaching Django |
| `proxy_pass` | everything else, to the application on `127.0.0.1` |
| `proxy_set_header Host $host` | pass the name the client asked for, which `ALLOWED_HOSTS` checks |
| `X-Forwarded-For`, `X-Forwarded-Proto` | the client's address, and whether it used HTTPS; the next section needs both |
| `add_header` | headers on every answer from the API; `always` includes errors |

**The headers are there because FastAPI does not add them**, and Django does: its
`SecurityMiddleware` and `XFrameOptionsMiddleware` already send `X-Content-Type-Options` and
`X-Frame-Options`. Putting them in nginx protects whatever runs behind it.

Enable the site, disable the default, and **test before reloading**, so that a mistake never reaches
the running server:

```
ana@vm:~/agenda$ sudo ln -s /etc/nginx/sites-available/agenda /etc/nginx/sites-enabled/agenda
ana@vm:~/agenda$ sudo rm /etc/nginx/sites-enabled/default
ana@vm:~/agenda$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@vm:~/agenda$ sudo systemctl reload nginx
```

Through nginx, by name:

```
ana@vm:~/agenda$ curl -sI -H "Host: agenda.example.org" http://127.0.0.1/static/events/agenda.css | grep -iE "^(HTTP|server|content-type|content-length)"
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Content-Type: text/css
Content-Length: 206
ana@vm:~/agenda$ curl -sI -H "Host: agenda.example.org" http://127.0.0.1/events/ | grep -iE "^(HTTP|location)"
HTTP/1.1 301 Moved Permanently
Location: https://agenda.example.org/events/
ana@vm:~/agenda$ curl -s -D - -o /dev/null -H "Host: api.agenda.example.org" http://127.0.0.1/events | grep -iE "^(HTTP|server|x-|referrer)"
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: same-origin
```

The stylesheet came from nginx itself, from disk. The site's own page is Django's 301 to HTTPS,
through nginx. And the API answered with the three headers added.
