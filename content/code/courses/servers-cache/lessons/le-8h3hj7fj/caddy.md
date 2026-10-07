---
title: Caddy, and a configuration that is mostly defaults
version: 1
---

Caddy is the youngest of the three, written in Go, and it starts from a different premise: **the
right behaviour should need no configuration.** Its best-known default is that a site with a domain
name gets a TLS certificate, fetched and renewed by Caddy itself, without being asked. Lesson 3
shows that working. Here it is turned off by writing `http://` in front of the address, because the
bookshop's names exist only inside this machine and no certificate authority could check them.

The whole site, on port 8081:

```
ana@web:~$ cat /etc/caddy/Caddyfile
http://ipelivros.example:8081, http://www.ipelivros.example:8081 {
	root * /var/www/ipe
	file_server
	log {
		output file /var/log/caddy/ipelivros.access.log
	}
}
ana@web:~$ caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile 2>&1 | tail -1
Valid configuration
```

Compare it with the Nginx server block of two sections ago. `root` and the names are the same
idea; `file_server` is the line that says "serve files from that root", which Nginx assumes and Caddy
wants said; and there is no `index` directive, because serving `index.html` for a directory is the
default. The log is written as one JSON object per line, which makes it easy to query and harder to
read with your eyes; the section on logs shows one.

`caddy validate` reads the file the way the service will, and it is Caddy's `nginx -t`. Then start
it and ask for the stylesheet:

```
ana@web:~$ sudo systemctl start caddy
ana@web:~$ curl -sI http://ipelivros.example:8081/css/site.css
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 237
Content-Type: text/css; charset=utf-8
Etag: "tkos406l"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Server: Caddy
Date: Wed, 07 Oct 2026 03:11:23 GMT
```

Same file, same bytes, same `Last-Modified`; a third format of `ETag`. Notice also what Caddy did
not say: no version in the `Server` header, where Nginx and Apache both name their exact release.
Lesson 4 is about why that matters.

## The Caddyfile and the JSON underneath

A Caddyfile is a convenience. Caddy's real configuration is a JSON document, the Caddyfile is
translated into it on load, and that JSON can be changed on a running Caddy through an API on
`localhost:2019`. That makes Caddy easy to drive from another program, and it is why some teams run
it with no Caddyfile at all. This course uses the Caddyfile and never needs the API.

**Where Caddy is the right choice:** a small number of sites that need HTTPS and very little else,
run by somebody who would rather not maintain certificates. **Where it is less common:** in front of
large, long-lived installations, where Nginx's configuration has been written, reviewed and debugged
by somebody already, and the team knows its every directive.
