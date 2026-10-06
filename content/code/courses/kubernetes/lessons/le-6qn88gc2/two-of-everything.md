---
title: Two of everything, and nothing shared
version: 1
---

Look again at the pods in the last section. In `kind-shop`, `10.244.1.3` on `shop-worker`; in
`kind-eu`, `10.244.1.3` on `eu-worker`. **The same address, for two different pods**, because both
clusters were made from the same configuration and give out the same pod range:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A laptop holds one kubeconfig file with two contexts, kind-shop and kind-eu. Each context points at the API server of its own cluster. The two clusters each have their own control plane, their own etcd and their own nodes, and both give pods addresses from the same range, 10.244.0.0/16. No line joins the two clusters to each other; the only thing they share is the file on the laptop.\"><defs><marker id=\"mc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"250\" y=\"16\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">~/.kube/config</text><text x=\"360.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">kind-shop · kind-eu</text><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">current-context decides where a bare kubectl goes</text><rect x=\"40\" y=\"150\" width=\"240\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kind-shop</text><text x=\"160.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">own control plane, etcd, nodes</text><text x=\"160\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pods: 10.244.0.0/16</text><rect x=\"440\" y=\"150\" width=\"240\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kind-eu</text><text x=\"560.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">own control plane, etcd, nodes</text><text x=\"560\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pods: 10.244.0.0/16</text><path d=\"M300 88 L160 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah-phosphor)\"></path><path d=\"M420 88 L560 148\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah-amber)\"></path><path d=\"M290 190 L430 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nothing joins them</text></svg>", "caption": "Two clusters meet only in your kubeconfig. Each has its own API server and its own names, and here even the same pod addresses."}
```

Within one cluster, any pod can reach any other by its address, as lesson 18 showed. Across two, that
promise does not exist, and with overlapping ranges it cannot be added later without renumbering one
of them. **If clusters may ever need to talk pod to pod, give each its own range when it is made.** That
is a decision for the day the cluster is created.

Everything else is doubled the same way. Each cluster has its own etcd, so a Deployment named `shop`
in each is two unrelated objects that happen to share a name. Each has its own RBAC, so being an
administrator in one says nothing about the other. Each has its own DNS, so `shop.default.svc` answers
inside its own cluster only. And each has its own version, upgraded on its own day. **This is the point
of having two:** a bad change, a broken upgrade or a deleted namespace stays inside one of them.

That isolation is why there are usually several clusters even in a small company. The common splits are
by environment (staging cannot harm production), by region (a failure in one does not take the other),
and by trust (a team running code from customers gets a cluster nobody else shares). Namespaces from
lesson 20 split one cluster between teams; they share one control plane, one etcd and one upgrade, and
that is the line where a second cluster begins to pay.
