---
title: Versions and garbage collection
version: 1
---

**A write to a column that already has a value does not replace it; it adds a cell.** In a
relational table an `UPDATE` leaves one value behind. In Bigtable the old cell is still there under
its own timestamp, the new one sits above it, and a read returns every version unless it asks for
fewer. What removes the old ones is a **garbage collection policy** on the family, and until a
family has one, nothing is ever removed.

## Four districts

c-17 has moved house three times. Each write below carries its own timestamp after the `@`, in
**microseconds since 1970**, so the four moves land on four dates rather than on the second you
typed them:

```
ana@laptop:~/gcp$ cbt deleterow customers c-17
ana@laptop:~/gcp$ cbt set customers c-17 p:name=Ana@1788000000000000 p:district=Lapa@1788000000000000
ana@laptop:~/gcp$ cbt set customers c-17 p:district=Mooca@1790000000000000
ana@laptop:~/gcp$ cbt set customers c-17 p:district=Pinheiros@1792000000000000
ana@laptop:~/gcp$ cbt set customers c-17 p:district=Santana@1792100000000000
ana@laptop:~/gcp$ cbt lookup customers c-17
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:district"                             @ 2026/10/14-14:46:40.000000
    "Pinheiros"
  "p:district"                             @ 2026/09/21-11:13:20.000000
    "Mooca"
  "p:district"                             @ 2026/08/29-07:40:00.000000
    "Lapa"
  "p:name"                                 @ 2026/08/29-07:40:00.000000
    "Ana"

ana@laptop:~/gcp$ cbt lookup customers c-17 cells-per-column=1
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:name"                                 @ 2026/08/29-07:40:00.000000
    "Ana"
```

**One column, four cells, newest first.** `lookup` returned all of them because the family `p` has
no policy yet. `cells-per-column=1` is a filter: it asks for the latest cell of each column, and
that is how a program reads "the current district". The three older cells are still stored and
still on the bill; the filter only decided what came back.

**The timestamp is a number with a unit, and the unit is microseconds.** The same date in
milliseconds, `1788000000000`, is a value a thousand times smaller:

```
ana@laptop:~/gcp$ cbt set customers c-18 p:district=Lapa@1788000000000
ana@laptop:~/gcp$ cbt lookup customers c-18 columns=p:district
----------------------------------------
"c-18"
  "p:district"                             @ 1970/01/21-13:40:00.000000
    "Lapa"
```

**January 1970.** Nothing refused it, because any 64-bit number is a valid timestamp. A program
that writes milliseconds where microseconds belong stores every cell fifty-six years in the past,
and the policy of the next block deletes that kind of cell first. Bigtable's tables also keep time
to the millisecond, so a timestamp's last three digits are zero, as every one above is.

## A policy, and what it took with it

**Two rules exist, and they combine.** `maxversions=N` keeps the newest N cells of each column.
`maxage=D` deletes cells whose timestamp is older than D, measured from now. Joined with `or`, a
cell goes when either rule condemns it, which is a **union**; joined with `and`, only when both do,
an **intersection**. A family's policy is set on the table, and `cbt` prints it the way the API
describes it:

```
ana@laptop:~/gcp$ cbt setgcpolicy customers p maxage=30d or maxversions=2
ana@laptop:~/gcp$ cbt ls customers
Family Name	GC Policy				Value Type
-----------	---------				----------
o							{}
p		(age() > 30d || versions() > 2)		{}
ana@laptop:~/gcp$ cbt lookup customers c-17
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:district"                             @ 2026/10/14-14:46:40.000000
    "Pinheiros"
  "p:district"                             @ 2026/09/21-11:13:20.000000
    "Mooca"
  "p:district"                             @ 2026/08/29-07:40:00.000000
    "Lapa"
  "p:name"                                 @ 2026/08/29-07:40:00.000000
    "Ana"

ana@laptop:~/gcp$ sleep 10 && cbt lookup customers c-17
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/15-18:33:20.000000
    "Santana"
  "p:district"                             @ 2026/10/14-14:46:40.000000
    "Pinheiros"

ana@laptop:~/gcp$ cbt lookup customers c-18
----------------------------------------
"c-18"
  "o:o-10004"                              @ 2026/10/30-15:11:47.796000
    "4290"
  "o:o-10005"                              @ 2026/10/30-15:11:47.796000
    "1380"
  "p:name"                                 @ 2026/10/30-15:11:47.796000
    "Bruno"
```

**`(age() > 30d || versions() > 2)` reads as the condition for deletion**, not for keeping: a cell
older than thirty days, or beyond the second version, is garbage. The first lookup, straight after
the policy was set, still returned all five cells. The second, ten seconds later, returned two.

**Lapa and Mooca went for both reasons, and Ana's name went with them.** The district had four
versions, so the two oldest were beyond the second; they were also older than thirty days. But
`p:name` had one version, written on 29 August, and **an age rule is applied to every cell of the
family, the only version included**. Today is 30 October, so the name was 62 days old and was
deleted. The policy did exactly what it says. The design was wrong: data that must never expire
does not belong in a family with a `maxage`. c-18's district of January 1970 went at the same pass,
and Bruno's name is still there only because it was written today; in thirty days it goes too.

**The repair is a second family, because the family is where the policy lives.** A profile keeps
its name in a family with `maxversions=1` and nothing else, and keeps what is history, the
addresses or the clicks of the next section, in a family whose age rule matches how long Quitanda
means to keep them. Choosing families is choosing retention.

## Collected later, not at once

**Garbage collection runs in the background, and a read can return a cell the policy has already
condemned.** The emulator here collected within seconds, and the first lookup above shows the window
it left. Google's documentation describes Bigtable's collection as happening during compaction, on
a schedule of its own that can take up to a week. It says that a read must not rely on it: if a
program needs at most one version, it asks with a filter, as `cells-per-column=1` did. The bill
follows the same schedule. The pricing page says that expired versions are charged for until they
are collected, and so is deleted data until the table is compacted.

**Changing a policy is instant and its effect is not.** Tightening `maxversions` from 3 to 1 makes
the older cells garbage the moment the change lands, and they disappear from storage over the
following days. Loosening it does not bring back what was already collected. On an instance that
replicates between clusters, `cbt setgcpolicy` refuses to loosen a policy without `force`, because
the clusters may each have collected a different amount and would then disagree.
