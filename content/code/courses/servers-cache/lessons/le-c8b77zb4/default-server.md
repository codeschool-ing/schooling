---
title: Refusing names you do not serve
version: 1
---

Lesson 1 showed that a request whose `Host` matches no `server_name` goes to the **default server**.
On this machine, that is still Ubuntu's packaged site on port 80, and on port 443 it is the bookshop,
because it is the only site listening there:

```
ana@web:~$ ls /etc/nginx/sites-enabled/
default
ipelivros
ana@web:~$ curl -s http://127.0.0.1/ | grep -o '<title>.*</title>'
<title>Apache2 Ubuntu Default Page: It works</title>
ana@web:~$ curl -sk https://127.0.0.1/ | grep -o '<title>.*</title>'
<title>Ipê Livros</title>
ana@web:~$ curl -sk -o /dev/null -w '%{http_code}\n' -H 'Host: anything.example' https://127.0.0.1/
200
```

Three answers that should not have been given. Port 80 served a placeholder page that Apache's
package left in `/var/www/html`, which tells a stranger which packages are installed. Port 443 served
**the bookshop to a request that asked for it by IP address**, and served it again to a request for a
name that has nothing to do with it. Scanners sweep the internet by address, so whatever answers there
is what they index; and a site that answers to any `Host` can be put behind somebody else's domain
name, which is a trick for borrowing a site's reputation.

A catch-all block that refuses everything not named elsewhere:

```
ana@web:~$ cat /etc/nginx/sites-available/catch-all
# Requests for a name this server does not serve: refuse them.
server {
    listen 80 default_server;
    listen 443 ssl default_server;
    server_name _;

    ssl_reject_handshake on;   # no certificate is shown to a stranger
    return 444;                # close the connection without an answer
}
ana@web:~$ sudo rm /etc/nginx/sites-enabled/default && sudo ln -s ../sites-available/catch-all /etc/nginx/sites-enabled/catch-all
```

`return 444` is Nginx's own non-standard code: it closes the connection without sending anything at
all. `ssl_reject_handshake on` does the same one step earlier, during the TLS handshake, so the
server does not even show its certificate, whose names would otherwise tell the stranger which
sites live here. The block needs no certificate of its own for that reason.

```
ana@web:~$ curl -sS http://127.0.0.1/
curl: (52) Empty reply from server
ana@web:~$ curl -sSk https://127.0.0.1/
curl: (35) OpenSSL/3.0.13: error:0A000458:SSL routines::tlsv1 unrecognized name
ana@web:~$ curl -sS -o /dev/null -w '%{http_code}\n' https://ipelivros.example/
200
```

`Empty reply from server` on port 80, an `unrecognized name` alert on 443, and the bookshop, asked for
by its name, unchanged. **Every server with more than one site should have this block**, and a server
with one site should have it too, for the requests that do not ask for that one site by name.
