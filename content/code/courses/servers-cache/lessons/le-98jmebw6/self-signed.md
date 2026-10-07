---
title: A certificate that signs itself
version: 1
---

Anybody can make a certificate. `openssl` does it in one command, with a P-256 key, valid for thirty
days, for the bookshop's two names:

```
ana@web:~$ sudo mkdir -p /etc/ssl/ipelivros && cd /etc/ssl/ipelivros && sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj "/CN=ipelivros.example" -addext "subjectAltName=DNS:ipelivros.example,DNS:www.ipelivros.example" -keyout self.key -out self.crt 2>&1; ls -l
-----
total 8
-rw-r--r-- 1 root root 672 Oct  7 00:39 self.crt
-rw------- 1 root root 241 Oct  7 00:39 self.key
ana@web:~$ openssl x509 -in /etc/ssl/ipelivros/self.crt -noout -subject -issuer -dates
subject=CN = ipelivros.example
issuer=CN = ipelivros.example
notBefore=Oct  7 03:39:45 2026 GMT
notAfter=Nov  6 03:39:45 2026 GMT
```

**The subject and the issuer are the same name.** Nobody vouched for this certificate except the
certificate itself, which is what *self-signed* means. Two lines in a snippet tell Nginx where the
certificate and its private key are, and the site's server block gets a second `listen`:

```conf
ssl_certificate     /etc/ssl/ipelivros/self.crt;
ssl_certificate_key /etc/ssl/ipelivros/self.key;
```

```
ana@web:~$ sed -n '/^server {/,/root/p' /etc/nginx/sites-available/ipelivros
server {
    listen 80;
    listen 443 ssl;
    include snippets/ipelivros-self.conf;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
```

The key file was written with permissions `-rw-------`, readable by root alone, and that is right:
Nginx's master reads it as root before the workers drop to `www-data`, and **the private key is the
one file on this server whose theft lets somebody else be you**. Now ask for the page over HTTPS:

```
ana@web:~$ curl -sS https://ipelivros.example/ -o /dev/null
curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@web:~$ curl -sSk https://ipelivros.example/ -o /dev/null -w '%{http_code}\n'
200
ana@web:~$ curl -sS --cacert /etc/ssl/ipelivros/self.crt https://ipelivros.example/ -o /dev/null -w '%{http_code}\n'
200
```

`curl` refused, and said why: nothing it trusts signed this certificate. The other two attempts
both "work", and they are worth telling apart. **`-k` switches the check off**: the connection is
encrypted, to whoever answered, which proves nothing. `--cacert` tells `curl` to trust this one
certificate as if it were a root, which is honest for a certificate you made yourself and copied to
the client yourself, and impossible for strangers on the internet, who have no way to get a copy
they can believe.

A self-signed certificate is the right tool for exactly that case: a service whose clients you also
control, such as two of your own machines talking over a private network. For a website it is the
wrong tool, because every visitor sees a browser warning, and teaching visitors to click past
warnings is how they end up clicking past the one that matters. The `-k` habit is the same mistake
in a terminal, and it ends up in scripts that then run in production.
