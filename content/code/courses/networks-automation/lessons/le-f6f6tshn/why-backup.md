---
title: What a backup is for
version: 1
---

A configuration backup sounds like insurance against a router dying, and that is the least of
what it does. A router dies rarely. **The questions a backup answers
every week are about change**: what is different on edge1 since Tuesday, who added that route, what
did this router look like before last night's maintenance window. A single copy answers none of
them. A history does.

So the job in this lesson does three things, every night, for every router: read the running
configuration, store it in a Git repository, and commit only when something changed. The history
is then a list of changes with dates, and `git diff` between any two of them is a question answered.

Lesson 10 added a second source: the data and the template say what the network **should** run.
With a backup that says what it **does** run, the difference between the two is drift, and finding
it is a script:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four scripts around three places. On the left, the routers. backup.py reads their running configuration every night into backups, a Git repository at the top right, which keeps one commit per change. render.py turns the data and the template into configs, at the bottom right: what the network should be. compare.py reads backups and configs and says what is missing and what is extra. restore.py takes a configuration from the history and puts it back on a router.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"170\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the routers</text><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">core1, edge1, edge2</text><text x=\"105.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what is running</text><rect x=\"470\" y=\"20\" width=\"230\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">backups/</text><text x=\"585.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Git: one commit per change</text><text x=\"585.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what was running, and when</text><rect x=\"470\" y=\"190\" width=\"230\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">configs/</text><text x=\"585.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rendered from data/ and frr.j2</text><text x=\"585.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what should be running</text><path d=\"M192 120 L466 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"300\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">backup.py</text><path d=\"M466 85 L192 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#lp-ah)\"></path><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">restore.py</text><path d=\"M585 186 L585 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"640\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">compare.py</text></svg>", "caption": "A backup records what was running; the data says what should be. Comparing the two is how drift is found."}
```

Two things make a backup job worth trusting, and both are in this lesson. **It has to say when it
failed**, because a router that stopped answering leaves an old file in the repository that looks
exactly like a new one. And **a backup is as sensitive as the router**: configurations carry
passwords, keys and the shape of the network, so the repository's access list is the routers'
access list, and the copy on a laptop counts.
