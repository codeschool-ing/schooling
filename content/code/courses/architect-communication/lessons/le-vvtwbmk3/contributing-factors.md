---
title: Contributing factors, not a root cause
version: 1
---

**Incidents in complex systems rarely have one cause. They happen when several weaknesses, each
harmless on its own, line up on the same evening.** Looking for "the root cause" finds one of them,
usually the last one, usually a person, and leaves the rest in place for next time.

## The holes that lined up

James Reason, studying accidents in hospitals, aviation and industry, described this with a picture now
known as the Swiss cheese model: each defence is a slice with holes in it, and an accident happens when
the holes in several slices line up. On 6 March, six holes lined up:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Six slices standing in a row, each with a hole: the runbook, the job limit, the database limit, the alerts, the first guess and the known risk. A line from the backfill at 19:05 passes through all six holes to checkout down.\"><defs><marker id=\"cheese-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"170\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"179\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"187\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runbook</text><rect x=\"260\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"269\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"277\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job limit</text><rect x=\"350\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"359\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"367\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">database limit</text><rect x=\"440\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"449\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"457\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alerts</text><rect x=\"530\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"539\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"547\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first guess</text><rect x=\"620\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"629\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"637\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">known risk</text><path d=\"M20 115 L700 115\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\" marker-end=\"url(#cheese-ah)\"></path><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">backfill at 19:05</text><text x=\"700\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">checkout down</text><text x=\"20\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">close any one hole and the line stops there</text></svg>", "caption": "Reason's Swiss cheese model, applied to 6 March. Each defence had a hole that was harmless alone; the evening was the one when they lined up."}
```

1. **The runbook** said when to run the backfill but not when not to.
2. **The job** had no limit on how many connections it could open.
3. **The database** had no per-service limit, so one client could take every connection.
4. **The alerts** measured checkout's errors, not the database's connections, so the cause was invisible
   for the first seven minutes.
5. **The usual suspect**: checkout deploys had caused most past incidents, so the first twelve minutes
   went there.
6. **The known risk**: lesson 4's accepted risk of the database running out of connections at peak,
   pending April's replica work. The system was already running close to the edge.

Remove any one hole and the evening is different. With a per-service limit, the backfill is slow and
checkout is fine. With a connection alert, the cause is seen at 19:09. With a line in the runbook, the
job runs at 23:00.

## Why "five whys" is not enough

The *five whys*, asking "why?" repeatedly until reaching a cause, came from Toyota's production system
and is still widely taught. It is useful for getting past the first answer. Its weakness, pointed out by
safety researchers, is that it follows **one chain**, and the chain chosen depends on who asks:

> Why did checkout fail? The database ran out of connections. Why? The backfill took them. Why? It was
> run at peak. Why? Paulo ran it. Why? He didn't check.

Five whys, one chain, and it ends at a person. Asked differently, the second "why?" could have been "why
could one job take every connection?", which leads to the database limit, a hole that would also have
caught the next job nobody has written yet. **Ask "why?" along every branch, and stop at the system, not
at the person.**

## A finding is a sentence about the system

Each contributing factor in the write-up is phrased as a property of the system: "the database has no
per-service connection limit", not "nobody set a connection limit". The first invites a fix; the second
invites the question "who should have?", which is blame by another route.
