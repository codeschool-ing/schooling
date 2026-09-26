---
title: Isolate: rule out what works
version: 1
---

A page that does not open involves at least four things: Carla's computer, the network, the server and
the page. Isolating means asking questions whose answers rule out whole parts of that list:

```
ana@pc2:~$ curl -sS -m 10 http://intranet/
intranet: welcome
ana@pc1:~$ getent hosts intranet
10.30.0.200     intranet
ana@pc2:~$ getent hosts intranet
10.30.0.31      intranet
ana@pc1:~$ curl -sS -m 10 http://10.30.0.31/
intranet: welcome
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Isolating the fault by halving what is left. First question: does pc2 open the intranet? Yes, so the server and the page are fine. Second: does pc1 reach srv1 by its address, 10.30.0.31? Yes, so pc1&#x27;s network is fine. Third: do pc1 and pc2 find the same address for intranet? No: pc1 finds 10.30.0.200, so what is left is the name, on pc1, in /etc/hosts.\"><defs><marker id=\"hv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pc2 opens the intranet?</text><rect x=\"440\" y=\"16\" width=\"60\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"518\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the server and the page are fine</text><path d=\"M220 62 L220 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hv-ah)\"></path><rect x=\"20\" y=\"78\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pc1 reaches srv1 by its address?</text><rect x=\"440\" y=\"78\" width=\"60\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"518\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pc1&#x27;s network is fine</text><path d=\"M220 124 L220 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hv-ah)\"></path><rect x=\"20\" y=\"140\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pc1 and pc2 find the same address for intranet?</text><rect x=\"440\" y=\"140\" width=\"60\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no</text><text x=\"518\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the name, on pc1: /etc/hosts</text></svg>", "caption": "Three questions, each answered by a command, and each answer rules out a large part of what was left. The third does not find the cause by itself; it leaves one place to look."}
```

- `pc2`, a colleague's computer on the same network, **opens the page**. So `srv1` is up, nginx is
  serving and the page is there. Half the list is gone in one command.
- `getent hosts` asks each computer what address it has for the name `intranet`, the same way the
  browser does. **They disagree**: `pc2` finds `10.30.0.31`, `pc1` finds `10.30.0.200`.
- `pc1` opens the page **by address**, `10.30.0.31`. So its network card and its route to the server work.

What is left is small: **the name `intranet`, on `pc1` only**. Nothing has been changed yet, and that
is deliberate. Every check so far only read; if one of them had changed something, the next result would
not mean what it seems to.
