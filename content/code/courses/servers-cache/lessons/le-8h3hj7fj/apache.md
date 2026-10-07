---
title: Apache, and two servers on one port
version: 1
---

Apache is the oldest of the three and still runs a large share of the web, much of it on shared
hosting where each customer controls their own directory. Start it while Nginx is running:

```
ana@web:~$ sudo systemctl start apache2
Job for apache2.service failed because the control process exited with error code.
See "systemctl status apache2.service" and "journalctl -xeu apache2.service" for details.
ana@web:~$ sudo journalctl -u apache2 --no-pager -o cat | grep -E "AH0|Address"
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
(98)Address already in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
AH00015: Unable to open logs
```

**`Address already in use` on port 80 is the error you will meet most often in this whole subject**,
and it means exactly what it says: a port belongs to one program at a time, and Nginx has it. The
`AH00558` line above it is only a warning about the machine's name, and it shows up on every start;
the line that matters is `AH00072`. Two web servers on one machine either use different ports, or one
of them stands in front of the other, which is lesson 2.

For this lesson Apache gets port 8080. Its configuration is split the Debian way, like Nginx's:
`ports.conf` says which ports to open, and each site is a **virtual host** in `sites-available`,
switched on with `a2ensite`, which creates the same kind of link Nginx's convention uses.

```
ana@web:~$ sudo sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf
ana@web:~$ cat /etc/apache2/sites-available/ipelivros.conf
<VirtualHost *:8080>
    ServerName ipelivros.example
    ServerAlias www.ipelivros.example
    DocumentRoot /var/www/ipe

    ErrorLog ${APACHE_LOG_DIR}/ipelivros-error.log
    CustomLog ${APACHE_LOG_DIR}/ipelivros-access.log combined
</VirtualHost>
ana@web:~$ sudo a2dissite 000-default && sudo a2ensite ipelivros
Site 000-default disabled.
To activate the new configuration, you need to run:
  systemctl reload apache2
Enabling site ipelivros.
To activate the new configuration, you need to run:
  systemctl reload apache2
ana@web:~$ sudo apachectl configtest
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
Syntax OK
ana@web:~$ sudo systemctl start apache2
ana@web:~$ curl -sI http://ipelivros.example:8080/css/site.css
HTTP/1.1 200 OK
Date: Wed, 07 Oct 2026 03:11:23 GMT
Server: Apache/2.4.58 (Ubuntu)
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
ETag: "ed-65a6b7f0fb400"
Accept-Ranges: bytes
Content-Length: 237
Vary: Accept-Encoding
Content-Type: text/css
```

The pieces map onto Nginx's almost one to one: `ServerName` and `ServerAlias` are `server_name`,
`DocumentRoot` is `root`, and `apachectl configtest` is `nginx -t`. The response differs in two
small ways worth noticing now. Apache's `ETag` is built from the file's size and modification time
in its own format, so the same file has a different tag on each server, which matters the day two
different servers answer for one name. And Apache adds `Vary: Accept-Encoding` because it is ready to
compress, which lesson 5 explains.

## Modules and processes

Apache does almost nothing on its own; nearly every feature is a **module** loaded at start-up, and
`a2enmod` and `a2dismod` switch them the way `a2ensite` switches sites. The first dozen enabled on
this machine:

```
ana@web:~$ ls /etc/apache2/mods-enabled/ | head -12
access_compat.load
alias.conf
alias.load
auth_basic.load
authn_core.load
authn_file.load
authz_core.load
authz_host.load
authz_user.load
autoindex.conf
autoindex.load
deflate.conf
```

How Apache handles connections is a module too, the **multi-processing module** or MPM, and only
one can be loaded:

```
ana@web:~$ a2query -M
event
```

`event` is Ubuntu's default: a few processes, each with many threads, and a separate thread that
watches idle keep-alive connections so they do not occupy a worker. The older `prefork` runs one
single-threaded process per connection. It is still what you get with `mod_php`, the PHP module that
does not tolerate threads, and it is why an old Apache server could run out of memory under a few
hundred visitors.

## The thing only Apache does

**`.htaccess`** files let a directory carry its own configuration, read by Apache on every request
that touches it. On shared hosting, where the customer cannot edit the server's files, that is the
whole point. On a server you control it is a cost: every request checks every directory on its path
for one. Ubuntu's Apache allows them nowhere by default (`AllowOverride None`), and a server of your
own should leave it so.
