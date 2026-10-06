---
title: What an orchestrator adds
version: 1
---

The three edges of the last two sections have one thing in common: **each is a decision that a
person makes on one machine and that nothing makes across several.** Where should a second copy
run? Which copy gets this request? Is the new one ready yet? Is there still a shop at all, now that
the laptop is gone? An orchestrator is a program that makes those decisions continuously, for a
group of machines treated as one.

## Desired state, and a loop that keeps checking it

The shape underneath all of Kubernetes fits in one sentence. **You write down what should be true,
and a program compares that with what is true and acts on the difference, over and over.** Ana does
not say "start three containers". She says "there should be three copies of `shop:1.1`, reachable
under one name", and the cluster spends the rest of its life making that so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A loop of three steps around a box labelled desired state: observe what is running, compare it with what was written down, act on the difference, and back to observe. Beside it, the desired state for the shop: three copies of shop:1.1 under one name.\"><defs><marker id=\"loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"170\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">observe</text><text x=\"125.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what is running</text><rect x=\"250\" y=\"170\" width=\"170\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">compare</text><text x=\"335.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">with what was written</text><rect x=\"40\" y=\"170\" width=\"170\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">act</text><text x=\"125.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the difference</text><path d=\"M210 56 L335 56 L335 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-paper-dim)\"></path><path d=\"M250 196 L212 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-paper-dim)\"></path><path d=\"M125 170 L125 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-paper-dim)\"></path><rect x=\"480\" y=\"60\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">desired state</text><text x=\"580.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 copies of shop:1.1</text><text x=\"580.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one name: web</text><path d=\"M480 120 L424 190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#loop-ah-amber)\"></path><text x=\"232\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">never stops</text></svg>", "caption": "The loop never finishes: a copy that disappears is a difference, and the next turn closes it."}
```

The difference from Compose is not the file. `compose.yaml` is also a description of what should
run. The difference is that Compose reads it when somebody types `docker compose up` and then stops
looking, while the orchestrator never stops. A copy that disappears at three in the morning is a
difference between the description and the world, and closing it is the loop's job rather than the
on-call person's.

## Five things that follow from the loop

| what you need | on one machine with Compose | on a cluster |
|---|---|---|
| a copy that crashes comes back | the daemon's restart policy | the same, plus a replacement made by the control plane (lesson 10) |
| a machine that dies | everything on it is gone | its copies are started again on the machines left (lesson 32) |
| several copies on one address | a proxy you add and configure | a Service in front of them, kept up to date (lesson 15) |
| an update without a gap | stop, then start: 12 of 300 refused | start, wait for ready, then stop (lesson 35) |
| more copies under load | a number you edit | a controller that changes it (lesson 33) |

Each line names the lesson where it happens on a real cluster, so none of them has to be taken on
trust here.

## What it costs

**None of this is free, and the price is paid before the first request.** A cluster is several
machines, a control plane that has to stay up for anything to change, a network between the
copies, and a vocabulary of objects you now have to learn, starting in lesson 2. For one service on
one machine, with an update a week and a team of one, that is a lot to carry in exchange for twelve
requests. Lesson 3 asks when Kubernetes is overkill, and lesson 46 does the arithmetic of running
one yourself.
