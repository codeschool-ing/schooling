---
title: Nginx in front of the application
version: 1
---

Asked directly, the bookshop answers on its own port, and it can see exactly who asked:

```
ana@web:~$ curl -s localhost:8001/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "localhost:8001", "x_real_ip": null, "x_forwarded_for": null, "x_forwarded_proto": null}
```

**A reverse proxy is a server that answers on the application's behalf.** The client connects to
Nginx and never learns that the application exists; Nginx opens a connection of its own to the
application, forwards the request, and copies the answer back. The word "reverse" is there because
an ordinary proxy works for the client, as an office's proxy does for its employees, and a reverse
proxy works for the server.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"The client connects only to Nginx on port 80. Nginx serves files from /var/www/ipe itself and opens its own connections to the two copies of the shop on 127.0.0.1 ports 8001 and 8002 for anything under /api/.\"><defs><marker id=\"fpx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"120\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><text x=\"80.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">curl, browser</text><rect x=\"230\" y=\"70\" width=\"170\" height=\"110\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nginx :80</text><text x=\"315.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">upstream shop</text><line x1=\"140\" y1=\"125\" x2=\"228\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><text x=\"184\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">connection 1</text><rect x=\"500\" y=\"20\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">/var/www/ipe</text><text x=\"590.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">files</text><rect x=\"500\" y=\"100\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop1</text><text x=\"590.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">127.0.0.1:8001</text><rect x=\"500\" y=\"180\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop2</text><text x=\"590.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">127.0.0.1:8002</text><line x1=\"400\" y1=\"95\" x2=\"498\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><line x1=\"400\" y1=\"125\" x2=\"498\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><line x1=\"400\" y1=\"155\" x2=\"498\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><text x=\"440\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/css/...</text><text x=\"450\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/api/...</text><text x=\"440\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">connection 2</text></svg>", "caption": "Two connections where there used to be one. The application only ever sees the second, which is why the next section has to tell it about the first."}
```

One `location` block inside lesson 1's server block is enough. A `location` names a part of the URL
space, and everything under `/api/` is now handed to the first copy of the shop:

```
ana@web:~$ grep -A2 'location /api/' /etc/nginx/sites-available/ipelivros
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
    }
ana@web:~$ curl -si http://ipelivros.example/api/books/3
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:25:39 GMT
Content-Type: application/json
Content-Length: 131
Connection: keep-alive
X-Served-By: shop1
ETag: "ec5dc1095232d72e"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT

{"id": 3, "title": "A Hora da Estrela", "author": "Clarice Lispector", "price_cents": 3990, "stock": 20, "updated_at": 1788267600}
```

The headers are a mix of the two programs. `Server`, `Date` and `Connection` are Nginx's; `X-Served-By`,
`ETag` and `Last-Modified` came through from the shop untouched. The rest of the site is still files
from `/var/www/ipe`, so **one name now serves both the static front and the API**, which is the
arrangement almost every web application in production has.

## What the application sees now

Ask the shop what it was told:

```
ana@web:~$ curl -s http://ipelivros.example/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "127.0.0.1:8001", "x_real_ip": null, "x_forwarded_for": null, "x_forwarded_proto": null}
```

Two things are lost, and both matter. **`peer` is Nginx**, because Nginx opened the connection. Every
request the shop receives now comes from `127.0.0.1`, so its logs, its rate limits and anything else
that wants to know who the client is see one client. And **`host` is `127.0.0.1:8001`**, the address
in `proxy_pass`, not the name the browser asked for, so an application that builds links from its
`Host` header now builds them wrong. The next section puts both back.

Notice also what `proxy_pass` does with the path. Written as `http://127.0.0.1:8001` with no path,
the request's own path is passed unchanged: `/api/books/3` goes to the shop as `/api/books/3`. Written
with a path, as `proxy_pass http://127.0.0.1:8001/;` would be, the part of the URL that matched the
`location` is replaced by it, and the shop would receive `/books/3`. One slash changes the request
the application receives, and it is the commonest surprise in a first proxy configuration.
