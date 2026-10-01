---
title: What the proxy refuses before the application sees it
version: 1
---

The cheapest protection a proxy offers is **refusing requests the application never needs**. Each
refusal is a line of configuration and a class of problem that no longer reaches the code behind it.

Before any change, the proxy announces its software and version to anybody who asks:

```
ana@remote:~$ curl -sI https://www.example.com/ | grep -iE "^server|^HTTP"
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
```

A version number tells a stranger which published vulnerabilities to try first. It is not a defence
to hide it, since a patched server is safe whatever it says, but there is no reason to volunteer it.
The site configuration after this section's changes:

```schooling-example
{"language": "conf", "file": "/etc/nginx/sites-enabled/shop", "parts": [{"code": "server_tokens off;", "note": "Say `nginx` in the `Server` header, with no version."}, {"code": "server {\n    listen 192.0.2.80:80;\n    server_name www.example.com;\n    return 301 https://$host$request_uri;\n}", "note": "Plain HTTP only ever answers with a redirect to HTTPS. Lesson 13 says why the redirect alone is not enough."}, {"code": "server {\n    listen 192.0.2.80:443 ssl;\n    server_name www.example.com;\n    ssl_certificate     /etc/ssl/private/www.crt;\n    ssl_certificate_key /etc/ssl/private/www.key;\n    ssl_protocols TLSv1.2 TLSv1.3;", "note": "TLS ends here, and only the two current versions are offered."}, {"code": "    client_max_body_size 16k;", "note": "A request body larger than 16 KiB is refused with `413`. The shop's forms are small; an upload endpoint would get a larger limit of its own."}, {"code": "    location /admin/ {\n        allow 192.168.10.0/24;\n        deny all;\n        proxy_pass http://192.168.20.10:8080;\n    }", "note": "The admin pages exist, and only the staff LAN may reach them through the proxy. Everybody else gets `403`."}, {"code": "    location / {\n        limit_except GET POST { deny all; }\n        proxy_pass http://192.168.20.10:8080;\n        proxy_set_header Host $host;\n        proxy_set_header X-Forwarded-For $remote_addr;\n    }\n}", "note": "Everything else is passed to the application, but only as `GET` or `POST`. `HEAD` is allowed along with `GET`; any other method is refused."}]}
```

Each refusal, tested from the outside and, where it matters, from the inside:

```
ana@remote:~$ curl -sI https://www.example.com/ | grep -iE "^server|^HTTP"
HTTP/1.1 200 OK
Server: nginx
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/admin/
403
ana@laptop:~$ curl -s https://www.example.com/admin/
admin console
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -X DELETE https://www.example.com/orders/17
403
ana@remote:~$ head -c 20000 /dev/zero | curl -s -o /dev/null -w "%{http_code}\n" --data-binary @- https://www.example.com/
413
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/
301
```

The `Server` header now says `nginx` and nothing more. The admin page is `403` from the internet and
works from `laptop`. `DELETE` is refused before it reaches any code that might have handled it
carelessly. Twenty thousand bytes of body were refused at the door with `413`, and plain HTTP
answered with a redirect.

**None of this needed to know what an attack looks like.** Every rule describes what the application
legitimately receives, and refuses the rest, which is the same stance as the firewall's
`policy drop`. The next two sections add controls that do have to recognise misuse, and they are
harder to get right.
