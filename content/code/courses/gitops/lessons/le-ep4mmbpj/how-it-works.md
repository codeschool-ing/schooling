---
title: What Argo CD is made of
version: 1
---

**Argo CD is lesson 1's loop, split into the parts that each need to be good at one thing.** The
shell script fetched, rendered, compared and applied in one process and kept nothing. Argo CD gives
each of those jobs to a component of its own and keeps its state as Kubernetes objects.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Argo CD&#x27;s components: the repo server clones Git and renders manifests, the application controller compares them with the cluster and applies, the API server serves the web interface and the CLI, and Redis caches for both.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"300\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"120\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"75.0\" y=\"140.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"75.0\" y=\"158.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">fleet</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"265.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">repo server</text><text x=\"265.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">clone and render</text><rect x=\"190\" y=\"200\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"265.0\" y=\"220.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Redis</text><text x=\"265.0\" y=\"238.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">cache</text><rect x=\"400\" y=\"120\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"485.0\" y=\"140.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">application controller</text><text x=\"485.0\" y=\"158.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">compare and apply</text><rect x=\"610\" y=\"120\" width=\"90\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"655.0\" y=\"140.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><text x=\"655.0\" y=\"158.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">API</text><rect x=\"400\" y=\"230\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"485.0\" y=\"250.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">API server</text><text x=\"485.0\" y=\"268.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">web, argocd CLI</text><line x1=\"130\" y1=\"135\" x2=\"180.5\" y2=\"80.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"186,75 177.3,77.8 183.8,83.9\" fill=\"var(--paper-dim)\"/><line x1=\"340\" y1=\"75\" x2=\"412.9\" y2=\"112.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"420,116 414.9,108.3 410.8,116.4\" fill=\"var(--paper-dim)\"/><line x1=\"340\" y1=\"225\" x2=\"390.5\" y2=\"170.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"396,165 387.3,167.8 393.8,173.9\" fill=\"var(--paper-dim)\"/><line x1=\"570\" y1=\"145\" x2=\"598.0\" y2=\"145.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\"/><polygon points=\"606,145 598.0,140.5 598.0,149.5\" fill=\"var(--phosphor)\"/><line x1=\"485\" y1=\"226\" x2=\"485.0\" y2=\"182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"485,174 480.5,182.0 489.5,182.0\" fill=\"var(--paper-dim)\"/><text x=\"600\" y=\"105\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--phosphor)\">the only writer</text><text x=\"190\" y=\"22\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">no cluster credentials here</text></svg>", "caption": "Argo CD's parts. Only the application controller writes to the cluster; the repo server, which runs whatever a repository asks it to render, never holds the cluster's credentials."}
```

- **The repo server** clones repositories and turns a path into plain manifests. For a directory of
  YAML that is reading files; for Kustomize or Helm, which lesson 6 covers, it runs the tool. It holds
  no credentials to the cluster at all, which matters, because it is the component that runs
  whatever a repository asks it to render.
- **The application controller** is the loop. For every Application it asks the repo server for the
  desired manifests, reads the live objects from the cluster, compares the two, and records the
  result. When told to, it applies the difference. It is the one component with write access to the
  cluster.
- **The API server** answers the web interface and the `argocd` command. It does not apply
  anything; it asks the controller to.
- **Redis** caches what the repo server rendered and what the controller saw, so that a comparison
  every few minutes does not clone and render everything again.
- **Dex**, the ApplicationSet controller and the notifications controller are optional parts: single
  sign-on, generating many Applications from one template, and sending messages when something
  happens. Lesson 5 uses an ApplicationSet; lesson 12 the notifications.

## The Application, the unit of everything

Argo CD adds a resource type to the cluster, `Application`, and **one Application is one arrow from
a place in Git to a place in the cluster**: this repository, at this revision, at this path, goes
to this namespace of this cluster. Everything Argo CD reports is reported per Application: whether
it is in sync, whether it is healthy, which commit it is at, what it did and when.

Because an Application is itself a Kubernetes object, it can be described in YAML and kept in Git
like anything else. The end of this lesson does exactly that, and Argo CD ends up managing its own
list of applications from the repository.
