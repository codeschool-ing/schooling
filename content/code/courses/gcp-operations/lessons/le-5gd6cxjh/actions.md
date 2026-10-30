---
title: Which action, on which budget
version: 1
---

**An action wired to a budget runs without a person, on numbers that lag, so the question is not what it can do but
what it can safely do while nobody is looking.** The function of the last section published three decisions and
carried out none of them. This section is about the consumers of `ops-actions`, and nothing in it ran: stopping a
machine needs Compute Engine, and no emulator answers for it.

## Three actions, from mild to drastic

| action | what it does | reversible by | safe on |
|---|---|---|---|
| ticket or page | tells the person who can act, through lesson 14's routes | nothing to reverse | every budget |
| stop the sandbox's machines | stops the running Compute Engine instances in one project or folder; disks stay and keep costing | starting them again | a sandbox, never production |
| remove the billing account | detaches the project from billing, and every paid service in it stops | attaching it again, by hand | a project nobody depends on |

**The ticket and the page are what the shop's budget gets.** A budget on production that stopped production would turn
a cost problem into an outage that customers feel, and lesson 15 already has a name for that.

**Stopping machines is what the sandbox gets.** Google publishes a sample that does exactly this from a budget message:
when `costAmount` passes `budgetAmount`, it lists the instances in a zone and stops the ones running. Stopping is the
right degree of force for a sandbox: the work is paused rather than lost, the disks stay, and the owner restarts what
they still need. In the shop's version the consumer reads `ops-actions`, takes only `stop-sandbox`, and stops the
instances in projects under the sandbox folder.

**Removing the billing account is Google's other sample**, and the most drastic thing a budget can trigger. It sets
the project's billing account to empty, which stops everything paid in the project at once. It belongs on a project
that exists to experiment and that nobody would miss for a day, and nowhere else.

## What the consumer needs

- **Its own service account, with the narrowest role that does the job.** Stopping instances is one permission on
  Compute Engine; detaching billing is a billing role. Lesson 17's rule applies: no key file, the function runs as
  that identity.
- **A way to undo, written down.** The ticket that goes with `stop-sandbox` says which machines were stopped, so their
  owner knows what to start again.
- **A test with a message, before it is trusted.** A budget's first real crossing is the worst moment to learn the
  function's filter matches production too. Publishing a made-up message into a test topic, as the last section did,
  is how that is found on a Tuesday afternoon instead.

**An action does not replace the person; it buys time for them.** The sandbox stopped at 102% still has a person whose
experiment cost more than planned, and the ticket is what reaches them.
