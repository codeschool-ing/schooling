---
title: Files that should not be there, and methods nobody uses
version: 1
---

A web root collects things nobody meant to publish: an editor's backup file, an `.env` with a
password in it, a whole `.git` directory copied along with a deploy. Give this one a `.git`, the way a careless deploy would, with a file inside it that names where the
code comes from:

```sh
sudo mkdir -p /var/www/ipe/.git && printf "[core]\n\trepositoryformatversion = 0\n[remote \"origin\"]\n\turl = git@git.example:ipe/site.git\n" | sudo tee /var/www/ipe/.git/config >/dev/null
```

Nginx serves whatever is in a web root:

```
ana@web:~$ ls -A /var/www/ipe
.git
css
img
index.html
js
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/.git/config
200
```

`200`. A `.git` directory is the full history of the site, every file that was ever committed and
every password that was ever committed by mistake, and there are scanners that look for nothing but
`/.git/config` on every address they can find. **The real fix is a deploy that never copies it**; the
server's job is to make the mistake harmless when it happens anyway. One location refuses every path
with a component that starts with a dot, except the one directory ACME needs:

```
ana@web:~$ sudo sed -i '0,/    location \/ {/s||    location ~ /\\.(?!well-known/) {\n        return 404;\n    }\n\n    location / {|' /etc/nginx/sites-available/ipelivros && grep -n -A2 'location ~' /etc/nginx/sites-available/ipelivros
18:    location ~ /\.(?!well-known/) {
19-        return 404;
20-    }
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/.git/config
404
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/.well-known/acme-challenge/test
404
```

It returns `404` rather than `403`, so the answer for a hidden file that exists is the same as for one
that does not, and a scan learns nothing. The challenge path still reaches its own location.

## Methods

The API understands `GET` and `PUT`. Everything else reaches the application anyway, and whether it
gets refused depends on how carefully the application was written:

```
ana@web:~$ for m in GET PUT DELETE TRACE; do printf '%-6s ' $m; curl -s -o /dev/null -w '%{http_code}\n' -X $m -d '{"price_cents": 4990}' https://ipelivros.example/api/books/1; done
GET    200
PUT    200
DELETE 405
TRACE  405
```

`DELETE` got `405` from the shop, which happens to answer it correctly. `TRACE` got `405` from Nginx,
which never passes it on. **`limit_except` lets Nginx refuse every other method before the application
sees it**, so an endpoint nobody tested for `DELETE` is not the one place a `DELETE` does something:

```
ana@web:~$ sudo sed -i 's|        proxy_pass http://shop;|        limit_except GET HEAD PUT { deny all; }\n        proxy_pass http://shop;|' /etc/nginx/sites-available/ipelivros
ana@web:~$ for m in GET PUT DELETE TRACE; do printf '%-6s ' $m; curl -s -o /dev/null -w '%{http_code}\n' -X $m -d '{"price_cents": 4990}' https://ipelivros.example/api/books/1; done
GET    200
PUT    200
DELETE 403
TRACE  405
```

`DELETE` now gets `403` from Nginx itself. `GET` brings `HEAD` with it automatically, which is why
`HEAD` appears in the list only for readability.
