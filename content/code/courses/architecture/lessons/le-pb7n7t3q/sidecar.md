---
title: The sidecar
version: 1
---

The edge does not talk to the stock service; it talks to `stock:8080`, which is the **sidecar**. Look at
how it is declared in `compose.yaml`: `network_mode: service:stock`. The sidecar runs in its own
container, from its own image, but **in the stock service's network namespace**: the same interfaces,
the same `localhost`, the same ports. To the stock service, the sidecar is a process on the same
machine; to everybody else, the two are one address.

Every request the edge sent to the new stock service passed through it, and it logged each one:

```
ana@vm:~/lab/strangler$ docker compose logs sidecar --tail 5
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 1 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A box for the stock service&#x27;s network namespace contains two processes: the sidecar, listening on port 8080, and the stock service, on port 8000. The edge sends requests to the sidecar on 8080; the sidecar logs each one and forwards it to localhost:8000.\"><defs><marker id=\"l15-sidecar-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"95\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">edge</text><rect x=\"230\" y=\"40\" width=\"460\" height=\"160\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"460\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">one network namespace: the stock service's</text><rect x=\"260\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sidecar</text><text x=\"340\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:8080, logs</text><rect x=\"500\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:8000</text><path d=\"M162 120 L258 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-sidecar-ah-phosphor)\"></path><path d=\"M422 120 L498 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-sidecar-ah-phosphor)\"></path><text x=\"460\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost</text></svg>", "caption": "A sidecar shares the service's network namespace: to the service it is localhost, and every request on its way in passes through it."}
```

The stock service has no logging code and does not know it is being logged. That is the pattern's
point: **cross-cutting work is done beside the service instead of inside it**, by a component that is
the same for every service whatever language each is written in. A Python service and a Java service
get the same request logs, the same metrics and the same TLS, from the same sidecar, configured the
same way.

The name comes from the seat attached to a motorcycle: it goes wherever the motorcycle goes, is started
and stopped with it, and is a separate thing. In Kubernetes the arrangement is built in: the containers
in a **pod** share a network namespace exactly as the lab's two containers do, and a sidecar is simply a
second container in the pod.

This is also what lesson 3's **service mesh** is made of. Istio and Linkerd put an Envoy or Linkerd proxy
as a sidecar beside every service; together, those sidecars are the mesh's **data plane**. What the lab
does not have is the **control plane**, the component that configures every sidecar at once, hands out
certificates and collects what they observe. The lab's sidecar is configured by three environment
variables; a mesh's sidecars are configured by the control plane, which is what makes a hundred of them
manageable.
