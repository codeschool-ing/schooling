---
title: A copy of the files, and why `cp` is not one
version: 1
---

Lesson 2's dump rebuilt the database from instructions. A **physical backup** skips the
instructions and copies what the server keeps on disk: the data directory, every file in it, byte
for byte. Restoring it means putting the files back and starting a server on them. No row is
inserted, no index is built, and that is why it is fast; it is also why it carries everything the
files carry, including what is wrong with them.

## The simple version, with the server stopped

The surest physical copy of a PostgreSQL server is the one taken while it is not running. Stop it,
copy the directory, start it again:

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ sudo cp -a /var/lib/postgresql/16/main cold-copy
ana@vm:~$ sudo pg_ctlcluster 16 main start
ana@vm:~$ sudo du -sh cold-copy
991M	cold-copy
ana@vm:~$ sudo du -sh cold-copy/pg_wal
689M	cold-copy/pg_wal
```

That copy is perfect, and it cost an outage for as long as `cp` took. Notice the second number:
of 991 MB, **689 MB is `pg_wal`**, the write-ahead log the server keeps for its own recovery,
swollen here by the three million orders lesson 2 loaded into `bigshop`. A copy of the directory
takes all of it, needed or not.

A **cold backup** like this is a real technique, and the right one for a database that can afford
to stop every night. Most cannot, which is the whole problem.

## Why the same `cp` on a running server is a trap

Copying the directory of a running server looks like it should work, and it often appears to.
`cp` reads the files one after another, over seconds or minutes, while the server keeps changing
them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline left to right. cp reads four files, A to D, one after another. While it does, the server keeps writing: one transaction writes to file A after A has been copied and to file D before D is copied, so the copy holds that transaction's change to D and not its change to A.\"><defs><marker id=\"l3t-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"l3t-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cp reads</text><rect x=\"130\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file A</text><rect x=\"270\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file B</text><rect x=\"410\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file C</text><rect x=\"550\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file D</text><path d=\"M130 80 L700 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3t-pa)\"></path><text x=\"690\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the server writes</text><circle cx=\"300\" cy=\"130\" r=\"6\" fill=\"var(--amber)\"></circle><circle cx=\"470\" cy=\"130\" r=\"6\" fill=\"var(--amber)\"></circle><path d=\"M300 124 L190 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3t-am)\" stroke-dasharray=\"5 4\"></path><path d=\"M470 124 L580 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3t-am)\" stroke-dasharray=\"5 4\"></path><path d=\"M306 130 L464 130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"385\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one transaction writes A and D</text><rect x=\"220\" y=\"176\" width=\"330\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the copy has its D, not its A</text></svg>", "caption": "Copying a running server's files one after another. Each file is copied at a different moment, so a transaction that touched two of them can be half in the copy, and nothing in the copy says so."}
```

The copy holds each file **as it was at a different moment**. A transaction that wrote to a file
already copied and to one not yet copied is half in the copy. An index can point at rows the copy
does not have. Started, a server on that copy usually runs the crash recovery it would run after a
power cut, finds nothing it recognises as wrong, and opens. Nothing reports a problem. The damage
surfaces later, as a query that returns a row it should not, or a constraint that no longer holds.

What a crash recovery needs to repair a copy like that is **every change written from before the
first file was read until after the last one was**. The server writes exactly that, to the
write-ahead log; what `cp` lacks is a way to say "start keeping it from here, and tell me where
here is". PostgreSQL has that conversation built in, and the next section has it.
