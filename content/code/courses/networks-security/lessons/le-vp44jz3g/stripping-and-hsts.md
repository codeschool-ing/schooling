---
title: Stripping, and the header that prevents it
version: 1
---

People type `www.example.com`, not `https://www.example.com`, so the browser's first request goes out
over **plain HTTP**. Before this lesson changed anything, the shop answered it in clear:

```
ana@laptop:~$ curl -sI http://www.example.com/ | head -3
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Mon, 28 Sep 2026 20:51:47 GMT
```

Now the proxy is changed in two places: the plain-HTTP server does nothing but redirect, and the HTTPS
server adds one header to every answer:

```
root@www:~# grep -nE "return 301|Strict-Transport" /etc/nginx/sites-enabled/shop
4:    return 301 https://$host$request_uri;
12:    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
ana@laptop:~$ curl -sI http://www.example.com/orders | grep -iE "^HTTP|^location"
HTTP/1.1 301 Moved Permanently
Location: https://www.example.com/orders
ana@laptop:~$ curl -sI https://www.example.com/ | grep -iE "^HTTP|^strict"
HTTP/1.1 200 OK
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

The redirect sends the browser to HTTPS, and the HTTPS answer carries **`Strict-Transport-Security`**:
for the next 31,536,000 seconds, one year, this browser must use HTTPS for this site and every
subdomain, without asking.

**The redirect alone is not enough, and that is what stripping exploits.** The first request and the
redirect travel in clear. Somebody on the path answers that first request themselves, fetches the real
page over HTTPS on the user's behalf, and hands it back over HTTP with every link rewritten to HTTP.
The user never reaches HTTPS at all, and the redirect that would have taken them there never arrives.

HSTS closes the gap **from the second visit on**: a browser that has seen the header refuses plain
HTTP for the site before sending anything, so there is no clear request to answer. For the very first
visit, sites submit their domain to the **HSTS preload list** built into browsers, after which not
even the first request goes out in clear.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two visits to www.example.com. Without HSTS, the browser&#x27;s first request goes out over plain HTTP, the server answers with a redirect in clear, and only then does the browser switch to HTTPS; somebody on the path can answer that first request instead. With HSTS remembered from an earlier visit, or from the preload list, the browser goes straight to HTTPS and no plain request is ever sent.\"><defs><marker id=\"hs2-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hs2-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">without HSTS</text><rect x=\"20\" y=\"30\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">browser</text><rect x=\"560\" y=\"30\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com</text><path d=\"M150 42 L560 42\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"355\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GET http://www.example.com/</text><path d=\"M560 56 L150 56\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"355\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">301 to https://, in clear: the step somebody on the path can answer</text><path d=\"M150 92 L560 92\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-phosphor)\"></path><text x=\"355\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">GET https://www.example.com/</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">with HSTS, or preloaded</text><rect x=\"20\" y=\"152\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">browser</text><rect x=\"560\" y=\"152\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com</text><path d=\"M150 167 L560 167\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-phosphor)\"></path><text x=\"355\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">GET https://www.example.com/</text><text x=\"355\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no plain request is sent: nothing in clear to answer</text></svg>", "caption": "The redirect travels in clear. HSTS removes the request it answers."}
```

Two cautions. `includeSubDomains` commits every subdomain to HTTPS as well, so an old internal site on
plain HTTP under the same domain stops working in browsers that saw the header. And a year is a long
promise: deploy with a short `max-age` first, and raise it once nothing broke.
