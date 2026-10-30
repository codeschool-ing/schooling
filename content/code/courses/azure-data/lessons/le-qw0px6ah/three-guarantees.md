---
title: At most, at least, exactly: one question about a crash
version: 1
---

**A delivery guarantee is the answer to one question: when a reader crashes, what happens to the
event it was handling?** A reader of an event hub does two things with every event, in some order:
it does the work, adding a payment to a total or writing a row, and it records how far it got, the
checkpoint of lesson 22. A crash between the two is what the guarantee is about, and the order of
the two steps is what decides it.

**Checkpoint first, then the work, is at most once.** If the process dies after the checkpoint and
before the work, the restarted reader starts after the checkpoint, and the event is never handled.
Nothing is ever done twice and something is sometimes never done.

**The work first, then the checkpoint, is at least once.** If the process dies after the work and
before the checkpoint, the restarted reader starts from the previous checkpoint and does the work
again. Nothing is ever lost and something is sometimes done twice. `checkpointed.py` in lesson 22
called `update_checkpoint` after handling the event, and so does every example Microsoft publishes
for these libraries: at least once is the default.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two orders of the same two steps, with a crash between them. Top, at least once: do the work, then the crash, then the checkpoint that never happened; the restart begins at the old checkpoint and the work is done again. Bottom, at most once: checkpoint first, then the crash, then the work that never happened; the restart begins after the new checkpoint and the work is never done.\" data-fig=\"l24-order\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">at least once</text><rect x=\"170\" y=\"30\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">do the work</text><line x1=\"322\" y1=\"46\" x2=\"366.0\" y2=\"46.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"372,46 366.0,49.0 366.0,43.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"374\" y=\"30\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"419\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crash</text><line x1=\"466\" y1=\"46\" x2=\"510.0\" y2=\"46.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"516,46 510.0,49.0 510.0,43.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"518\" y=\"30\" width=\"150\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"593\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checkpoint</text><text x=\"170\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">restart from the old checkpoint: the work is done again</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">at most once</text><rect x=\"170\" y=\"140\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkpoint</text><line x1=\"322\" y1=\"156\" x2=\"366.0\" y2=\"156.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"372,156 366.0,159.0 366.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"374\" y=\"140\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"419\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crash</text><line x1=\"466\" y1=\"156\" x2=\"510.0\" y2=\"156.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"516,156 510.0,159.0 510.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"518\" y=\"140\" width=\"150\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"593\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do the work</text><text x=\"170\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">restart after the new checkpoint: the work is never done</text></svg>", "caption": "The same crash in two places: after the work it repeats an event, after the checkpoint it loses one."}
```

**Exactly once is not a third order.** There is no way to arrange two separate writes, one to the
sink and one to the checkpoint store, so that a crash between them leaves both or neither. What
gets called exactly once is one of two things: the work and the checkpoint written in one atomic
step to the same place, or at-least-once delivery into a sink where doing the work twice changes
nothing. The last two sections of this lesson are those two.

## What the Azure services promise

**This part is from Microsoft's documentation and was not run.** Each service states its guarantee,
and none of them says exactly once from end to end:

| service | what its documentation promises |
|---|---|
| Event Hubs | at least once: an event a reader has not checkpointed is delivered again |
| Stream Analytics | exactly-once processing inside the job, and at-least-once delivery to its outputs |
| the Event Hubs trigger of Azure Functions | at least once: a function that fails or times out sees the batch again |

**At least once is the default everywhere, because it is the only one of the three that loses
nothing.** At most once is fine for a dashboard of approximate counts and wrong for anything that
is money. What at least once costs is that every reader must survive seeing an event twice, and the
next section counts the ways that happens.
