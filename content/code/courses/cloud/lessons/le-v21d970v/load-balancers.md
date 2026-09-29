---
title: "Load balancers: one address in front of many machines"
version: 1
---

An application that runs on one machine goes down with that machine. Run it on four, and a client
still needs a single address to connect to, one that does not change when a machine is replaced.
**A load balancer is that address.** Clients connect to it; it passes each connection or request to
one of the machines behind it, which the provider calls **targets**, and it stops sending to any
target that is not healthy.

On AWS a load balancer is reached by a DNS name the provider gives it, and the addresses behind the
name are the provider's to change; you point your own name at it and never write its address down.

## Layer 4 or layer 7

The OSI layers from `networks` are the cleanest way to tell the two kinds apart.

**A network load balancer works at layer 4.** In its plain form it forwards TCP or UDP connections:
it sees addresses and ports, picks a target, and passes the bytes along without reading them. It does not know
whether they are HTTP, a database protocol or a game. That makes it the choice for anything that
is not HTTP, and for very high connection counts.

**An application load balancer works at layer 7.** It speaks HTTP: it ends the client's TLS
connection itself, holding the certificate, reads the request, and can route on what it reads.
Requests for `api.example.com` go to one group of targets and `www.example.com` to another;
`/images/` to one service and everything else to the application. The price of reading the request
is that the connection the target sees comes from the load balancer, not from the client. The
client's own address arrives in the `X-Forwarded-For` header, and an application that logs the
source address of the connection logs the load balancer's.

## Health checks

**A load balancer checks every target on its own schedule**, by opening a connection or requesting
a path such as `/health` every few seconds. The load balancer marks a target that fails several checks in a row
as unhealthy and sends it no more traffic, and brings it back once it passes again. That is how a
machine that crashed at three in the morning stops receiving customers before anybody is awake. An
autoscaling group from lesson 4 can be told to use the same check, so that it replaces the instance
as well as avoiding it.

The check is only as good as the path it asks for. A `/health` that returns 200 while the database
is unreachable keeps a broken target in service; one that fails whenever the database is slow can
take every target out at once.

## Across zones

A load balancer is given a subnet in each zone it should serve, and runs nodes in each of them. It
sits in the **public** subnets, because that is where clients reach it, and its targets sit in
private ones. With targets in two zones, losing a zone costs half the capacity rather than the
application.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Clients connect to one application load balancer, which spans zone a and zone b. It sends traffic to three healthy targets, 10.0.32.10 and 10.0.32.11 in zone a and 10.0.48.12 in zone b. The fourth target, 10.0.48.13 in zone b, fails its health check on /health and receives nothing.\"><defs><marker id=\"lb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"10\" width=\"180\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">clients</text><path d=\"M360 42 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"60\" y=\"70\" width=\"600\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">application load balancer, one address</text><rect x=\"40\" y=\"130\" width=\"310\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"52\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zone a</text><text x=\"52\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">private subnet</text><text x=\"138\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10.0.32.0/20</text><rect x=\"370\" y=\"130\" width=\"310\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"382\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zone b</text><text x=\"382\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">private subnet</text><text x=\"468\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10.0.48.0/20</text><rect x=\"60\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.32.10</text><text x=\"125\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">healthy</text><path d=\"M125 106 L125 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"205\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.32.11</text><text x=\"270\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">healthy</text><path d=\"M270 106 L270 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"390\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.48.12</text><text x=\"455\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">healthy</text><path d=\"M455 106 L455 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"535\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.48.13</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">fails /health</text><text x=\"600\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">receives nothing</text></svg>", "caption": "One address in front of four targets in two zones. The target failing its health check is taken out of rotation; losing a whole zone would still leave two."}
```

## What it costs

An application load balancer is billed by the hour, plus a charge for the capacity it uses, which
AWS measures in its own units and which the sheet does not list. The hourly part:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|ALB'
                                        sa-east-1    us-east-1
  load balancer (ALB), per hour            0.0340       0.0225
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0340, 2), round(730 * 0.0225, 2))"
24.82 16.43
```

That is 24.82 dollars a month of 730 hours in `sa-east-1` and 16.43 in `us-east-1`, before a single
request. Lesson 10 is where these fixed monthly amounts are added up, and it is the reason a
side project with one small machine often does not have a load balancer at all.
