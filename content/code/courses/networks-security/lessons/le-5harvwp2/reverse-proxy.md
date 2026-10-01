---
title: A reverse proxy stands in front
version: 1
---

The shop's application runs on `app`, in the servers segment, and **nobody on the internet talks to
it**. They talk to `www`, in the DMZ, which receives each request and makes a request of its own to
`app` on their behalf. That is a **reverse proxy**: a server that answers for other servers, the
mirror image of the forward proxy a company puts between its staff and the web.

From `remote`, a stranger on the internet, the shop answers and the application does not:

```
ana@remote:~$ curl -s https://www.example.com/
orders service: ok
ana@remote:~$ curl -s -m3 http://192.168.20.10:8080/; echo "exit $?"
exit 28
```

Both machines wrote the request down, and each saw a different client:

```
root@app:~# tail -1 /var/log/lab/app.log
192.0.2.80 - - [28/Sep/2026 15:23:48] "GET / HTTP/1.0" 200 -
root@www:~# tail -1 /var/log/nginx/access.log
203.0.113.50 - - [28/Sep/2026:15:23:48 -0300] "GET / HTTP/1.1" 200 19 "-" "curl/8.5.0"
```

`app` saw `192.0.2.80`, the proxy. **The application never exchanged a packet with the internet**,
and the firewall rule that lets anything reach it names one source, the proxy, on one port. The
proxy logged the real client, `203.0.113.50`, and passes it on in the `X-Forwarded-For` header,
because an application that needs the client's address has no other way to learn it.

That header is only as trustworthy as the machine that wrote it. `app` may believe it because the
firewall guarantees that only `www` can reach it; an application reachable directly would be
believing whatever a client chose to send.

## What the proxy is configured to do

```
root@www:~# cat /etc/nginx/sites-enabled/shop | sed -n "/listen 192.0.2.80:443/,/^}/p"
    listen 192.0.2.80:443 ssl;
    server_name www.example.com;
    ssl_certificate     /etc/ssl/private/www.crt;
    ssl_certificate_key /etc/ssl/private/www.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://192.168.20.10:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

The proxy **terminates TLS**: the certificate and its private key live on `www`, the encrypted
connection ends there, and the request travels on to `app` as plain HTTP. That is what lets the
proxy read and judge each request, which the rest of this lesson depends on. It also means the hop
from the DMZ to the servers segment carries readable traffic, which is acceptable only because that
path crosses the firewall and nothing else; lesson 20 encrypts it anyway.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A request&#x27;s path. remote, on the internet, opens HTTPS to www in the DMZ; the encrypted connection ends on www, which holds the certificate. www then makes its own plain HTTP request to app on port 8080, and the firewall allows that connection from www and from nothing else. app sees only www&#x27;s address; www logs remote&#x27;s and passes it on in X-Forwarded-For.\"><defs><marker id=\"rp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"rp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote</text><text x=\"30\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.50</text><rect x=\"290\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"300\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">holds the certificate</text><rect x=\"570\" y=\"70\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"580\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.10</text><path d=\"M160 93 L290 93\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#rp-ah-phosphor)\"></path><text x=\"225\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HTTPS :443</text><text x=\"225\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">encrypted</text><path d=\"M440 93 L570 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rp-ah-paper-dim)\"></path><text x=\"505\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP :8080</text><text x=\"505\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from www only</text><rect x=\"10\" y=\"40\" width=\"160\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"18\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">internet</text><rect x=\"280\" y=\"40\" width=\"170\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"288\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">DMZ</text><rect x=\"560\" y=\"40\" width=\"150\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"568\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">servers</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">www logs: 203.0.113.50</text><text x=\"570\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app logs: 192.0.2.80</text><text x=\"290\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">X-Forwarded-For: 203.0.113.50</text></svg>", "caption": "Two connections, not one. The first is encrypted and ends at the proxy; the second starts there."}
```

Putting one machine in front of the application buys several things at once:

| the proxy | what it gives |
|---|---|
| is the only address the internet sees | the application's machine, its port and its software stay private |
| terminates TLS | one place holds the certificate; one place is patched when TLS changes |
| reads every request before the application does | a place to refuse what the application should never receive |
| sits in the DMZ | if it is compromised, the attacker is in the DMZ, and lesson 4 makes that a small place |
