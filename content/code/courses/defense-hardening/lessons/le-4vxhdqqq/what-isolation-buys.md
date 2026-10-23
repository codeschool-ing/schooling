---
title: What isolation buys
version: 1
---

**A sandbox runs a program in a smaller world than the machine it is on.** Inside it, the program
sees fewer files, fewer devices, less of the network and fewer of the system's powers, and what
it does there cannot reach what it was not given. It is the answer to a question every defender
meets weekly: a file arrived that somebody needs to open, and nobody can say whether it is safe.

The common picture is a box with a lid: either the program is inside, and safe, or it is not. In
practice there are layers of boxes, and they differ in how thick the walls are and in what they
cost to build:

| layer | what separates the program | wall | cost |
|---|---|---|---|
| **a confined process** | namespaces and filters on one kernel: its own view of the files, the network, the system calls | thin: one bug in the shared kernel crosses it | none: it starts in milliseconds, and systemd builds it for every service you ask |
| **a container** | the same mechanisms, applied to a whole system | the same kernel, so the same thickness | small: this lab is seven of them |
| **a virtual machine** | a hypervisor and a kernel of its own | thick: the program would need a flaw in the hypervisor | real: a second operating system, its memory and its disk |
| **another computer** | nothing shared at all | the thickest | a machine you can afford to throw away |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-layers\" aria-label=\"Four layers of isolation drawn side by side, each box's border as thick as its wall. A confined process shares the kernel with everything else. A container also shares that kernel. A virtual machine has its own kernel on top of a hypervisor. Another computer shares nothing. Cost grows from left to right along with the strength of the wall.\"><defs><marker id=\"l12-layers-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">confined process</text><text x=\"105.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shared kernel</text><rect x=\"202.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"277.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">container</text><text x=\"277.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shared kernel</text><rect x=\"374.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"3.0\"></rect><text x=\"449.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">virtual machine</text><text x=\"449.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own kernel</text><rect x=\"546.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"4.6\"></rect><text x=\"621.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">another computer</text><text x=\"621.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing shared</text><path d=\"M40.0 210.0 L680.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-layers-dh-ah-paper-dim)\"></path><text x=\"40.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thinner wall, nearly free</text><text x=\"680.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thicker wall, real cost</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the line drawn by each wall is its thickness</text></svg>", "caption": "Choose the layer by what you fear: a flaw in a trusted program, or a file built to escape."}
```

**The right layer is decided by what you are afraid of.** A program you trust that should do one
job, the portal, belongs in a confined process, so that a flaw in it reaches as little as possible.
A file of unknown origin, which might have been written to escape whatever holds it, belongs in a
virtual machine or on a machine set aside for it, and lesson 19 adds the services that run such
files on somebody else's computer. This lesson works at the thin end, which is the one most
servers use and fewest configure.

Every wall in this lesson is built from what systemd and the kernel already offer on `web`. Start
the lab with the machines this lesson uses:

```sh
sudo bash hostlab.sh up web trap
```

`trap` is there only to be an address the suspicious file can try to reach.
