---
title: Asking for a certificate with certbot
version: 1
---

`certbot` is the ACME client the Electronic Frontier Foundation maintains, and the one most guides
assume. It can fetch a certificate in several ways; the one used here is **webroot**: certbot writes
the challenge token as a file under the site's own root, and the web server that is already running
serves it. Nginx is not touched and never stops.

```
ana@web:~$ sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot certonly --webroot -w /var/www/ipe -d ipelivros.example -d www.ipelivros.example --server https://localhost:14000/dir --agree-tos -m ana@ipelivros.example --no-eff-email --non-interactive 2>&1
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Requesting a certificate for ipelivros.example and www.ipelivros.example

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/ipelivros.example/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/ipelivros.example/privkey.pem
This certificate expires on 2027-01-05.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

`REQUESTS_CA_BUNDLE` is the one thing this lab needs that a real server does not: it tells certbot,
a Python program, to trust Pebble's API certificate. `--server` points it at Pebble instead of Let's
Encrypt. Against Let's Encrypt, with a real domain, the command is the same with those two removed.

## What the CA did

While certbot waited, Pebble checked both names, and Nginx's access log recorded it doing so:

```
ana@web:~$ grep acme-challenge /var/log/nginx/ipelivros.access.log
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/HETdSjY3HaNEI5kRnDkQp2JOXgr4vrxIX35BUWQEEXU HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/HETdSjY3HaNEI5kRnDkQp2JOXgr4vrxIX35BUWQEEXU HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/HETdSjY3HaNEI5kRnDkQp2JOXgr4vrxIX35BUWQEEXU HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/q_mhsdMTwCZy3OLUP_CAimDpKVDDGv8_MlYBVJ_N2Yc HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/q_mhsdMTwCZy3OLUP_CAimDpKVDDGv8_MlYBVJ_N2Yc HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/q_mhsdMTwCZy3OLUP_CAimDpKVDDGv8_MlYBVJ_N2Yc HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
```

One token per name, each fetched over plain HTTP on port 80 by a client calling itself
`LetsEncrypt-Pebble-VA`, the *validation authority*. It fetched each token three times, which mirrors
what Let's Encrypt does in production: it checks from several places on the internet at once, so that
somebody who can intercept traffic near one of them cannot obtain a certificate for your name. The
`200` and the 87 bytes are the token file certbot had written and then deleted again.

## What certbot left behind

```
ana@web:~$ sudo ls -l /etc/letsencrypt/live/ipelivros.example/
total 4
-rw-r--r-- 1 root root 692 Oct  7 00:39 README
lrwxrwxrwx 1 root root  41 Oct  7 00:39 cert.pem -> ../../archive/ipelivros.example/cert1.pem
lrwxrwxrwx 1 root root  42 Oct  7 00:39 chain.pem -> ../../archive/ipelivros.example/chain1.pem
lrwxrwxrwx 1 root root  46 Oct  7 00:39 fullchain.pem -> ../../archive/ipelivros.example/fullchain1.pem
lrwxrwxrwx 1 root root  44 Oct  7 00:39 privkey.pem -> ../../archive/ipelivros.example/privkey1.pem
ana@web:~$ sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -subject -issuer -dates -ext subjectAltName
subject=CN = ipelivros.example
issuer=CN = Pebble Intermediate CA 6e3a58
notBefore=Oct  7 03:39:49 2026 GMT
notAfter=Jan  5 03:39:48 2027 GMT
X509v3 Subject Alternative Name: 
    DNS:ipelivros.example, DNS:www.ipelivros.example
ana@web:~$ sudo grep -c BEGIN /etc/letsencrypt/live/ipelivros.example/fullchain.pem
2
```

`/etc/letsencrypt/live/<name>/` holds **links**, and the files they point at are numbered in
`archive/`. When the certificate is renewed, certbot writes `cert2.pem` and moves the links, so a web
server configured with the `live/` paths never needs its configuration edited again. The four files:

| file | what it is | who needs it |
|---|---|---|
| `privkey.pem` | the private key | Nginx's `ssl_certificate_key`, and nobody else |
| `cert.pem` | the site's certificate alone | rarely anything |
| `chain.pem` | the intermediate | rarely anything on its own |
| `fullchain.pem` | the site's certificate followed by the intermediate | Nginx's `ssl_certificate` |

**Point Nginx at `fullchain.pem`, never at `cert.pem`.** A server that sends only its own certificate
works in a browser that happens to have the intermediate cached from another site, and fails
everywhere else, including `curl` and every phone that has not seen it. It is the most common TLS
mistake that survives testing, because the person testing has the intermediate cached.

The certificate itself names both hosts in its *Subject Alternative Name*, is issued by Pebble's
intermediate, and is valid for ninety days from the minute it was signed.
