---
title: Isolation
version: 1
---

Least privilege says what an account may touch. **Isolation** goes one step further: it puts a
program somewhere it cannot even see what it is not allowed to touch. A program that cannot see the
salaries file cannot be tricked into reading it, and one that cannot see the network cannot send
anything over it.

Isolation comes in strengths, and each step up costs more and contains more:

```schooling-figure
{"svg": "<svg id=\"sf-isolation\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Six levels of isolation as a rising staircase, from weakest to strongest: separate accounts, sandbox, container, virtual machine, separate hardware, air gap. An arrow along the bottom says each step contains more and costs more.\"><defs><marker id=\"sf-isolation-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"130\" width=\"105\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">separate</text><text x=\"72\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">accounts</text><rect x=\"135\" y=\"108\" width=\"105\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"187\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sandbox</text><rect x=\"250\" y=\"86\" width=\"105\" height=\"94\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"302\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">container</text><rect x=\"365\" y=\"64\" width=\"105\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"417\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">virtual</text><text x=\"417\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">machine</text><rect x=\"480\" y=\"42\" width=\"105\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">separate</text><text x=\"532\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hardware</text><rect x=\"595\" y=\"20\" width=\"105\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"647\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">air gap</text><path d=\"M20 200 L700 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isolation-ah-paper-dim)\"></path><text x=\"20\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">weaker, cheaper</text><text x=\"700\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stronger, costlier</text></svg>", "caption": "Each step up hides more of the system from the program, and costs more to run."}
```

| level | what separates the two sides | an example |
|---|---|---|
| **separate accounts** | the operating system's permissions | the portal as `shop`, bruno as `bruno`, on the same machine |
| **sandbox** | the program is started with most of the system hidden from it | a browser tab that cannot read your files |
| **container** | its own view of files, processes and network, sharing the host's kernel | the portal in a container that sees only its own folder |
| **virtual machine** | its own operating system and kernel, on virtual hardware | the portal on its own virtual server |
| **separate hardware** | different physical machines | the database on a server of its own |
| **air gap** | no network connection at all | an offline backup disk in a drawer |

Two lessons hide in that table.

**Each level fails differently.** A container shares the kernel with its host, so a flaw in the
kernel can let a program escape it; a virtual machine has its own kernel, so the same flaw stays
inside. That is why the choice is about what the program could do if it went wrong, not only about
convenience. `virtualization` and `docker` cover the two middle rows properly; here the point is
that they are steps on one ladder.

**Isolation was already in this course.** The lab itself is isolation: each machine is a separate
network namespace, so `www` cannot see the office's traffic except through the firewall. The DMZ of
lesson 5 is isolation at the scale of a network. The offline backup that saved the shop R$ 2,100 a
year in lesson 3 is an air gap, the strongest level, chosen exactly because ransomware on the
server cannot reach what the server cannot see.

### When to isolate

The more a program is exposed and the less it is trusted, the more isolation it deserves. A program
that reads input from strangers, such as the shop's public pages, a file uploaded by a customer or
an attachment in an email, sits high on both counts. Opening an unknown attachment in a sandbox, or
processing uploads in a container that holds nothing else, means the worst it can do is damage the
sandbox. `defense-hardening` lesson 12 shows that practice for suspicious files.
