---
title: When one agent is enough
version: 1
---

Section 05 measured the split at three times the requests for the same answer. Section 08 showed a fact lost at the boundary. Neither result means multi-agent systems are wrong; they mean a split has to pay for itself. A short checklist, in the order the questions usually settle it:

**Does one agent's context get too large?** If a single agent's conversation stays well within its window and its cost per request is acceptable, the first reason to split is absent. If long sub-tasks flood the conversation with results the later steps do not need, specialists with their own conversations are the cure.

**Are there too many tools for one agent to choose well?** Two or three tools, no. Twenty, spanning unrelated jobs, probably: a model picking from a long list makes more wrong picks, and the descriptions start to overlap.

**Do the tools need different privileges?** This one settles it on its own. An agent that reads customers' messages, web pages or third-party documents should not be the agent that can refund, email or delete. Splitting them, so that the reader cannot act and the actor never reads untrusted text, is a security design rather than an efficiency one, and lesson 17 builds it.

**Can the parts run in parallel, and are they slow?** Then an orchestrator waiting for the slowest worker beats one agent doing them in turn.

**Does a conversation belong to one owner?** Then a handoff, not an orchestrator: route it once and let the owner answer.

If none of these holds, keep one agent and spend the effort on its tools, its limits and its tests. **Most production agents are one loop with a handful of good tools**, and the ones that are not got there by measuring a single agent first and finding exactly which of these questions it failed.
