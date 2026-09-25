---
title: Status codes that point somewhere
version: 1
---

`curl -L` follows redirects, and `-I` asks only for headers:

```
ana@laptop:~$ curl -sIL http://example.com/ | grep -iE "^HTTP|^location"
HTTP/1.1 301 Moved Permanently
Location: https://example.com/
HTTP/2 200 
```

Two answers for one command: the `301` from plain HTTP, and the `200` from HTTPS, now over **HTTP/2**.
A browser does the same thing without showing it. Then four paths on the same site, and the status of
each:

```
ana@laptop:~$ for p in / /private/ /nothing /app/; do curl -so /dev/null -w "%{http_code} $p\n" https://www.example.com$p; done
200 /
403 /private/
404 /nothing
502 /app/
ana@www:~$ tail -2 /var/log/nginx/error.log
2026/09/25 13:57:45 [error] 76721#76721: *6 directory index of "/var/www/example/private/" is forbidden, client: 203.0.113.2, server: example.com, request: "GET /private/ HTTP/2.0", host: "www.example.com"
2026/09/25 13:57:45 [error] 76721#76721: *8 connect() failed (111: Connection refused) while connecting to upstream, client: 203.0.113.2, server: example.com, request: "GET /app/ HTTP/2.0", upstream: "http://127.0.0.1:9000/app/", host: "www.example.com"
```

**Every one of these is a successful network conversation.** DNS worked, TCP connected, TLS agreed,
the request arrived and the server answered. The code says what the server decided, and each one
sends the support question to a different place:

| code | means | ask |
|---|---|---|
| `2xx` | it worked | nobody |
| `3xx` | it is somewhere else, see `Location:` | nobody; follow it |
| `403` | the server will not show this | whoever runs the site: permissions |
| `404` | there is nothing at that path | whoever made the link |
| `500` | the application crashed | the application's developers |
| `502`, `504` | the web server could not reach the application behind it | whoever runs that application |

**The error log says which.** The last two lines of nginx's log on `www` name both failures: the
`403` is `directory index … is forbidden`, a folder with no page in it; the **`502` is `connect()
failed (111: Connection refused) while connecting to upstream`, `127.0.0.1:9000`**. nginx is
healthy and passed the request on to the booking application, which was not running. That is lesson
3's `Connection refused`, one level further in. Restarting nginx would change nothing.
