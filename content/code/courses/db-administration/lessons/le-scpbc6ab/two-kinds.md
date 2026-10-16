---
title: Two kinds of memory
version: 1
---

The picture most people bring from other software is a single number: give the program 2 GB and
it uses 2 GB. **PostgreSQL has two kinds of memory, and only one of them is a fixed size.** One
is shared by every process and allocated once, when the server starts. The other is taken by each
process for one operation at a time, a sort or a hash or an index build, and given back when the
operation ends. The first is easy to size. The second is the one that runs a machine out of
memory, because its total depends on what everybody is doing at once.

## The machine the numbers came from

Memory arithmetic depends on the machine, so start with the one these transcripts were recorded
on:

```
ana@db:~$ nproc
4
ana@db:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.8Gi       1.3Gi       477Mi        13Gi        13Gi
Swap:             0B          0B          0B
```

**4 processors and 15 GB of memory.** The virtual machine lesson 3 recommends has 2 processors and
4 GB, so `free -h` on yours prints smaller numbers, and wherever an answer in this lesson depends
on the size of the machine, it is worked out for both. `buff/cache` is the operating system's
page cache, which this lesson comes back to: memory that holds recently read files and is given
up the moment a program asks for it, which is why `available` is far larger than `free`.

## The parameters, sorted by kind

```
ana@db:~$ psql shop
shop=# SELECT name, setting, unit, context
shop-#   FROM pg_settings
shop-#  WHERE name IN ('shared_buffers', 'shared_memory_size', 'work_mem',
shop(#                 'hash_mem_multiplier', 'maintenance_work_mem',
shop(#                 'autovacuum_work_mem', 'temp_buffers', 'effective_cache_size')
shop-#  ORDER BY name;
         name         | setting | unit |  context   
----------------------+---------+------+------------
 autovacuum_work_mem  | -1      | kB   | sighup
 effective_cache_size | 524288  | 8kB  | user
 hash_mem_multiplier  | 2       |      | user
 maintenance_work_mem | 65536   | kB   | user
 shared_buffers       | 16384   | 8kB  | postmaster
 shared_memory_size   | 143     | MB   | internal
 temp_buffers         | 1024    | 8kB  | user
 work_mem             | 4096    | kB   | user
(8 rows)

shop=# \q
```

The `context` column, from lesson 5, already sorts them.

**Shared, sized at start.** `shared_buffers` is a `postmaster` parameter: 16384 pages of 8 kB,
128 MB, allocated when the server starts and kept until it stops. `shared_memory_size` is
`internal`, a value the server computes rather than one you set: the whole shared segment,
143 MB, of which the buffers are most and the rest is lock tables, the write-ahead log's buffers
and other bookkeeping.

**Private, per operation.** `work_mem`, 4 MB, is the most one sort or one hash may use before it
writes to temporary files instead. `hash_mem_multiplier` lets a hash use twice that.
`maintenance_work_mem`, 64 MB, is the same idea for maintenance work: building an index,
vacuuming. `autovacuum_work_mem` at `-1` means autovacuum's workers use `maintenance_work_mem`
too. `temp_buffers`, 8 MB, is a session's cache for its own temporary tables. All of them are
`user` or `sighup`, changeable without a restart, because none of them is allocated until an
operation asks.

**Neither.** `effective_cache_size`, 4 GB, allocates nothing at all. It tells the planner how
much of the database it may assume is cached somewhere, and the last section of this lesson
shows how little the server checks it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A machine’s memory drawn as one box. At the top, the shared memory the server allocates once at start, mostly shared_buffers, one copy of table and index pages used by every process. Below it, four processes with private memory: connection 1 with one sort of up to work_mem, connection 2 with a hash of up to twice work_mem and a sort of up to work_mem, connection 3 idle with none, and an autovacuum worker using maintenance_work_mem. At the bottom, the operating system’s page cache fills what is left, and below the machine is the disk.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"330\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the machine’s memory</text><text x=\"30\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">shared memory, allocated once at start</text><rect x=\"30\" y=\"66\" width=\"660\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"46\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">shared_buffers</text><text x=\"46\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pages of tables and indexes, one copy for every process</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">private memory, taken per operation and given back when it ends</text><rect x=\"30\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">connection 1</text><rect x=\"38\" y=\"180\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"46\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sort</text><text x=\"46\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work_mem</text><rect x=\"205\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">connection 2</text><rect x=\"213\" y=\"180\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"221\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hash</text><text x=\"221\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work_mem × 2</text><rect x=\"213\" y=\"216\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"221\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sort</text><text x=\"221\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work_mem</text><rect x=\"375\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">connection 3</text><text x=\"385\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">idle</text><rect x=\"545\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">autovacuum worker</text><rect x=\"553\" y=\"180\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"561\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vacuum</text><text x=\"561\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">maintenance_work_mem</text><rect x=\"30\" y=\"272\" width=\"660\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"298\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the operating system’s page cache: whatever memory is left, holding recently read file blocks</text><rect x=\"300\" y=\"356\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"372\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">disk</text><line x1=\"360\" y1=\"324\" x2=\"360\" y2=\"354\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line></svg>", "caption": "Two kinds of memory. The top box is sized once by a restart and shared; the boxes inside each process appear for one operation and are counted per operation, so the total moves with what the connections are doing."}
```

Each process in the drawing is one connection, and the next sections measure both kinds on the
`shop` database: what `shared_buffers` holds and what holding more changes, then a sort and an
index build that do and do not fit their private allowance. Lesson 10 is about why each
connection is a whole process; here it matters because **every one of them can take its own
`work_mem`, once per operation**.
