---
title: Push and pull: who holds the keys
version: 1
---

**Most deployment pipelines push.** A change is merged, a CI job builds an image, and the same job
runs `kubectl apply` or `helm upgrade` against the cluster. It works, and it has three properties
that only show up later.

The first is **where the credentials live**. To push into the cluster, the CI system needs a
credential that can change the cluster, usually one that can change all of it. Every job that runs
in that CI system, including the ones on branches nobody reviewed, is a step away from that
credential. The `testing-cicd` course spends lesson 9 limiting the damage, and the limit is never
zero while the pipeline itself holds the key.

The second is **what the pipeline knows**. A push happens once, at the end of a job, and then the
job is gone. If somebody changes the cluster an hour later, nothing notices. If the apply half
failed, the pipeline turned red and the cluster stays half changed until somebody runs it again.

The third is **where the truth is**. After a few months of pushes, hot fixes and manual commands,
the honest answer to "what is running in production?" is "ask the cluster". The repository holds
what somebody meant to deploy, at some point.

## Turning it round

GitOps reverses the direction. **An agent inside the cluster pulls**: it reads the desired state
from a repository and changes the cluster to match. The CI system builds images and, at most,
writes a commit; it never talks to the cluster.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Two pipelines side by side. On the left, push: CI holds the cluster's credentials and applies changes into it. On the right, pull: CI only commits to Git, and an agent inside the cluster reads Git and applies.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"300\" fill=\"var(--ink)\"/><text x=\"180\" y=\"28\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">push</text><text x=\"540\" y=\"28\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">pull</text><line x1=\"360\" y1=\"15\" x2=\"360\" y2=\"285\" stroke=\"var(--wire)\" stroke-dasharray=\"4 4\"/><rect x=\"40\" y=\"50\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95\" y=\"77\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><rect x=\"40\" y=\"130\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95\" y=\"157\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">CI job</text><rect x=\"200\" y=\"200\" width=\"130\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"265\" y=\"240\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><line x1=\"95\" y1=\"94\" x2=\"95\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"90,122 100,122 95,130\" fill=\"var(--paper-dim)\"/><line x1=\"150\" y1=\"160\" x2=\"222\" y2=\"198\" stroke=\"var(--amber)\" stroke-width=\"2\"/><polygon points=\"214,200 226,201 219,191\" fill=\"var(--amber)\"/><text x=\"118\" y=\"204\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">kubectl apply,</text><text x=\"118\" y=\"220\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">with the keys</text><rect x=\"400\" y=\"50\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"455\" y=\"77\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">CI job</text><rect x=\"570\" y=\"50\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"625\" y=\"77\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><line x1=\"510\" y1=\"72\" x2=\"564\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"562,67 562,77 570,72\" fill=\"var(--paper-dim)\"/><text x=\"537\" y=\"112\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">a commit</text><rect x=\"520\" y=\"170\" width=\"170\" height=\"100\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"605\" y=\"258\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><rect x=\"545\" y=\"185\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"605\" y=\"210\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">agent</text><line x1=\"625\" y1=\"181\" x2=\"625\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"2\"/><polygon points=\"620,104 630,104 625,96\" fill=\"var(--phosphor)\"/><text x=\"634\" y=\"145\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--phosphor)\">reads</text></svg>", "caption": "In push, the CI job holds the cluster's keys and acts once. In pull, the CI job only commits, and the agent that holds the keys lives inside the cluster and keeps reading."}
```

Each of the three properties changes. **The credential to change the cluster never leaves it**: the
agent runs there with a service account, and what reaches the outside world is a read-only token
for the repository. **The agent keeps looking**, so a manual change or a failed apply is noticed on
its next pass rather than on the next deploy. And **the repository becomes the truth**, because
anything the cluster holds that the repository does not say is, by definition, a difference to be
corrected.

Pull has costs too, and they are real. A change takes effect when the agent next looks, not when
the pipeline finishes. The agent itself has to be installed, upgraded and watched. And the
repository becomes the most valuable thing you own, because whoever can write to it can change
production. Lesson 2 is about guarding it.
