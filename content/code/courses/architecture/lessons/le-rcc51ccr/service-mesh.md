---
title: The service mesh
version: 1
---

Lesson 2's shop has a timeout on its one call to the stock service and passes a request id along.
With twenty services, every one of them needs the same handful of network chores: timeouts and
retries, encryption between services, knowing who is calling, metrics for every call, and a way to
send a small share of traffic to a new version. Written into each service, in each language, they
drift apart. **A service mesh takes those chores out of the services and puts them in a proxy that
stands beside each one.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two services, each in a pod with a sidecar proxy beside it. The services talk only to their own proxy over localhost; the two proxies talk to each other across the network with mutual TLS, retries and timeouts. Above them, a control plane sends configuration and certificates to every proxy.\"><defs><marker id=\"l3-mesh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l3-mesh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"220\" y=\"24\" width=\"280\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">control plane</text><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">config, certificates, policy</text><rect x=\"40\" y=\"110\" width=\"260\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"54\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pod</text><rect x=\"56\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"106\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">shop</text><rect x=\"184\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">proxy</text><text x=\"234\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sidecar</text><path d=\"M158 185 L182 185\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-mesh-ah-wire)\" marker-start=\"url(#l3-mesh-ah-wire)\"></path><path d=\"M234 148 L234 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l3-mesh-ah-phosphor)\"></path><rect x=\"420\" y=\"110\" width=\"260\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"434\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pod</text><rect x=\"564\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">stock</text><rect x=\"436\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"486\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">proxy</text><text x=\"486\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sidecar</text><path d=\"M538 185 L562 185\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-mesh-ah-wire)\" marker-start=\"url(#l3-mesh-ah-wire)\"></path><path d=\"M486 148 L486 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l3-mesh-ah-phosphor)\"></path><path d=\"M286 200 L434 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-mesh-ah-phosphor)\" marker-start=\"url(#l3-mesh-ah-phosphor)\"></path><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mTLS, retries, timeouts between the proxies</text></svg>", "caption": "The data plane is a proxy beside every service, carrying all of its traffic. The control plane never touches a request; it tells the proxies what to do."}
```

## Two planes

**The data plane** is the proxies. Each service gets one, deployed with it as a *sidecar*, and every
byte the service sends or receives passes through it. The service talks plain HTTP to its own proxy
on `localhost`; the proxies talk to each other across the network, and they are where the timeouts,
retries and encryption happen. Envoy is the proxy most meshes use; Linkerd has its own, written in
Rust.

**The control plane** never touches a request. It holds the configuration, issues the certificates
and pushes both to every proxy: "calls to stock time out after two seconds", "send 5% of traffic to
stock version 2". Istio and Linkerd are the two best-known meshes, and both run on Kubernetes.

## What it gives

| feature | what it replaces in the service's own code |
| --- | --- |
| mutual TLS between services | certificates and TLS set up in every service, in every language |
| timeouts, retries, circuit breaking | the code lessons 11 and 12 write by hand |
| traffic splitting | a new version receiving a small share of requests before all of them |
| uniform metrics and traces | instrumentation added to each service separately |
| policy | "only the shop may call stock", enforced outside the stock service |

**Mutual TLS** is the feature that most often justifies a mesh. Each proxy holds a certificate that
names its service, and both sides of every connection check the other's, so a call is encrypted and
the stock service knows the caller really is the shop, without either program containing a line of
TLS code.

## What it costs

A proxy per service is a process per service: more memory, more CPU, and **two extra hops on every
call**, out through the caller's proxy and in through the callee's. The control plane is another
distributed system to install, upgrade and understand, and when a call fails, the failure may now be
in the configuration of a proxy nobody on the team wrote. A mesh earns its place at the scale where
twenty teams would otherwise write the same retry logic twenty times; for Quitanda's two services it
would be more machinery than system.

Lesson 15 builds the sidecar pattern by hand in your lab, a proxy beside a service in a shared
network, which is the mesh's data plane with the control plane taken away.
