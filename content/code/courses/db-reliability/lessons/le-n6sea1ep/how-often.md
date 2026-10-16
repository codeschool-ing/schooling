---
title: How often, and the arithmetic of retention
version: 1
---

"Regularly" is not a schedule. The interval between drills is a number with a consequence you can
calculate: **it is the longest a broken backup can go unnoticed.** A drill every month means that a
backup which stopped working the day after a drill is discovered up to a month later.

That interval has to fit inside another one. When the drill finds a broken backup, you need a good
one older than the breakage to fall back on, and you have exactly as many as retention keeps:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A six-week timeline with a full backup at the start of every week. Backups break early in week 3. A monthly drill runs at the end of week 6 and finds the failure. The retention window, the last two full backups, covers only weeks 5 and 6, so every backup still kept was taken after the break.\"><defs><marker id=\"l7w-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M30 90 L700 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7w-wi)\"></path><circle cx=\"40\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"94\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week 1</text><circle cx=\"148\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"202\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week 2</text><circle cx=\"256\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"310\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week 3</text><circle cx=\"364\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"418\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week 4</text><circle cx=\"472\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"526\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week 5</text><circle cx=\"580\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"634\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">week 6</text><text x=\"40\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">weekly full backups</text><path d=\"M270 40 L270 84\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"270\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">backups break</text><path d=\"M686 40 L686 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">monthly drill</text><text x=\"640\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">finds it</text><path d=\"M472 140 L472 148 L700 148 L700 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"586\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">retention: the last two fulls</text><rect x=\"330\" y=\"182\" width=\"370\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"515\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">every backup kept was taken after the break</text></svg>", "caption": "A monthly drill against two weeks of retention. By the time the drill finds the failure, every backup from before it has expired, and there is nothing good left to restore."}
```

With two full backups kept and a full taken weekly, retention reaches back about two weeks. A
monthly drill finds a failure up to a month old, by which time **every backup taken before the
failure has expired**, and the drill's discovery is that you have had no restorable backup for
weeks and still have none. The rule is simple and is broken often: **the drill interval must be
shorter than the retention window**, with room to spare for the time it takes to notice the result.

## A schedule worth having

| when | what |
|---|---|
| **every week, unattended** | the script in this lesson, or its equivalent, against the newest backup |
| **after every change to backups** | a new setting, a new repository, an upgrade of PostgreSQL or of the tool |
| **every quarter, by a person** | a full rehearsal by somebody who did not set it up, following the written procedure (lessons 23 and 24) |
| **when the data grows** | a drill on the larger database, to re-measure the time |

The weekly drill catches broken backups. The quarterly one catches what the script cannot: a
procedure that only works in the head of the person who wrote it, a step that needs a password
nobody else has, a restore server that no longer has room for the data.

A drill costs a second server for as long as it runs, and that is the reason most teams give for not
running one. In this lab the second server is free. On a real system it is a temporary machine that
lives for an hour, which is a small bill next to the one for finding out on the day.
