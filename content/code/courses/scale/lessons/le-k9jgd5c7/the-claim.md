---
title: What the CAP theorem actually says
version: 1
---

The CAP theorem is usually quoted as "consistency, availability, partition tolerance: pick two".
**That version is wrong in a way that matters**, because it suggests a system can decide to go
without partition tolerance, as if network failures were optional. They are not. A network
between two machines will at some point lose packets, drop a connection, or put a switch between
them that stops forwarding, and no design choice prevents it.

What the theorem says, as Eric Brewer stated it in 2000 and Seth Gilbert and Nancy Lynch proved it
in 2002, is narrower and more useful:

> **When the network between the copies of some data is partitioned, a system must choose, for
> each request, between giving an answer that may be stale and giving no answer at all.**

Three words carry the weight, and each has a precise meaning:

- **Consistency**, in CAP, means **linearizability**: every read sees the most recent completed
  write, as if there were a single copy of the data. It is a much stronger promise than the C of
  ACID, which is about a transaction keeping a database's rules.
- **Availability** means every request to a copy that is running gets a non-error answer,
  eventually. Not a fast answer; just an answer that is not "I cannot tell you".
- **Partition** means some copies cannot talk to some others, while both sides can still be
  reached by some clients.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A partition. Two copies of the data, A on the left and B on the right, with the link between them cut. A client on the left writes to A; a client on the right reads from B. B has two choices: answer with its own copy, which may miss the write made on A, and stay available; or refuse until it can reach A, and stay consistent.\"><rect x=\"60\" y=\"90\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">copy A</text><text x=\"130\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sold = 1</text><rect x=\"520\" y=\"90\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">copy B</text><text x=\"590\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sold = 0</text><path d=\"M200 120 L330 120\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M390 120 L520 120\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M345 100 L375 140\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\"></path><path d=\"M375 100 L345 140\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\"></path><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">partition</text><rect x=\"70\" y=\"200\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">client: sells</text><path d=\"M130 200 L130 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M130 152 L133.0 158.3 L127.0 158.3 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"530\" y=\"200\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">client: reads</text><path d=\"M590 200 L590 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M590 152 L593.0 158.3 L587.0 158.3 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"590\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">B answers sold = 0: available</text><text x=\"590\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">B refuses: consistent</text></svg>", "caption": "During a partition, a copy that cannot reach the others answers with what it has, or does not answer."}
```

During a partition, a copy that receives a request has two options. It can **answer with what it
has**, which may miss writes made on the other side: available, not consistent. Or it can **refuse
until it hears from the other side**: consistent, not available. There is no third option, because
the information it would need to be both is on the other side of the partition.

## What it does not say

- **It says nothing about a healthy network.** Without a partition, a system can be consistent
  and available at once, and most of the time it is. Section 05 is about the cost that remains
  even then.
- **It is not a property of a database.** It is a choice per operation. The box office can refuse
  to sell during a partition and still show its pages from a replica, and that is exactly what
  the next two sections do.
- **"Choosing availability" does not mean wrong answers.** It means answers that may be out of
  date, and a plan for what happens when the two sides meet again. Sections 07 to 09 are that plan.

`architecture` lesson 8 placed CAP among the patterns. Here you will cause a partition on purpose,
on the replication you built in lesson 2, and watch each choice happen.
