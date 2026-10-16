---
title: Flux is a set of controllers
version: 1
---

**Argo CD has one central idea, the Application. Flux has several small ones, each a resource type
with a controller of its own**, and a deployment is what you get by chaining them. The split follows
the same line lesson 3 drew inside Argo CD, between fetching and applying, and makes it visible in
the objects you write.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Flux&#x27;s chain: a GitRepository is fetched by the source controller into an artifact; a Kustomization takes a path of that artifact, and the kustomize controller builds and applies it to the cluster. The notification controller receives webhooks that make the source controller fetch at once.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"280\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"110\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"75.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"75.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">fleet</text><rect x=\"170\" y=\"110\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"245.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">GitRepository</text><text x=\"245.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">source controller</text><rect x=\"360\" y=\"110\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"435.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">artifact</text><text x=\"435.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">files at one revision</text><rect x=\"550\" y=\"110\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"625.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Kustomization</text><text x=\"625.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">kustomize controller</text><rect x=\"550\" y=\"210\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"625.0\" y=\"230.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><text x=\"625.0\" y=\"248.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">objects</text><rect x=\"170\" y=\"20\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"245.0\" y=\"40.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Receiver</text><text x=\"245.0\" y=\"58.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">notification controller</text><line x1=\"130\" y1=\"135\" x2=\"158.0\" y2=\"135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"166,135 158.0,130.5 158.0,139.5\" fill=\"var(--paper-dim)\"/><line x1=\"320\" y1=\"135\" x2=\"348.0\" y2=\"135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"356,135 348.0,130.5 348.0,139.5\" fill=\"var(--paper-dim)\"/><line x1=\"510\" y1=\"135\" x2=\"538.0\" y2=\"135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"546,135 538.0,130.5 538.0,139.5\" fill=\"var(--paper-dim)\"/><line x1=\"625\" y1=\"160\" x2=\"625.0\" y2=\"198.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\"/><polygon points=\"625,206 629.5,198.0 620.5,198.0\" fill=\"var(--phosphor)\"/><line x1=\"245\" y1=\"70\" x2=\"245.0\" y2=\"98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"245,106 249.5,98.0 240.5,98.0\" fill=\"var(--paper-dim)\"/><text x=\"330\" y=\"48\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">a push: fetch now</text><text x=\"20\" y=\"250\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">every minute: fetch</text><text x=\"360\" y=\"250\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">every ten minutes: apply</text></svg>", "caption": "Flux's chain of objects. Fetching and applying are two resources with two intervals, and only the kustomize controller writes to the cluster."}
```

- **The source controller** fetches. A `GitRepository` says: clone this repository, at this branch,
  every minute. The controller does it and keeps the result inside the cluster as an **artifact**, a
  compressed copy of the files at one revision, which other controllers download. `OCIRepository`,
  `HelmRepository` and `Bucket` are the same idea for other places desired state can live.
- **The kustomize controller** applies. A `Kustomization` (Flux's resource, not to be confused with
  Kustomize's `kustomization.yaml` file) says: take this path of that source's artifact, build it
  with Kustomize, and apply it, every ten minutes, pruning what disappeared. It is the
  application controller of lesson 3, and the only one of these that writes ordinary objects into
  the cluster.
- **The helm controller** installs Helm charts as real Helm releases, from a `HelmRelease`. Lesson 6
  uses it.
- **The notification controller** sends events out, to a chat or a Git server's commit status, and
  takes webhooks in, so that a push can trigger a fetch at once. This lesson sets one up.
- **The image controllers**, optional, watch a registry for new tags and write the new tag back
  into Git. Lesson 7 is where they belong.

There is no web interface, no API server of its own and no users: **Flux's interface is the
Kubernetes API**. Everything it knows is in the status of its objects, which `kubectl` and the
`flux` command read. That makes it smaller and leaves the questions of who may do what to
Kubernetes' own permissions, which lesson 11 is about.
