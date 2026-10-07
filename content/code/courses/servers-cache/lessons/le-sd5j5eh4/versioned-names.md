---
title: Never changing a URL's content
version: 1
---

Purging works on a cache you control. It cannot reach the copy in a visitor's browser, which was told
the stylesheet is good for an hour and will believe it for an hour. **The way around a copy nobody can
purge is to make sure no copy ever becomes wrong: a file's content never changes at a given URL, and a
new version gets a new URL.**

The usual way to name a version is with a few characters of the file's own hash:

```
ana@web:~$ cd /var/www/ipe/css && sha256sum site.css | cut -c1-8
c867bf6d
ana@web:~$ cd /var/www/ipe/css && sudo cp site.css site.$(sha256sum site.css | cut -c1-8).css && ls
site.c867bf6d.css
site.css
ana@web:~$ sudo sed -i 's|/css/site.css|/css/site.c867bf6d.css|' /var/www/ipe/index.html && grep stylesheet /var/www/ipe/index.html
<link rel="stylesheet" href="/css/site.c867bf6d.css">
```

`site.c867bf6d.css` is the stylesheet as it is today. When somebody edits it, its hash changes, the new
file is `site.<another hash>.css`, and the HTML points at the new name. Every browser that loads the new
HTML asks for a file it has never seen, so its old copy of the old name is simply never asked for again.
Nothing had to be purged, and nothing could be stale.

That makes the strongest caching header honest:

```
ana@web:~$ cat /etc/nginx/snippets/versioned-assets.conf
# A file whose name carries eight hex digits of its own hash never changes:
# a new version is a new name. Keep it for a year and never ask again.
location ~* "\.[0-9a-f]{8}\.(css|js)$" {
    add_header Cache-Control "public, max-age=31536000, immutable";
}
ana@web:~$ sudo sed -i '0,/    index index.html;/s//    index index.html;\n    include snippets\/versioned-assets.conf;/' /etc/nginx/sites-available/ipelivros && grep -n 'versioned' /etc/nginx/sites-available/ipelivros
16:    include snippets/versioned-assets.conf;
ana@web:~$ curl -sI https://ipelivros.example/css/site.c867bf6d.css | grep -iE '^(HTTP|cache-control)'
HTTP/1.1 200 OK
Cache-Control: public, max-age=31536000, immutable
```

A year, and `immutable`, which tells the browser not even to revalidate when the person presses reload.
The regular expression is in double quotes because Nginx reads `{` as the start of a block; without the
quotes `nginx -t` refuses the file. One thing still has to be short-lived for all this to work: **the
HTML that names the files.** It is the one place the new name appears, so it carries a short lifetime or
`no-cache`, and every asset it points at can be cached forever.

Doing this by hand for every file is error-prone, and in practice the build step of a front-end project
does it: every bundler (Vite, webpack, esbuild) writes hashed file names and rewrites the HTML to match.
The server's only job is the header.
