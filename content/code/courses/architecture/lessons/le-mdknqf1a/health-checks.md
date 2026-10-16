---
title: Health checks
version: 1
---

Being registered says an instance started. It does not say it can do its job now. Each instance gave
Consul a URL to call every two seconds, `/health`, and an instance that answers anything but success is
marked **critical** and dropped from the healthy list. Ask the gateway for the stock six times, a third
of a second apart:

```
ana@vm:~/lab/gateway$ for i in $(seq 6); do curl -s localhost:8080/stock/coffee; sleep 0.3; done
stock-3: coffee 12
stock-1: coffee 12
stock-2: coffee 12
stock-1: coffee 12
stock-2: coffee 12
stock-3: coffee 12
```

The gateway spread the requests over all three instances. Now make `stock-2` report itself sick, wait
five seconds, and look again:

```
ana@vm:~/lab/gateway$ curl -s -X POST localhost:8002/sick
stock-2: sick
ana@vm:~/lab/gateway$ sleep 5; $D stock
2 healthy instance(s) of stock
  stock-1 at 172.18.0.6:8000
  stock-3 at 172.18.0.3:8000
ana@vm:~/lab/gateway$ for i in $(seq 6); do curl -s localhost:8080/stock/coffee; sleep 0.3; done
stock-3: coffee 12
stock-1: coffee 12
stock-3: coffee 12
stock-1: coffee 12
stock-3: coffee 12
stock-1: coffee 12
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline for stock-2. It registers with Consul, which checks its health every two seconds and gets 200 each time. Then the instance starts answering 503. On the next check Consul marks it critical, and the gateway, which refreshes its routes every two seconds, stops sending it requests. Requests in between may still reach it.\"><defs><marker id=\"l19-health-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-health-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40 120 L680 120\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l19-health-ah-wire)\"></path><path d=\"M60 112 L60 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"60\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M130 112 L130 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"130\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M200 112 L200 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"200\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M270 112 L270 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"270\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200</text><path d=\"M340 112 L340 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"340\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><path d=\"M410 112 L410 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"410\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><path d=\"M480 112 L480 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"480\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><path d=\"M550 112 L550 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"550\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">503</text><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">registered</text><text x=\"300\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">starts failing</text><path d=\"M300 70 L300 88\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-health-ah-amber)\"></path><text x=\"410\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">critical: out of the routes</text><path d=\"M410 150 L410 132\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-health-ah-amber)\"></path><rect x=\"300\" y=\"176\" width=\"110\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">still routed</text><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks every 2 s</text></svg>", "caption": "A health check turns a broken instance into one the registry knows is broken. The time between is a window in which it still gets traffic."}
```

Consul's next check found `stock-2` failing, the registry dropped it from the healthy list, and the
gateway, which reads the registry every two seconds, stopped sending it requests. The process is still
running, and nothing was restarted; it was taken **out of rotation** until it recovers. Between the
moment it fell sick and the moment the gateway noticed, a few seconds in the lab, requests could still
reach it, which is why lesson 11's retries belong in front of anything discovered this way.

Stopping an instance cleanly is faster still, because it deregisters itself on the way out instead of
waiting to fail a check:

```
ana@vm:~/lab/gateway$ docker compose stop stock-3; $D stock
 Container gateway-stock-3-1 Stopping 
 Container gateway-stock-3-1 Stopped 
1 healthy instance(s) of stock
  stock-1 at 172.18.0.6:8000
```

What a health check should test is a decision with two sides. **Too shallow**, a check that only proves
the process answers HTTP, and an instance whose database connection is broken stays in rotation and
fails every real request. **Too deep**, a check that calls every dependency, and one slow dependency
fails the checks of every instance at once, and the registry empties itself, a cascading failure that
the checks caused. Kubernetes separates the two questions: a **liveness** probe asks "should this process
be restarted?", and a **readiness** probe asks "should this instance get traffic right now?". The lab's
`/health` is a readiness check.
