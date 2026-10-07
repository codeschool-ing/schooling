---
title: Which location answers
version: 1
---

A real site has more than two kinds of path, and Nginx has to pick one `location` for each request.
The rules for picking are short and are not the ones most people guess. To watch them work, every
`location` in this version of the site adds a header naming itself:

```conf
    location / {
        try_files $uri $uri/ =404;
        add_header X-Location "prefix /";
    }

    location /api/ {
        proxy_pass http://shop;
        # ...the proxy settings of the previous sections...
        add_header X-Location "prefix /api/";
    }

    location = /healthz {
        proxy_pass http://shop;
        add_header X-Location "exact /healthz";
    }

    location ~* \.(css|js|svg)$ {
        add_header X-Location "regex static";
    }

    location /covers/ {
        alias /var/www/ipe/img/;
        add_header X-Location "prefix /covers/";
    }
```

Eight paths, and which `location` answered each:

```
ana@web:~$ for p in / /index.html /healthz /api/books/2 /css/site.css /covers/logo.svg /api/app.js /nope; do printf '%-18s ' $p; curl -s -o /dev/null -D - http://ipelivros.example$p | grep -iE '^(HTTP|X-Location)' | tr -d '\r' | tr '\n' ' '; echo; done
/                  HTTP/1.1 200 OK X-Location: prefix / 
/index.html        HTTP/1.1 200 OK X-Location: prefix / 
/healthz           HTTP/1.1 200 OK X-Location: exact /healthz 
/api/books/2       HTTP/1.1 200 OK X-Location: prefix /api/ 
/css/site.css      HTTP/1.1 200 OK X-Location: regex static 
/covers/logo.svg   HTTP/1.1 404 Not Found 
/api/app.js        HTTP/1.1 404 Not Found 
/nope              HTTP/1.1 404 Not Found 
```

The first five are what anybody would expect. `/healthz` matched the **exact** location, written with
`=`, which wins over everything. `/api/books/2` matched the longest prefix. `/css/site.css` matched the
regular expression, `~*` meaning case-insensitive.

The next two are the lesson. **`/covers/logo.svg` should have been served by `/covers/`, and was
not.** Nginx's order is:

1. an exact match with `=` wins at once;
2. otherwise, the **longest matching prefix** is found and remembered;
3. if that prefix is marked `^~`, it wins, and no regular expression is tried;
4. otherwise, the regular expressions are tried **in the order they appear in the file**, and the
   first that matches wins;
5. only if none matches does the remembered prefix answer.

So `/covers/logo.svg` was longest-matched by `/covers/`, and then the static regex, which also
matches anything ending in `.svg`, took it. That location has no `alias`, so Nginx looked for
`/var/www/ipe/covers/logo.svg`, which does not exist. The same thing happened to `/api/app.js`: a
request meant for the application ended at a file lookup. A `404` carries no `X-Location`, because
`add_header` only adds to successful responses unless it is written with `always`.

**`^~` is the fix: it says "if this prefix is the longest, stop looking".**

```
ana@web:~$ sudo sed -i 's|    location /covers/ {|    location ^~ /covers/ {|' /etc/nginx/sites-available/ipelivros && grep -n 'covers' /etc/nginx/sites-available/ipelivros
40:    location ^~ /covers/ {
42:        add_header X-Location "prefix /covers/";
ana@web:~$ curl -s -o /dev/null -D - http://ipelivros.example/covers/logo.svg | grep -iE '^(HTTP|X-Location)'
HTTP/1.1 200 OK
X-Location: prefix /covers/
```

## `root`, `alias` and `try_files`

`root` **appends** the whole request path to a directory. `alias` **replaces** the part that matched
the location. With `location /covers/` and `alias /var/www/ipe/img/`, `/covers/logo.svg` becomes
`/var/www/ipe/img/logo.svg`; with `root /var/www/ipe/img/` it would have become
`/var/www/ipe/img/covers/logo.svg`. Keep the trailing slash on both the location and the alias, or
the two concatenate into a path that does not exist.

`try_files $uri $uri/ =404` checks each candidate in turn and serves the first that exists, and the
last one is what happens otherwise. A single-page application uses the same line with
`/index.html` at the end instead of `=404`, so every unknown path loads the application, which then
draws its own page. The bookshop's front is plain HTML, so an unknown path is an honest `404`.
