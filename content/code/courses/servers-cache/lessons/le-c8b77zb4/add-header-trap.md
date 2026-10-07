---
title: The add_header trap
version: 1
---

This is the mistake that switches every header of the previous section off without a single warning,
and it is worth a section of its own because almost everybody makes it once.

The API should never be stored by a browser, so its location gets a `Cache-Control` header of its own:

```
ana@web:~$ sudo sed -i 's|        proxy_read_timeout 10s;|        proxy_read_timeout 10s;\n        add_header Cache-Control "no-store";|' /etc/nginx/sites-available/ipelivros && grep -n 'add_header' /etc/nginx/sites-available/ipelivros
31:        add_header Cache-Control "no-store";
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(cache-control|strict-transport|content-security)"
Cache-Control: no-store
```

**HSTS and CSP are gone from every API response.** Nginx did not complain, the test passed, and the
headers the site depends on vanished from one location because somebody added an unrelated header
to it. The rule is short and surprising:

> `add_header` directives are inherited from the enclosing block **only if the current block has no
> `add_header` of its own.** One `add_header` in a `location` replaces every one from the `server`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A server block holds five security headers. Its location for / has no add_header of its own and inherits all five. Its location for /api/ has one add_header, Cache-Control, and so inherits none of the five: its responses carry Cache-Control only.\"><defs><marker id=\"fih-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"660\" height=\"222\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server { ... }</text><text x=\"40\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Strict-Transport-Security</text><text x=\"40\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Content-Security-Policy</text><text x=\"40\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header X-Content-Type-Options</text><text x=\"40\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Referrer-Policy</text><text x=\"40\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Permissions-Policy</text><rect x=\"330\" y=\"30\" width=\"330\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">location / { }</text><text x=\"495.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no add_header here: inherits all five</text><rect x=\"330\" y=\"135\" width=\"330\" height=\"85\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">location /api/ { }</text><text x=\"495.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Cache-Control ...</text><text x=\"495.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">one add_header: inherits none</text><line x1=\"270\" y1=\"85\" x2=\"328\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fih-ah)\"></line><line x1=\"270\" y1=\"115\" x2=\"328\" y2=\"178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fih-ah)\"></line></svg>", "caption": "Inheritance of add_header is all or nothing. One header in a location replaces the whole list from the server."}
```

The fix is to repeat them where the new header is added, which a snippet makes cheap:

```
ana@web:~$ sudo sed -i 's|        add_header Cache-Control "no-store";|        add_header Cache-Control "no-store";\n        include snippets/security-headers.conf;|' /etc/nginx/sites-available/ipelivros && grep -n 'add_header\|security-headers' /etc/nginx/sites-available/ipelivros
12:    include snippets/security-headers.conf;
31:        add_header Cache-Control "no-store";
32:        include snippets/security-headers.conf;
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(cache-control|strict-transport|content-security)"
Cache-Control: no-store
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
```

All three are back. That is also the argument for keeping the security headers in a snippet rather
than writing them out in the server block: the day they have to be repeated in a location, it is one
`include`, and the list stays in one file.

**The check that catches this is a test of the live site, location by location**, not a reading of
the configuration: a line in a deployment script that asks for one URL under each location and
fails if `Strict-Transport-Security` is missing.
