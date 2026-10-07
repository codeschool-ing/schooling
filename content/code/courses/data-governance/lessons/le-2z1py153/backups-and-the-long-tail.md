---
title: Backups, logs and the long tail
version: 1
---

The purge deleted 9,826 prescriptions from `health.prescriptions`. They are still in at least three
other places, and a retention schedule that ignores them is a schedule for one copy.

## Backups

Last week's backup holds every row the purge removed. That is what a backup is for, and it is also a
copy of expired data. The defensible practice, the same as for an erasure in lesson 7:

- **backups have their own retention**, written in the schedule: 35 days of daily backups, say, and
  nothing older. After that window, the purged data is gone everywhere;
- **a restore re-applies the purge.** Restoring last week's backup brings back last week's expired
  rows, so the restore procedure runs the purge before anybody uses the restored database;
- **point-in-time recovery** keeps the write-ahead log for its window; its retention is the window,
  and it counts as a backup.

## Logs

The server log, the application log and the load balancer's log hold fragments of personal data: an
e-mail in an error message, a CPF in a failed query, an IP address. Lesson 4 showed one log done
well: OpenBao's audit device writes a keyed hash (`hmac-sha256:...`) of each sensitive value instead
of the value, so the log can prove which token was used without holding the token. Most logs are not
built like that, and so they get the shortest retention of anything: days or weeks, not years.

## Copies nobody listed

Lesson 9's lineage map ended with the edges no tool sees: an analyst's extract, a CSV sent by e-mail, a
test database. Retention reaches them only if the map does. A purge that deletes 950 orders from the
database and leaves the 2020 sales extract on a shared drive has made the database compliant and the
company no more so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l10-copies\" aria-label=\"Where an expired row lives. The purge deletes it from the database. Backups keep it until their own retention ends, and a restore must run the purge again. Logs hold fragments of it for days or weeks. Extracts and test copies keep it until somebody finds them, which only a lineage map makes possible.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">expired row</text><text x=\"85.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2020 order</text><rect x=\"230.0\" y=\"20.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">database</text><text x=\"450.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the purge deletes it</text><path d=\"M150.0 110.0 L228.0 39.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"68.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">backups</text><text x=\"450.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">until their window ends</text><path d=\"M150.0 110.0 L228.0 87.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"116.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">logs</text><text x=\"450.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fragments, days or weeks</text><path d=\"M150.0 110.0 L228.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"164.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">extracts, test copies</text><text x=\"450.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">until somebody finds them</text><path d=\"M150.0 110.0 L228.0 183.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path></svg>", "caption": "A retention schedule covers every copy, or it covers one."}
```
