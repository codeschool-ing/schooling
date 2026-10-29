---
title: A certificate of your own, for a name of your own
version: 1
---

**Every step a host takes to serve a site over HTTPS can be taken on your computer, with one difference:
the authority that signs is yours, so only the programs you tell about it trust it.** That difference is
the whole lesson of this section, because it is the one a browser enforces.

## An authority and a certificate

`openssl`, which every Linux and Mac has, does both halves. First an authority: a key and a
self-signed certificate that says *I am the Planner lab CA*. Then a key for the site, a request naming
`planner.test`, and the authority's signature on it. The keys are elliptic-curve keys on the P-256
curve, the kind most certificates on the web use today:

```
ana@dev:~$ mkdir -p ~/tls && cd ~/tls
ana@dev:~/tls$ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ca.key
ana@dev:~/tls$ openssl req -x509 -key ca.key -out ca.crt -days 30 -subj "/CN=Planner lab CA"
ana@dev:~/tls$ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out planner.key
ana@dev:~/tls$ openssl req -new -key planner.key -out planner.csr -subj "/CN=planner.test"
ana@dev:~/tls$ openssl x509 -req -in planner.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out planner.crt -days 30 -extfile <(printf "subjectAltName=DNS:planner.test")
Certificate request self-signature ok
subject=CN = planner.test
ana@dev:~/tls$ openssl x509 -in planner.crt -noout -subject -issuer -ext subjectAltName
subject=CN = planner.test
issuer=CN = Planner lab CA
X509v3 Subject Alternative Name: 
    DNS:planner.test
```

The last command read the certificate back: issued **to** `planner.test`, **by** the lab's authority,
and valid **for** the one name in its subject alternative names. Thirty days is deliberate; a lab
authority whose key sits in a home folder should not outlive the lab.

## Serving it

Build the planner and start the grown host with the certificate, on port 8443:

```
ana@dev:~/planner$ CERT=~/tls/planner.crt KEY=~/tls/planner.key node host.mjs dist 8443
serving dist on https://127.0.0.1:8443, and redirecting http://127.0.0.1:8080
```

`planner.test` exists nowhere, so `curl` is told where it lives with `--resolve`, which pins a name to an
address for one command without touching any configuration. Ask for the page as a stranger would, and
then as somebody who trusts the lab's authority:

```
ana@dev:~/planner$ curl -sS --resolve planner.test:8443:127.0.0.1 https://planner.test:8443/ -o /dev/null
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@dev:~/planner$ curl -sS --cacert ~/tls/ca.crt --resolve planner.test:8443:127.0.0.1 https://planner.test:8443/ -o /dev/null -w '%{http_code}\n'
200
ana@dev:~/planner$ curl -sS --cacert ~/tls/ca.crt https://127.0.0.1:8443/ -o /dev/null
curl: (60) SSL: no alternative certificate subject name matches target host name '127.0.0.1'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Three answers, and each is the browser's too:

- **without the authority, refused**: `curl` could not link the certificate to any authority it trusts.
  A browser shows a full-page warning here, and that warning is the right answer: a certificate anybody
  can make proves nothing to somebody who did not make it.
- **with the authority, a 200**.
- **with the authority but the wrong name**, `127.0.0.1` instead of `planner.test`, refused again. The
  certificate is valid, and it is for a different name, which is precisely what a certificate exists to
  catch.

Browsers keep their own list of trusted authorities, and adding the lab's to it is what a tool such as
`mkcert` automates for local development. That step was not run for this course; `curl --cacert` showed
the same trust without changing anything on the computer.

## HTTP, redirected

The grown host also answers plain HTTP on port 8080, and only with a redirect:

```
ana@dev:~/planner$ curl -sI --resolve planner.test:8080:127.0.0.1 http://planner.test:8080/course/git
HTTP/1.1 308 Permanent Redirect
location: https://planner.test:8443/course/git
Date: Fri, 23 Oct 2026 23:04:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**308, Permanent Redirect**, to the same path over HTTPS. It is what all four hosts do on port 80 once a
domain has a certificate, and most of them do it without being asked. A browser that has seen the site
once can skip that first unencrypted request entirely when the site sends a
`Strict-Transport-Security` header; that header, and the others a site should send, are front-quality
lesson 8.

Stop the server with Ctrl-C. The `~/tls` folder holds an authority's private key: delete it when this
lesson is done, which the next sections do not need.
