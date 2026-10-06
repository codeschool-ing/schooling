---
title: Up or out
version: 1
---

A database that is too slow, or too full, has two ways to grow.

**Vertical scaling, or scaling up**: a bigger machine. More cores to work in parallel, more memory to
hold the working set, faster disks. The software does not change, the data does not move, and every
query that worked before works the same way, faster.

**Horizontal scaling, or scaling out**: more machines. The data is divided between them, each
machine works on its share, and the results are combined. Adding capacity means adding a machine,
and in principle there is no limit to how many.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two ways to grow. On the left, scaling up: one machine replaced by a bigger one with more cores and memory, the data unmoved. On the right, scaling out: four machines, each holding a quarter of the data and working on its own quarter, with a coordinator combining their answers.\"><defs><marker id=\"ah-up-or-out\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">up: a bigger machine</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">out: more machines</text><line x1=\"350\" y1=\"40\" x2=\"350\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line><rect x=\"30\" y=\"110\" width=\"90\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 cores</text><text x=\"75\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 GB</text><line x1=\"125\" y1=\"145\" x2=\"175\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-up-or-out)\"></line><rect x=\"180\" y=\"60\" width=\"140\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">64 cores</text><text x=\"250\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">512 GB</text><text x=\"250\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">all the data</text><rect x=\"470\" y=\"50\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">coordinator</text><line x1=\"530\" y1=\"86\" x2=\"410\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"375\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"410\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text><line x1=\"530\" y1=\"86\" x2=\"492\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"457\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"492\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"492\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text><line x1=\"530\" y1=\"86\" x2=\"574\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"539\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"574\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text><line x1=\"530\" y1=\"86\" x2=\"656\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"621\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"656\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"656\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text></svg>", "caption": "Scaling up replaces the machine; scaling out divides the data between machines."}
```

The lab is one machine:

```
ana@lab:~/wh$ nproc
4
ana@lab:~/wh$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16094        1359       11197         348        4182       14734
```

Four cores and 16 GB of memory. Ana's warehouse, all of it, is a file of about 46 MB. **For a business this
size, scaling up is not a decision anybody needs to make yet**, and that is the most common situation
there is: a single modern server holds hundreds of gigabytes in memory and has dozens of cores, which
is more than most companies' entire warehouse.

Lesson 1 promised a number for "small". Here it is, as a rule of thumb rather than a law: **if the data
a typical query reads fits in one machine's memory, one machine is the simpler answer.** The rest of
this lesson is what changes when it does not.
