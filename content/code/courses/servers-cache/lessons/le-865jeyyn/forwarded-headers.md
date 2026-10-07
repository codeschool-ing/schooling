---
title: Telling the application who asked
version: 1
---

Nginx knows everything the application lost: the client's address, the name it asked for and
whether it arrived over HTTP or HTTPS. `proxy_set_header` passes them on, as request headers the
application can read:

```
ana@web:~$ grep -A6 'location /api/' /etc/nginx/sites-available/ipelivros
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
ana@web:~$ curl -s http://ipelivros.example/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "ipelivros.example", "x_real_ip": "127.0.0.1", "x_forwarded_for": "127.0.0.1", "x_forwarded_proto": "http"}
```

| header | what it carries | set from |
|---|---|---|
| `Host` | the name the client asked for | `$host` |
| `X-Real-IP` | the client's address, one value | `$remote_addr` |
| `X-Forwarded-For` | every address the request passed through, client first | `$proxy_add_x_forwarded_for` |
| `X-Forwarded-Proto` | `http` or `https`, as the client saw it | `$scheme` |

None of these is a standard in the strict sense. `X-Forwarded-For` and its siblings are a convention
every proxy and framework follows, and RFC 7239 defines one `Forwarded` header meant to replace
them, which few applications read. Ubuntu ships the four lines above as `/etc/nginx/proxy_params`,
so `include proxy_params;` writes them in one line:

```
ana@web:~$ cat /etc/nginx/proxy_params
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

The one difference is `$http_host` against `$host`: the first is the `Host` header exactly as the
client sent it, port included, and the second is the name without the port, or the server's own name
if the client sent none.

## A header anybody can write

`X-Forwarded-For` is a list, and `$proxy_add_x_forwarded_for` **appends** to whatever the client
already sent. So a client can start the list with anything it likes:

```
ana@web:~$ curl -s -H 'X-Forwarded-For: 198.51.100.7' http://ipelivros.example/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "ipelivros.example", "x_real_ip": "127.0.0.1", "x_forwarded_for": "198.51.100.7, 127.0.0.1", "x_forwarded_proto": "http"}
```

`198.51.100.7` is not an address that took part in this request. The client wrote it, and Nginx
faithfully kept it at the front of the list. An application that reads the **first** entry and calls
it "the client's IP" has just let the client choose its own address, which is how a rate limit or an
allow-list gets walked around.

**The rule: trust the entries added by proxies you run, and nothing to the left of them.** With one
Nginx in front, that is the last entry, which is also what `X-Real-IP` carries. With a load balancer
in front of Nginx, it is the second from the end, and both Nginx (the `realip` module) and every web
framework have a setting that says how many proxies to trust for exactly this reason.
