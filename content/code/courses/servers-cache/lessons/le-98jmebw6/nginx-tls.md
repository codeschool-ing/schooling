---
title: Nginx with a trusted certificate
version: 1
---

The snippet changes from the self-signed files to certbot's, and gains three lines:

```
ana@web:~$ cat /etc/nginx/snippets/ipelivros-tls.conf
ssl_certificate     /etc/letsencrypt/live/ipelivros.example/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ipelivros.example/privkey.pem;
ssl_protocols       TLSv1.2 TLSv1.3;
ssl_session_cache   shared:TLS:10m;
ssl_session_timeout 1d;
```

Save it as `/etc/nginx/snippets/ipelivros-tls.conf`, and point the site at it instead of the
self-signed one:

```sh
sudo sed -i 's/ipelivros-self.conf/ipelivros-tls.conf/' /etc/nginx/sites-available/ipelivros
sudo nginx -t && sudo systemctl reload nginx
```

`ssl_protocols TLSv1.2 TLSv1.3` drops the versions before 1.2, which every current browser has stopped
using and every audit flags. The session cache lets a returning client resume its previous TLS session
instead of doing the whole handshake again, for a day; `shared` means every worker uses the same cache,
the same reason the upstream needed a `zone` in lesson 2.

This machine still does not trust Pebble's root. Copying it into `/usr/local/share/ca-certificates`
in the previous section was half the job, and `update-ca-certificates` is the other half: it adds the
file to the list every program on the machine reads.

```
ana@web:~$ sudo update-ca-certificates 2>&1
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
ana@web:~$ curl -sS https://ipelivros.example/api/books/3 -o /dev/null -w '%{http_code} %{ssl_verify_result}\n'
200 0
```

`200`, and `ssl_verify_result` `0`, which means the chain was checked and accepted, **with no `-k`
and no `--cacert`**. That is the state a Let's Encrypt certificate is in from the first second,
because its root is already in that list.

## Looking at the handshake

`curl -v` describes the connection it made:

```
ana@web:~$ curl -sv https://ipelivros.example/ -o /dev/null 2>&1 | grep -E '^\*  ?(SSL connection|Server certificate|subject|issuer|expire|subjectAltName|SSL certificate verify)'
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
* Server certificate:
*  subject: CN=ipelivros.example
*  expire date: Jan  5 03:39:48 2027 GMT
*  subjectAltName: host "ipelivros.example" matched cert's "ipelivros.example"
*  issuer: CN=Pebble Intermediate CA 6e3a58
*  SSL certificate verify ok.
```

TLS 1.3, an AES-256-GCM cipher, an X25519 key exchange, and the certificate checked. `openssl
s_client` shows the chain the server actually sent, which is the check that catches the `cert.pem`
mistake of the previous section:

```
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | grep -E "^ ?[0-9] s:|^   i:|Verify return|Protocol|Cipher is"
 0 s:CN = ipelivros.example
   i:CN = Pebble Intermediate CA 6e3a58
 1 s:CN = Pebble Intermediate CA 6e3a58
   i:CN = Pebble Root CA 435937
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

Two certificates were sent: `0` is the site, issued by the intermediate, and `1` is the intermediate,
issued by the root. The root itself was not sent and did not need to be.

**And an old protocol is refused.** OpenSSL's own client will not even offer TLS 1.1 by default any
more; told to, with its security level lowered, it gets an answer from Nginx:

```
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example -tls1_1 -cipher 'DEFAULT@SECLEVEL=0' 2>&1 | grep -E 'alert|Protocol  *:'
405799AE627F0000:error:0A00042E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:../ssl/record/rec_layer_s3.c:1590:SSL alert number 70
    Protocol  : TLSv1.1
```

`protocol version` is the server saying it does not speak what was offered. That is the line a
compliance scanner looks for.

## Sending HTTP to HTTPS

Port 80 now has one job: tell every client to come back over HTTPS. The site's own server block
listens only on 443, and a small second block takes port 80:

```
ana@web:~$ cat /etc/nginx/sites-available/ipelivros.redirect
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    location /.well-known/acme-challenge/ {
        root /var/www/ipe;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
```

Save that block as `/etc/nginx/sites-available/ipelivros.redirect`. Then delete the `listen 80;` line
from the site's own block, append the new block to the site's file, and remove the copy:

```sh
sudo sed -i '/^    listen 80;/d' /etc/nginx/sites-available/ipelivros
sudo sh -c 'cat /etc/nginx/sites-available/ipelivros.redirect >> /etc/nginx/sites-available/ipelivros'
sudo rm /etc/nginx/sites-available/ipelivros.redirect
sudo nginx -t && sudo systemctl reload nginx
```

```
ana@web:~$ grep -nE 'server \{|listen|include snippets' /etc/nginx/sites-available/ipelivros
9:server {
10:    listen 443 ssl;
11:    include snippets/ipelivros-tls.conf;
35:server {
36:    listen 80;
```

```
ana@web:~$ curl -sI http://ipelivros.example/css/site.css?v=1 | grep -E "HTTP|Location"
HTTP/1.1 301 Moved Permanently
Location: https://ipelivros.example/css/site.css?v=1
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/.well-known/acme-challenge/nothing
404
```

`301` with `Location: https://...` keeps the path and the query, so a bookmark to any page still
works. **The `acme-challenge` location is the one exception, and it matters**: the next renewal checks
the challenge over plain HTTP on port 80, and a redirect that swallowed it would make the renewal fail
ninety days from now, on a day nobody is watching. A `404` for a token that does not exist is the
right answer, and it shows the location is reached rather than redirected.
