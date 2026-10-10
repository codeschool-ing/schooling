---
title: A measurement you can believe
version: 1
---

Every fix in this course is judged by a number, so the number has to mean something. `\timing`
gives you one per statement, and the mistake everybody makes with it at first is to believe the
first one.

## What `\timing` measures

The `Time:` line is measured by `psql`, on your side: from the moment it sent the statement to the
moment the whole answer had arrived. So it includes the server's work, the trip across the
connection and the time to receive the rows. On your virtual machine the trip is nothing, because
`psql` and the server are on the same computer. Between an application in one building and a
database in another, the trip is a large part of every short query — which is why the server's
own figure for the same query, which lesson 3 reads, is smaller than this one.

## The same query, three times

Restart the server, ask the operating system to drop what it has cached from the disk, open
`psql` and run one query three times:

```
ana@vm:~$ sudo systemctl restart postgresql
ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
ana@vm:~$ psql market
market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
  count  
---------
 1666667
(1 row)

Time: 434.619 ms

market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
  count  
---------
 1666667
(1 row)

Time: 166.557 ms

market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
  count  
---------
 1666667
(1 row)

Time: 207.896 ms
```

**435, 167, 208 milliseconds.** Three runs of one query, and the slowest took more than twice as
long as the fastest. Two different things are in those numbers.

The first run is slow because it is **cold**. The restart emptied PostgreSQL's own memory, and the
`drop_caches` line emptied the operating system's, so the 432 MB of `order_lines` came from the
disk. By the second run both had kept a copy. A cold run is real — it is what the first person to
ask after a restart gets — but it is not what the same query costs the thousandth time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Four boxes left to right: the disk, holding the whole 1334 MB database; the operating system&#x27;s cache, which uses whatever memory is free; PostgreSQL&#x27;s shared buffers, 128 MB; and the query. A page travels from left to right. The cold run, at 435 milliseconds, read from the disk; the warm runs, at 167 and 208, found the pages in memory.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Three places a page can be, slowest on the left</text><rect x=\"14\" y=\"44\" width=\"170\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"99.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">the disk</text><text x=\"99.0\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1334 MB</text><text x=\"99.0\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">the whole database</text><rect x=\"214\" y=\"44\" width=\"200\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"314.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">operating system's cache</text><text x=\"314.0\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">14 GB available on this computer</text><rect x=\"444\" y=\"44\" width=\"150\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"519.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">shared buffers</text><text x=\"519.0\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">128 MB</text><text x=\"519.0\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">PostgreSQL's own</text><rect x=\"624\" y=\"44\" width=\"82\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"665.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">the query</text><path d=\"M184 96 L214 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M214.0 96.0 L208.0 100.0 L208.0 92.0 Z\" fill=\"var(--wire)\"></path><path d=\"M414 96 L444 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M444.0 96.0 L438.0 100.0 L438.0 92.0 Z\" fill=\"var(--wire)\"></path><path d=\"M594 96 L624 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M624.0 96.0 L618.0 100.0 L618.0 92.0 Z\" fill=\"var(--wire)\"></path><path d=\"M99 156 L99 176 L659 176 L659 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"110\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cold run: from the disk, 435 ms</text><path d=\"M314 156 L314 166 L659 166\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"325\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">warm runs: already in memory, 167 and 208 ms</text></svg>", "caption": "Where a page of a table comes from. The cold run went all the way to the disk; the warm ones stopped in memory."}
```

The second and third differ by 41 milliseconds although both are warm. That is **noise**: other
processes, the processor's own caches, the timing of a few parallel workers. It never goes away,
and it is why one run proves nothing about a change. A query that "went from 208 to 167
milliseconds" after a fix may not have changed at all.

## The rule for the rest of the course

- **Say whether you are measuring cold or warm**, and compare like with like. A warm "after"
  against a cold "before" is a fix that did nothing and looks like a 60% improvement.
- **Run it several times and take the middle one**, the median, which a single slow run cannot
  drag around the way it drags an average.
- **A difference smaller than the noise is not a difference.** Lesson 24 turns that sentence into
  arithmetic.

## The machine you are measuring on

The numbers in the transcripts are from this computer:

```
ana@vm:~$ nproc
4
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       824Mi        11Gi       154Mi       4.2Gi        14Gi
Swap:             0B          0B          0B
```

Four processors and 15 GB of memory, against the two and four the recommended virtual machine
has. Of those 15, PostgreSQL itself only uses a fixed slice for its own cache of table pages:

```
market=# SHOW shared_buffers;
 shared_buffers 
----------------
 128MB
(1 row)

Time: 0.598 ms
```

**128 MB**, which is Ubuntu's default and was chosen to start on any computer, not to be fast on
yours. `db-administration` lesson 6 is the arithmetic for sizing it. This course leaves it alone
almost everywhere, on purpose: the database is ten times bigger than that cache, so the
difference between memory and disk stays visible, and a timing on your machine and one in a
transcript differ for reasons you can name.

Your timings will not match these. What should match is their **shape** — which query is faster,
by roughly how many times, and which run was cold. When the shape disagrees, look for what you did
differently before blaming the machine.
