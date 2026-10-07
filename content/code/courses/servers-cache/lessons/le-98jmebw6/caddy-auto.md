---
title: Caddy does all of this by itself
version: 1
---

Everything this lesson did by hand, certbot, the webroot, the hook, the timer, the redirect, is what
Caddy does by default for any site whose address is a domain name. Lesson 1 switched it off with
`http://`. Here it is switched on, pointed at Pebble with two global options that a real server would
leave out:

```
ana@web:~$ cat /etc/caddy/Caddyfile
{
	acme_ca https://localhost:14000/dir
	acme_ca_root /etc/pebble/api.crt
	email ana@ipelivros.example
}

ipelivros.example, www.ipelivros.example {
	root * /var/www/ipe
	file_server
	reverse_proxy /api/* 127.0.0.1:8001 127.0.0.1:8002
}
```

The site block has no certificate, no port and no redirect in it. `reverse_proxy` with two addresses
is the whole of lesson 2's upstream. Stop Nginx, which holds ports 80 and 443, and start Caddy:

```
ana@web:~$ sudo systemctl stop nginx && sudo systemctl start caddy && sleep 6 && systemctl is-active caddy
active
ana@web:~$ sudo journalctl -u caddy --no-pager -o cat | grep -o '"msg":"[^"]*"' | grep -iE 'certif|challenge|obtain|authoriz' | uniq
"msg":"enabling automatic TLS certificate management"
"msg":"started background certificate maintenance"
"msg":"obtaining certificate"
"msg":"trying to solve challenge"
"msg":"successfully downloaded available certificate chains"
"msg":"certificate obtained successfully"
"msg":"successfully downloaded available certificate chains"
"msg":"certificate obtained successfully"
```

Within the six seconds of that `sleep`, Caddy registered an account, solved a challenge for each of
the two names and installed both certificates, and it serves them:

```
ana@web:~$ curl -sS https://ipelivros.example/api/books/3 -o /dev/null -w '%{http_code}\n'
200
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | openssl x509 -noout -issuer -dates
issuer=CN = Pebble Intermediate CA 6e3a58
notBefore=Oct  7 03:40:01 2026 GMT
notAfter=Jan  5 03:40:00 2027 GMT
ana@web:~$ curl -sI http://ipelivros.example/css/site.css | grep -E 'HTTP|Location'
HTTP/1.1 308 Permanent Redirect
Location: https://ipelivros.example/css/site.css
```

`308 Permanent Redirect` is Caddy's way of sending HTTP to HTTPS, the same idea as Nginx's `301`
with one difference: a `308` tells the client to repeat the request with the same method and body,
where browsers turn a `POST` that meets a `301` into a `GET`.

Caddy renews by itself as well, with nothing to install. **That is the trade:** the defaults are
right and there is less to forget, and in exchange the certificates live in Caddy's own data
directory, managed in Caddy's own way. A team that runs Nginx for everything else keeps certbot;
a team starting a small service from nothing has one fewer thing to get wrong with Caddy.

The lesson ends with Nginx back in charge, because the rest of the course builds on it:

```
ana@web:~$ sudo systemctl stop caddy && sudo systemctl start nginx && systemctl is-active nginx
active
```
