---
title: Four questions before building one
version: 1
---

Before writing a loop, answer four questions about the task. They take five minutes, and each one has an answer that rules an agent out.

**1. Can the path be written down?** List the steps a person takes. If the list is the same every time, or branches on a few things you can name, it is a workflow: code the list, and call a model only where a step needs reading or writing. If the honest answer is "it depends on what we find", the task has the shape lesson 1 described.

**2. What does a wrong step cost, and can it be undone?** Reading the wrong article costs a request. Refunding the wrong order costs money and an apology. Section 06 sorts actions by how far back they can be taken; an agent that only reads can be given far more freedom than one that writes.

**3. Can the result be checked?** An agent's answer is only as good as somebody's ability to tell whether it is right. Code that compiles and passes its tests is checkable. A refund amount can be compared with the order. "Is this a good summary of the supplier's new terms?" needs a person, and if that person must read the sources anyway, the agent saved less than it seemed.

**4. Do the volume and the deadline allow it?** In section 05 the lab's agent spends 9.9 s of model time and 2551 input tokens on three messages, where the router spends 1.0 s and 130 tokens on four. For one research question a day that is irrelevant. For every message in a busy support queue, it is the bill and the queue.

| answer | points towards |
|---|---|
| the path is a fixed list | automation, or a workflow with model calls |
| the path branches on one reading of the input | a workflow with routing |
| the next step depends on the last result, and the result can be checked | an agent |
| a wrong step cannot be undone | an agent only behind a person's confirmation (lesson 17) |
| thousands of requests a day under a deadline | a workflow, with an agent for the cases it cannot route |

The last row is common in practice and worth stating plainly: **the two are not exclusive.** A router that handles nine messages in ten with fixed procedures, and passes the tenth to an agent or a person, gets most of the cost of a workflow and most of the reach of an agent.
