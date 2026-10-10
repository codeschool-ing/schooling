---
title: HTTPS with an authority of your own
version: 1
---

**HTTPS is HTTP inside TLS, and TLS does two jobs: it encrypts the conversation, and it proves to the
client that the server is the one it asked for.** The second job is the one people forget, and it is
done by a certificate: a public key and a list of names, signed by an authority the client already
trusts.

The idea that HTTPS matters only for the login page does not survive lessons 7 to 9. Every one of
them ends with a secret travelling in every request: a password in Basic authentication, a token, a
session cookie. Here is what Basic authentication puts on the wire, and what anybody who reads those
bytes recovers from it:

```
ana@api:~/shelf$ curl -sv -u ana:correct-horse localhost:8000/v1/books/1 2>&1 | grep -i '^> authorization'
> Authorization: Basic YW5hOmNvcnJlY3QtaG9yc2U=
ana@api:~/shelf$ echo YW5hOmNvcnJlY3QtaG9yc2U= | base64 -d; echo
ana:correct-horse
```

Base64 is a way of writing bytes as text, not a cipher, and the second command needs no key. Over
plain HTTP, that header crosses every network between the client and the server exactly as printed,
on every request. **Over HTTPS the same header is inside the encryption**, and an observer learns which server was contacted and how much was sent, but not
what.

## An authority of your own

A public authority signs certificates only for names on the public internet, and a VM called `api`
has none. So the lab makes its own authority, a CA, and has it sign a certificate for the server.
Every step is `openssl`, which lesson 1 installed. Make a directory for the files, inside `~/shelf`,
and go into it with `cd tls`:

```
ana@api:~/shelf$ mkdir tls
```

Then the authority: a private key and a certificate that signs itself, valid for thirty
days. The `-----` is all `openssl req` prints when nothing goes wrong:

```
ana@api:~/shelf/tls$ openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -days 30 -subj '/CN=shelf lab CA' -keyout ca.key -out ca.crt
-----
```

The server's own key, and a certificate signing request, which carries the server's public key to
the authority:

```
ana@api:~/shelf/tls$ openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -subj '/CN=localhost' -keyout server.key -out server.csr
-----
```

**The names the certificate is valid for go in `subjectAltName`.** Browsers check that list and ignore
the `CN` of the subject, so a certificate without it is refused by every current browser. This one is good for the name `localhost` and the address `127.0.0.1`:

```
ana@api:~/shelf/tls$ printf 'subjectAltName = DNS:localhost, IP:127.0.0.1\n' > server.ext
ana@api:~/shelf/tls$ openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 -extfile server.ext -out server.crt
Certificate request self-signature ok
subject=CN = localhost
```

The certificate names its subject, the authority that signed it, and the two names it covers:

```
ana@api:~/shelf/tls$ openssl x509 -in server.crt -noout -subject -issuer -ext subjectAltName
subject=CN = localhost
issuer=CN = shelf lab CA
X509v3 Subject Alternative Name: 
    DNS:localhost, IP Address:127.0.0.1
```

The two `.key` files are the secrets. Whoever holds `server.key` can be this server, and whoever holds
`ca.key` can make a certificate for any name that anything trusting `ca.crt` will believe. Make them
readable by you alone:

```
ana@api:~/shelf/tls$ chmod 600 ca.key server.key; ls -l
total 28
-rw-rw-r-- 1 ana ana 587 Oct 10 01:23 ca.crt
-rw------- 1 ana ana 241 Oct 10 01:23 ca.key
-rw-rw-r-- 1 ana ana  41 Oct 10 01:23 ca.srl
-rw-rw-r-- 1 ana ana 599 Oct 10 01:23 server.crt
-rw-rw-r-- 1 ana ana 355 Oct 10 01:23 server.csr
-rw-rw-r-- 1 ana ana  45 Oct 10 01:23 server.ext
-rw------- 1 ana ana 241 Oct 10 01:23 server.key
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 275\" role=\"img\" aria-label=\"The CA key signs the server certificate. The server holds server.key and server.crt and presents the certificate. curl holds ca.crt, checks the signature against it, and checks that the name asked for is in the subjectAltName. Without ca.crt, or with a name not in the list, curl refuses.\"><defs><marker id=\"l13-tls-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ca.key</text><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">kept secret, signs</text><rect x=\"20\" y=\"120\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ca.crt</text><text x=\"120.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">public, handed to clients</text><rect x=\"270\" y=\"20\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server.crt</text><text x=\"370.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DNS:localhost, IP:127.0.0.1</text><rect x=\"270\" y=\"120\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server.key</text><text x=\"370.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">kept secret, by secure.py</text><rect x=\"520\" y=\"70\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl --cacert ca.crt</text><line x1=\"220\" y1=\"50\" x2=\"268\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-tls-ah)\"></line><text x=\"244.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signs</text><line x1=\"370\" y1=\"80\" x2=\"370\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"470\" y1=\"70\" x2=\"518\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-tls-ah)\"></line><text x=\"494\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">presents</text><line x1=\"120\" y1=\"180\" x2=\"120\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"120\" y1=\"198\" x2=\"610\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"610\" y1=\"198\" x2=\"610\" y2=\"132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-tls-ah)\"></line><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">trusts</text><text x=\"360\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">curl checks two things: the signature leads to a CA it trusts, and the name it asked for is in the list.</text><text x=\"360\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Fail either, and the connection ends before a byte of HTTP is sent.</text></svg>", "caption": "Who signs what and who trusts whom. The two keys never leave the machine that made them; the two certificates are public."}
```

## The server, and a client that checks

Stop `secure.py` with `Ctrl+C` and start it in HTTPS mode, from `~/shelf`:

```sh
python3 secure.py --tls
```

```
secure shelf on https://127.0.0.1:8443, pages allowed: http://localhost:8080
```

Asked without being told about the new authority, curl refuses, because nothing it trusts signed the
certificate:

```
ana@api:~/shelf$ curl -sS https://localhost:8443/v1/books/1
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Given `ca.crt`, it checks the signature, finds `localhost` in the list, and the request goes through:

```
ana@api:~/shelf$ curl -sS --cacert tls/ca.crt https://localhost:8443/v1/books/1
{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

And asked under a name the certificate does not list, it refuses again, even with the right
authority. `--resolve` sends the name `shelf.test` to `127.0.0.1` without touching any DNS:

```
ana@api:~/shelf$ curl -sS --cacert tls/ca.crt --resolve shelf.test:8443:127.0.0.1 https://shelf.test:8443/v1/books/1
curl: (60) SSL: no alternative certificate subject name matches target host name 'shelf.test'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

**Never answer that error by turning verification off.** curl's `-k`, Python's `verify=False` and
their relatives in every language make the error go away by removing the second job of TLS: the
connection is still encrypted, to whoever answered. The right answers are the ones above, the
authority's certificate given to the client, or a certificate that lists the name.

`openssl s_client` shows the same check from the inside: the chain from the server's certificate up
to the authority, each link verified, and the version of TLS agreed:

```
ana@api:~/shelf$ openssl s_client -connect 127.0.0.1:8443 -CAfile tls/ca.crt </dev/null 2>&1 | grep -E '^depth|^verify|^New,|Verify return code'
depth=1 CN = shelf lab CA
verify return:1
depth=0 CN = localhost
verify return:1
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

In production the authority is a public one, usually Let's Encrypt, which issues certificates
for a domain you control to a program on the server that renews them automatically. A private CA like this one is right for a lab and
for services that talk only to each other inside one organisation. And the process holding the
certificate is usually not the API: a reverse proxy such as nginx holds it and passes plain HTTP to
the API on the same machine. That arrangement, TLS termination, belongs to the `servers-cache`
course.

## HSTS

HTTPS on its own leaves one gap: the first request. Somebody types `shop.example` with no scheme,
the browser tries `http://`, and that one plaintext request can be answered by anyone on the network
in between. **`Strict-Transport-Security` closes it from the second visit on.** It tells the browser
to use only HTTPS for this host for the number of seconds given, to rewrite every `http://` link
itself, and to give the user no way past a certificate error.

```
ana@api:~/shelf$ curl -si --cacert tls/ca.crt https://localhost:8443/v1/books/1 | grep -i '^strict'
Strict-Transport-Security: max-age=31536000
```

`max-age=31536000` is a year. Two rules come with it. The header is sent only over HTTPS, because
over plain HTTP anybody in between could remove it or forge it, and browsers ignore it there. The plain mode of `secure.py` does not send it, as every transcript before this section shows. And it is a promise that is hard to take back. A browser that saw it will refuse plain HTTP for a year, so a
real site starts with a few minutes and raises the number once HTTPS is known to work everywhere.
`includeSubDomains` extends it to every subdomain, and `preload` asks browsers to ship it built in,
which closes even the first visit. curl applies it only when asked, with `--hsts` and a file to
remember it in; HSTS is a browser's defence.
