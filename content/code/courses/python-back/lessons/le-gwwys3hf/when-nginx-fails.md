---
title: When nginx fails
version: 1
---

Three failures, each with the message that names it.

## 502 Bad Gateway

Stop the application behind nginx:

```
ana@vm:~/agenda$ sudo systemctl stop agenda
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
502
ana@vm:~/agenda$ sudo tail -1 /var/log/nginx/error.log | cut -c1-160
2026/10/23 00:56:00 [error] 1100#1100: *17 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.1, server: agenda.example.or
ana@vm:~/agenda$ sudo systemctl start agenda
```

**502** is nginx saying that it is fine and what it proxies to is not. The error log says which
upstream and why: `Connection refused` on `127.0.0.1:8000`, nothing listening. **`systemctl status
agenda`** and **`journalctl -u agenda`** are the next places to look. A **504** instead means the
application accepted the connection and did not answer in time.

## A configuration that does not parse

A missing semicolon after `proxy_pass`:

```
ana@vm:~/agenda$ sudo nginx -t
2026/10/23 00:56:00 [emerg] 1195#1195: invalid number of arguments in "proxy_pass" directive in /etc/nginx/sites-enabled/agenda:21
nginx: configuration file /etc/nginx/nginx.conf test failed
```

**`nginx -t` names the file and the line**, and a reload after a failed test would have kept the old
configuration running. That is why every reload in this lesson came after a test.

## A redirect that never ends

Remove `proxy_set_header X-Forwarded-Proto $scheme;` from the site's `location /`, and ask over HTTPS:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
301 https://agenda.example.org/events/
```

**A 301 to the address that was asked for.** Django did not see `https` in the header, concluded the
request was plain HTTP, and redirected it to HTTPS, where the same thing happens again; a browser
gives up with *too many redirects*. With the line back:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
200
```

## Others you will meet

| symptom | cause | fix |
|---|---|---|
| `403 Forbidden` on `/static/`, `Permission denied` in the error log | the static directory is inside a home directory `www-data` cannot enter | collect into `/var/www`, as this lesson did |
| `Address already in use` when nginx starts | another server holds port 80 or 443 | `sudo ss -ltnp` names it |
| `400 Bad Request` from Django | `Host` not in `ALLOWED_HOSTS`, often a missing `proxy_set_header Host` | lesson 15's setting, and the header |

These three were not produced for this course; the messages are nginx's and Django's for those
causes.
