---
title: Timelines: two histories after one point
version: 1
---

The restored server now holds a history that never happened on the live one: the five orders, and
then, instead of a `DELETE`, whatever is written to it next. The live server holds the other history:
the `DELETE`, and the three orders after it. Both continue from the same moment, and both will keep
writing log. That moment is a fork, and PostgreSQL gives every branch its own number:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A horizontal line for timeline 1, the live server: a full backup, transactions 737 to 741 for five orders, transaction 742 the DELETE, then 743 to 745 for three more orders. Just before 742 a second line branches downwards: timeline 2, the restored server, which has the five orders and no DELETE and carries on with its own writes. A note at the fork reads 0/415E8F0, before transaction 742.\"><defs><marker id=\"l6f-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l6f-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">timeline 1: the live server</text><path d=\"M110 70 L392 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M468 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6f-wi)\"></path><rect x=\"20\" y=\"52\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">full backup</text><circle cx=\"140\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"140\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">737</text><circle cx=\"180\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"180\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">738</text><circle cx=\"220\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"220\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">739</text><circle cx=\"260\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"260\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">740</text><circle cx=\"300\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"300\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">741</text><text x=\"220\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">five orders</text><rect x=\"392\" y=\"52\" width=\"76\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">742</text><text x=\"430\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">DELETE</text><circle cx=\"510\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"510\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">743</text><circle cx=\"550\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"550\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">744</text><circle cx=\"590\" cy=\"70\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"590\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">745</text><text x=\"550\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three orders</text><path d=\"M360 70 L360 190 L700 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6f-ph)\"></path><text x=\"380\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">timeline 2: the restored server</text><text x=\"600\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">new writes</text><rect x=\"150\" y=\"150\" width=\"190\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"245\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fork at 0/415E8F0,</text><text x=\"245\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">before transaction 742</text><path d=\"M340 173 L354 173\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "The restore stopped before transaction 742 and became timeline 2. The live server carries on along timeline 1 with the DELETE and the three orders after it; the history file records where the two parted."}
```

Every recovery that stops before the end of the log starts a new **timeline**. The segment names
carry it, in their first eight digits:

```
ana@vm:~$ sudo ls /var/lib/postgresql/16/restore/pg_wal
000000010000000000000004
00000002.history
000000020000000000000004
000000020000000000000005
archive_status
ana@vm:~$ sudo cat /var/lib/postgresql/16/restore/pg_wal/00000002.history
1	0/415E8F0	before transaction 742
```

`000000010000000000000004` is timeline 1, the history the copy replayed. `000000020000000000000004`
and `…05` are timeline 2, written by the restored server since it was promoted: the same position
in the log, a different history. And `00000002.history` is the record of the fork, one line: **timeline
2 left timeline 1 at `0/415E8F0`, before transaction 742.**

Timelines are what keep two histories from being confused, and they matter as soon as there is more
than one recovery:

- **A segment is never overwritten by another history.** If the restored server archived into the
  same repository, its segments would carry timeline 2 in their names and could not replace the live
  server's timeline 1 segments. The archive-mode warning in lesson 5 is about the cases where
  numbers alone do not save you.
- **A recovery can choose its branch.** `recovery_target_timeline` defaults to `latest`: follow the
  history files to the newest branch. A second recovery of the same backup would follow timeline 2
  unless told otherwise, which is what you want after a deliberate restore and not always after a
  rehearsal.
- **A history file is small and essential.** Recovery reads it to know where each branch left its
  parent, and a restore that cannot find one fails. pgBackRest archives them with the segments.

Lesson 15 meets timelines again, from the other side: a replica that is promoted after a failure
starts a new timeline in exactly this way, and the old primary, still on timeline 1, can no longer
follow it.
