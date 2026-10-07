---
title: Nginx, and a site of your own
version: 1
---

Nginx is installed and stopped. Starting it, and asking systemd to start it on every boot, is one
command, and `status` then shows what started:

```
ana@web:~$ sudo systemctl enable --now nginx
Synchronizing state of nginx.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
ana@web:~$ systemctl status nginx --no-pager --lines 0
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-10-07 00:11:20 -03; 36ms ago
       Docs: man:nginx(8)
    Process: 224 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 225 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 227 (nginx)
        CPU: 16ms
     CGroup: /system.slice/nginx.service
             ├─227 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─228 "nginx: worker process"
             ├─229 "nginx: worker process"
             ├─230 "nginx: worker process"
             └─231 "nginx: worker process"
```

**There are five processes, and they are not five copies of the same thing.** The first is the
**master**: it runs as root, reads the configuration and opens the port, and it never answers a
request. The other four are **workers**, one per processor because the configuration says
`worker_processes auto`, and they do all the serving. Every one of them holds the listening socket,
which is why `ss` names five owners for port 80:

```
ana@web:~$ sudo ss -ltnp 'sport = :80'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=231,fd=5),("nginx",pid=230,fd=5),("nginx",pid=229,fd=5),("nginx",pid=228,fd=5),("nginx",pid=227,fd=5))
ana@web:~$ curl -sI http://localhost/
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:11:20 GMT
Content-Type: text/html
Content-Length: 10671
Last-Modified: Wed, 07 Oct 2026 03:10:42 GMT
Connection: keep-alive
ETag: "6ac5b832-29af"
Accept-Ranges: bytes
```

That page is Ubuntu's placeholder, served by the default site from `/var/www/html`.

## Where the configuration lives

Everything Nginx does is decided by `/etc/nginx/nginx.conf` and the files it includes. With the
comments stripped, the main file is short:

```
ana@web:~$ grep -Ev '^\s*(#|$)' /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;
events {
	worker_connections 768;
}
http {
	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;
	access_log /var/log/nginx/access.log;
	gzip on;
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
```

Three things in it decide most of what follows. The configuration is **nested blocks**: directives
in `http { }` apply to every site, and a site is a `server { }` block inside it. The last line
includes every file in `sites-enabled`. And `user www-data` is the account the workers run as,
which is why a file the workers must read has to be readable by `www-data`.

`sites-available` holds a site's file and `sites-enabled` holds a symbolic link to it. **Enabling a
site is creating the link, and disabling it is deleting the link**, so the file itself is never lost
when a site is switched off. That convention is Debian's and Ubuntu's; Nginx itself only knows the
`include` line, and other distributions put every site in `conf.d/` instead.

## A server block for the bookshop

The shop's static front is in `/var/www/ipe`. This is the whole site:

```
ana@web:~$ cat /etc/nginx/sites-available/ipelivros
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
```

`listen` is the port. `server_name` is the list of names this block answers for, which the next
paragraph tests. `root` is the directory a request's path is appended to, so `/css/site.css` becomes
`/var/www/ipe/css/site.css`. `index` is the file sent when the path names a directory. And each
site gets logs of its own, which pays off the first time two sites share a server.

Enable it, test the configuration, and reload:

```
ana@web:~$ sudo ln -s ../sites-available/ipelivros /etc/nginx/sites-enabled/ipelivros
ana@web:~$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@web:~$ sudo systemctl reload nginx
ana@web:~$ curl -s http://ipelivros.example/ | head -4
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
```

**`nginx -t` before every reload** is the habit this lesson most wants you to keep, and its last
section shows what it saves you from. A file comes back with its size, its type and two validators,
`Last-Modified` and `ETag`, which lesson 5 is about:

```
ana@web:~$ curl -sI http://ipelivros.example/css/site.css
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:11:22 GMT
Content-Type: text/css
Content-Length: 237
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Connection: keep-alive
ETag: "6a96cc50-ed"
Accept-Ranges: bytes
```

## How Nginx picks a site

The same machine, the same port, the same file, and three answers:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost/css/site.css
404
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: www.ipelivros.example' http://localhost/css/site.css
200
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/nothing-here
404
```

**The site is chosen by the `Host` header, not by the address.** `localhost` matches none of the
bookshop's `server_name`s, so the request goes to the **default server**, the packaged site whose
root is `/var/www/html`, and that directory has no `css/site.css`. Sending `Host:
www.ipelivros.example` to the same address picks the bookshop. This is how one machine with one
address serves hundreds of sites, and it is also why a request to a server's bare IP address lands
on whatever site is the default. Lesson 4 makes that default refuse rather than answer.

The last `404` is the plain one: the right site, and no such file under its root.
