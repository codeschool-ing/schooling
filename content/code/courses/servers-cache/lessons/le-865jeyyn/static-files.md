---
title: Serving static files well
version: 1
---

Everything under `/var/www/ipe` is served by Nginx without the application ever hearing of it, and
that is most of what a web page asks for: the stylesheet, the script, the pictures. Three settings
decide how well it is done.

## Compression

Ubuntu's `nginx.conf` turns compression on with `gzip on`, and then leaves the useful part commented
out:

```
ana@web:~$ grep -n gzip /etc/nginx/nginx.conf
46:	gzip on;
48:	# gzip_vary on;
49:	# gzip_proxied any;
50:	# gzip_comp_level 6;
51:	# gzip_buffers 16 8k;
52:	# gzip_http_version 1.1;
53:	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

With `gzip_types` unset, Nginx compresses `text/html` and nothing else. The stylesheet, the script
and the API's JSON go out as they are, even to a client that asked for gzip:

```
ana@web:~$ curl -s -o /dev/null -w '%{size_download} bytes\n' -H 'Accept-Encoding: gzip' http://ipelivros.example/api/books
723 bytes
ana@web:~$ curl -sI -H 'Accept-Encoding: gzip' http://ipelivros.example/js/app.js | grep -iE 'content-(type|encoding|length)'
Content-Type: application/javascript
Content-Length: 462
```

A file in `conf.d` is included inside `http { }`, so three lines there apply to every site:

```
ana@web:~$ cat /etc/nginx/conf.d/gzip.conf
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 256;
gzip_vary on;
ana@web:~$ curl -sI -H 'Accept-Encoding: gzip' http://ipelivros.example/js/app.js | grep -iE 'content-(type|encoding|length)|vary'
Content-Type: application/javascript
Vary: Accept-Encoding
Content-Encoding: gzip
ana@web:~$ curl -s -o /dev/null -w '%{size_download} bytes\n' -H 'Accept-Encoding: gzip' http://ipelivros.example/api/books
303 bytes
ana@web:~$ curl -s -o /dev/null -w '%{size_download} bytes\n' http://ipelivros.example/api/books
723 bytes
```

The catalogue went from 723 bytes to 303 for a client that accepts gzip, and stayed at 723 for one
that does not. **`gzip_types` lists what to compress, and the list is about what compresses**: text,
JSON, JavaScript and SVG shrink to a third or less; JPEG, PNG, WebP and video are compressed already
and only cost CPU to try. `gzip_min_length 256` skips responses so small that the gzip header
outweighs the saving. And `gzip_vary on` adds `Vary: Accept-Encoding`, which tells any cache between
here and the browser that the compressed and uncompressed copies are different responses. Lesson 5
shows what goes wrong without it.

Nginx compresses on every request, which is cheap at this size. For large files that never change,
`gzip_static on` sends a `.gz` written beside the file in advance, compressed once at its highest
level instead of on every request.

## `sendfile` and the kernel

`sendfile on`, already in Ubuntu's `nginx.conf`, lets the kernel copy a file straight from the page
cache to the socket, without the bytes ever passing through Nginx's memory. It is why a web server
outruns a program that reads a file and writes it back out. It does not combine with gzip: a
compressed response has to pass through Nginx to be compressed.

## Refusing what is too large

A web server reads a request body before the application sees it, and so it is the place to refuse
one that is absurd. The default limit is one megabyte:

```
ana@web:~$ head -c 2000000 /dev/zero | curl -s -o /dev/null -w '%{http_code}\n' -X PUT --data-binary @- http://ipelivros.example/api/books/1
413
ana@web:~$ tail -n 1 /var/log/nginx/ipelivros.error.log
2026/10/07 00:26:35 [error] 1433#1433: *325 client intended to send too large body: 2000000 bytes, client: 127.0.0.1, server: ipelivros.example, request: "PUT /api/books/1 HTTP/1.1", host: "ipelivros.example"
```

`413` is answered from the `Content-Length` the client announced, before two megabytes are read.
`client_max_body_size` raises it per site or per location, and an upload form is the one place it
should: `client_max_body_size 20m;` inside `location /upload/` and nowhere else.
