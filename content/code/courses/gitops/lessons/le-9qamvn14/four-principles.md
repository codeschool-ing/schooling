---
title: The four principles
version: 1
---

**"GitOps" was coined in 2017 and spent years meaning whatever a vendor needed it to mean.** In
2021 a working group under the CNCF, OpenGitOps, wrote down four principles that the tools and
the companies behind them agreed on. They are short, and each one rules something out.

**1. Declarative.** The system's desired state is expressed declaratively. A Kubernetes manifest
says *two replicas of this image, behind this port*, not *run these commands*. The difference
matters because a description can be compared with reality, and a script can only be run. A
script that ran halfway leaves no record of what it meant to achieve.

**2. Versioned and immutable.** The desired state is stored in a way that keeps every version, and
a version, once written, does not change. Git does both: a commit has a hash computed from its
content and its parents, so the commit `ab88607` means exactly one tree of files, for ever. "Roll
back" becomes "point at an earlier version", and "what changed on Tuesday" has an exact answer.

**3. Pulled automatically.** Software agents pull the desired state from the source. Nobody runs a
deploy command, and nothing outside the cluster needs credentials into it. The previous section
argued why.

**4. Continuously reconciled.** Agents continuously observe the actual state and attempt to apply
the desired state. Not once per deploy: always. The loop never finishes, because the job is not
to make a change but to keep a difference at zero.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"The reconciliation loop: observe the actual state, compare it with the desired state from Git, act on the difference, and wait, round and round.\"><rect x=\"0\" y=\"0\" width=\"640\" height=\"300\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"118\" width=\"130\" height=\"64\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"85\" y=\"145\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">desired state</text><text x=\"85\" y=\"165\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">in Git</text><rect x=\"490\" y=\"118\" width=\"130\" height=\"64\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"555\" y=\"145\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">actual state</text><text x=\"555\" y=\"165\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">in the cluster</text><circle cx=\"320\" cy=\"150\" r=\"95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 5\"/><rect x=\"265\" y=\"40\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"320\" y=\"62\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">observe</text><rect x=\"355\" y=\"133\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"410\" y=\"155\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">compare</text><rect x=\"265\" y=\"226\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"320\" y=\"248\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">act</text><rect x=\"175\" y=\"133\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"230\" y=\"155\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">wait</text><line x1=\"150\" y1=\"150\" x2=\"171\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"/><line x1=\"469\" y1=\"150\" x2=\"486\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"/><text x=\"320\" y=\"290\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">it never finishes: the job is to keep the difference at zero</text></svg>", "caption": "The reconciliation loop. Every GitOps agent is this loop, run on an interval, on a change in Git, or on a change in the cluster."}
```

## What each principle rules out

| principle | what it forbids |
|---|---|
| declarative | a deploy that is a sequence of commands nobody can compare with the cluster |
| versioned and immutable | a "latest" that means something different tomorrow, and a history that can be rewritten |
| pulled automatically | a pipeline outside the cluster holding the keys to it |
| continuously reconciled | a change that lasts until somebody notices, made by hand and never written down |

**Git is not in the principles**, which surprises people. The word is "versioned", and an OCI
registry holding manifests, or an S3 bucket with versioning, satisfies it too; Flux can read
desired state from both, and lesson 7 uses the first. Git won because people already review
changes in it, and the review is where lesson 2 starts.

**Kubernetes is not in them either.** The principles describe any system with an API that accepts
a declared state and an agent to drive it. Kubernetes is where the tooling grew, because its
controllers already work this way: a Deployment is itself a reconciliation loop, comparing
replicas wanted with replicas running. GitOps extends the same loop one step outwards, from the
cluster's own database to a repository.
