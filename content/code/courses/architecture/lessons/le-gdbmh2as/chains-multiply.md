---
title: Failures travel up the chain
version: 1
---

Latency adds along a chain. **Availability multiplies.** If the checkout needs pricing and pricing
needs stock, the checkout can answer only at moments when all three are up, and the chance of that is
the product of their separate chances.

| each service up | chain of 3 | chain of 5 | chain of 10 |
| --- | --- | --- | --- |
| 99.9% | 99.7% | 99.5% | 99.0% |
| 99% | 97.0% | 95.1% | 90.4% |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A chart of the availability of a chain against the number of services in it, from one to ten. With each service at 99.9%, the chain falls slowly, to about 99.0% at ten services. With each at 99%, it falls fast, to about 90.4% at ten.\"><defs><marker id=\"l5-avail-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M80 240 L680 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-avail-ah-wire)\"></path><path d=\"M80 240 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-avail-ah-wire)\"></path><text x=\"72\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90%</text><text x=\"72\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">95%</text><text x=\"72\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100%</text><text x=\"80.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"337.8\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"660.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"370\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">services in the chain</text><path d=\"M80.0 42.0 L144.4 44.0 L208.9 46.0 L273.3 48.0 L337.8 50.0 L402.2 52.0 L466.7 54.0 L531.1 55.9 L595.6 57.9 L660.0 59.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"42.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"144.4\" cy=\"44.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"208.9\" cy=\"46.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"273.3\" cy=\"48.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"337.8\" cy=\"50.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"402.2\" cy=\"52.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"466.7\" cy=\"54.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"531.1\" cy=\"55.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"595.6\" cy=\"57.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"660.0\" cy=\"59.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><path d=\"M80.0 60.0 L144.4 79.8 L208.9 99.4 L273.3 118.8 L337.8 138.0 L402.2 157.0 L466.7 175.9 L531.1 194.5 L595.6 213.0 L660.0 231.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"60.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"144.4\" cy=\"79.8\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"208.9\" cy=\"99.4\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"273.3\" cy=\"118.8\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"337.8\" cy=\"138.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"402.2\" cy=\"157.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"466.7\" cy=\"175.9\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"531.1\" cy=\"194.5\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"595.6\" cy=\"213.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"660.0\" cy=\"231.2\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"560\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">each 99.9%: 99.0% at ten</text><text x=\"230\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">each 99%: 90.4% at ten</text></svg>", "caption": "Availability multiplies along a synchronous chain. Ten services at 99% each give a chain that is down almost one hour in ten."}
```

A month has about 720 hours. One service at 99.9% is down about 43 minutes of it; a chain of ten such
services, about seven hours. **Every synchronous dependency you add is a slice of somebody else's
downtime added to yours.** The figures assume the services fail independently, which is optimistic:
services that share a database, a network or a deploy tend to fail together.

## Watching it happen

Stop the service at the end of the chain and ask the checkout:

```
ana@vm:~/lab/chain$ docker compose stop stock
 Container chain-stock-1 Stopping 
 Container chain-stock-1 Stopped 
ana@vm:~/lab/chain$ curl -s -w "%{http_code}\n" localhost:8000/
{"name": "checkout", "error": "http://pricing:8000/ answered 502", "next": {"name": "pricing", "error": "http://stock:8000/ unreachable: <urlopen error [Errno -2] Name or service not known>", "took_ms": 102}, "took_ms": 206}
502
```

Stock is down, and **nothing in the checkout is wrong**, yet the checkout answers `502`. Pricing could
not reach stock and said so; the checkout received pricing's error and said so in turn, carrying
pricing's answer inside its own. Each link reported honestly, and the request failed at the top for a
reason at the bottom. In a real system the person reading the checkout's error has to walk down the
chain to find it, which is what lesson 2's request id and `scale`'s traces are for.

Start stock again:

```
ana@vm:~/lab/chain$ docker compose start stock
 Container chain-stock-1 Starting 
 Container chain-stock-1 Started 
```

## Three ways to shorten the multiplication

- **Fewer hops**: ask yourself whether pricing really needs stock on this path, or whether the checkout
  can ask both, in parallel, and decide itself.
- **A fallback**: when stock does not answer, pricing could quote the basket and mark availability as
  unknown, rather than failing the whole request. Not every dependency allows one; a payment does not.
- **No waiting at all**: if the caller does not need the answer now, it does not need the other side
  to be up now. That is the asynchronous style, two sections on.
