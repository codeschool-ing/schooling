---
title: Hybrid, the shape real networks have
version: 1
---

Ask what topology a company's network has and the honest answer is **all of them, each in its own
place**. A real network is a **hybrid**: shapes joined together, each chosen where its trade pays
off. The previous sections give you the trades:

| shape | one failure takes down | cables | where it pays |
|---|---|---|---|
| star | one machine, or everyone if it is the centre | one per machine | many cheap devices |
| ring | nothing, until a second cut | one per device | a loop of fibre round a city |
| full mesh | nothing, until several cuts | n × (n − 1) / 2 | a few devices that everybody depends on |

Read that table from the desks inwards and a typical company network draws itself.

- **The floors are stars.** Each PC, printer and phone has one cable to an access switch in the
  floor's cupboard. There are hundreds of them, each one matters to one person, and a star is the
  cheapest shape that makes a broken cable one person's problem.
- **The building is a star of stars**, sometimes called an *extended star* or a *tree*: every floor's
  switch has a cable up to a switch or router that joins the floors.
- **The core is meshed.** The two or three devices in the middle carry everybody's traffic, so each
  is cabled to each of the others, or at least to two of them. A full mesh of three costs three
  cables, and any one cable can fail without cutting a router off.
- **Between cities, it is whatever the provider sells**, and very often a ring of fibre in the
  metropolitan network, with the company's sites hung from it as stars.

## The lab is already a hybrid

This course's `office` scenario looks like a star, and the switch sw1 is one. But follow the
drawing at the top of `lab.sh` out of the office: sw1 hangs off r1, r1 is cabled to the provider
`isp`, `isp` to a load balancer `lb`, and `lb` is the centre of a second, small star with the two
web servers `web1` and `web2` on it.

```
pc1 pc2 pc3 srv --- sw1 --- r1 === isp --- lb --- web1, web2
```

A star, a chain of single links, and another star. **Every single link in that chain is a single
point of failure** for the office's view of the web servers: lose the r1–isp cable and the whole
office is cut off at once, exactly like the switched-off centre of the star experiment.

## Choosing, before lesson 6 makes it a method

The pattern in all of this is one question asked device by device: **if this fails, how many people
notice?** A desk PC fails for one person, and one cable is enough. A floor switch fails for the
floor, and many companies keep a spare in the cupboard rather than a second cable to every desk. A
core router fails for everyone, and that is where a second router and a mesh of cables are cheap
compared with the alternative.

Lesson 6 turns that question into the vocabulary of network design — hierarchy, redundancy, single
points of failure — and builds a campus whose layers are exactly the hybrid above: stars at the
bottom, a mesh at the top.
