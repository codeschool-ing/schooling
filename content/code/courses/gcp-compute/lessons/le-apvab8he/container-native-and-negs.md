---
title: Container-native load balancing and NEGs
version: 1
---

The load balancer of section 03 has to send each request to a pod. There are two ways it can know
where the pods are, and **the difference is one hop that used to be in every request.**

## The old path: through the nodes

A load balancer that only knows about virtual machines sends traffic to the **nodes**, on a port
Kubernetes opens on every node for the Service. The node then hands the request to `kube-proxy`'s
rules, which forward it to a pod, very often a pod on a **different node**. So a request crossed
the network twice, the health check tested nodes rather than pods, and a pod that was shutting down
kept receiving traffic until the rules caught up.

## The new path: straight to the pod

**A network endpoint group, NEG, is a list of pod addresses and ports that the load balancer uses
as its backend directly.** GKE keeps the list in step as pods start and stop, and the load balancer
sends each request to a pod, health-checking pods rather than nodes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two paths for one request. Above, through the nodes: the load balancer sends the request to node A on a node port, and kube-proxy on node A forwards it across the network to a pod on node B. Below, container-native: the load balancer sends the request straight to the pod address in its network endpoint group.\"><defs><marker id=\"l16n-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">through the nodes</text><rect x=\"24\" y=\"44\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">load balancer</text><rect x=\"220\" y=\"36\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node A</text><text x=\"320\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"480\" y=\"36\" width=\"216\" height=\"60\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node B</text><rect x=\"538\" y=\"58\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><path d=\"M156 66 L216 66\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16n-ah)\"></path><path d=\"M422 74 L534 74\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16n-ah)\"></path><text x=\"160\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node port, then a second hop</text><text x=\"24\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container-native, with a NEG</text><rect x=\"24\" y=\"186\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">load balancer</text><text x=\"588\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a pod on node B</text><rect x=\"538\" y=\"200\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><path d=\"M156 215 L534 215\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16n-ah)\"></path><text x=\"300\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">straight to the pod's address</text></svg>", "caption": "With node backends a request lands on any node and is forwarded, often to another one. A NEG lists the pods themselves, so the hop disappears and health checks test pods."}
```

This is called **container-native load balancing**, and on a VPC-native cluster, which is what GKE
creates by default and Autopilot always is, Ingress and Gateway use it without being asked. You can
see it requested, or ask for it on a Service of your own, with one annotation:

```yaml
metadata:
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
```

Shown from Google's documentation; not run.

## What it changes in practice

- **One hop fewer** for every request, which is lower latency and no cross-node traffic created by
  the load balancer itself.
- **Health checks reach pods.** A pod that fails its check stops receiving traffic, even while the
  node it is on is healthy; with node backends, a node with one bad pod among good ones looked fine.
- **Readiness reaches the load balancer.** GKE adds a readiness gate to the pods, so a new pod is
  counted as ready by Kubernetes only once the load balancer has it as a healthy endpoint. During
  a rollout, old pods are not removed before their replacements can actually be reached from
  outside.

That last point is the one that matters on the day of a deploy. Without it, a rolling update can be
"complete" in Kubernetes while the load balancer still has no healthy new endpoint, and customers
see errors for the minute in between.

## What a NEG asks of the pod

A pod behind a NEG receives traffic from Google's load balancer and its health checks, from
Google's own address ranges. The firewall must let those ranges reach the pods' port, which GKE
sets up for the Ingress it manages; and the pod should answer its health check path quickly and
honestly, because the load balancer now believes it about that one pod.
