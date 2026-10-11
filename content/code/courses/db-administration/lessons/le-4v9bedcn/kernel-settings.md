---
title: Two kernel settings for a database server
version: 1
---

Lesson 6 left two kernel settings for this lesson. Neither makes the server faster in a way you
would see in a benchmark; both decide what happens on the bad day, when memory runs out or the
shared cache is large. Read what the machine has now:

```
ana@db:~$ sysctl vm.overcommit_memory vm.overcommit_ratio
vm.overcommit_memory = 0
vm.overcommit_ratio = 50
ana@db:~$ systemctl cat postgresql@16-main | grep -B2 OOMScoreAdjust
# prevent OOM killer from choosing the postmaster (individual backends will
# reset the score to 0)
OOMScoreAdjust=-900
```

## Overcommit, and the out-of-memory killer

**With `vm.overcommit_memory = 0`, the default, Linux grants almost any request for memory and
counts on most of it never being touched.** When too much of it is touched at once, there is no
request left to refuse, so the kernel's out-of-memory killer chooses a process and kills it. Lesson
6 followed what that does to PostgreSQL: a killed backend may have left shared memory half
changed, so the postmaster ends every connection and restarts, and one query's memory becomes
everybody's outage.

The packaged unit already protects one process. `OOMScoreAdjust=-900` makes the postmaster the
last thing the killer would pick, and, as its comment says, each backend resets its own score to
0 so that it stays a fair target. Losing a backend costs a restart of the sessions; losing the
postmaster costs the whole cluster until somebody starts it again. You can check a running
server's postmaster with the first line of `postmaster.pid`, which lesson 4 opened:

```sh
sudo cat /proc/$(sudo head -1 /var/lib/postgresql/16/main/postmaster.pid)/oom_score_adj
```

On the recording machine that printed 0, because it is a container and a container is not allowed
to lower a score; on your virtual machine it prints the unit's -900.

**`vm.overcommit_memory = 2` stops the kernel promising memory it does not have.** A request
beyond the limit fails at once, inside the process that made it, and PostgreSQL turns that into an
`out of memory` error for that one query rather than a killed process and a restart. The limit is
the swap plus `vm.overcommit_ratio` per cent of the memory, and that second number is the trap:
**at the default of 50, a 4 GB machine without swap may commit only 2 GB in total**, every process
included, and a server sized by lesson 6's arithmetic can fail to start or fail ordinary queries. So
the two are set together, on a machine that runs nothing but the database, in a file of their own:

```conf
# /etc/sysctl.d/30-postgresql.conf
vm.overcommit_memory = 2
vm.overcommit_ratio = 90
```

```sh
sudo sysctl --system
```

These were not run on the recording machine: a container cannot change the kernel it shares, and
`sysctl -w` there answers that the file system is read-only. On your virtual machine they take
effect at once and survive a reboot. Ninety is a starting point for a server with little or no
swap; watch `CommitLimit` and `Committed_AS` in `/proc/meminfo` after the change, and raise the
ratio if the server is refused memory it ought to have.

## Huge pages

The shared buffers are one large block of memory, and the processor finds every 4 kB page of it
through a table it caches. **Huge pages are 2 MB each**, so the same block needs 512 times fewer
entries, and on a server with a cache of many gigabytes that saves real work in every backend.
PostgreSQL uses them when it can and tells you how many it would need:

```
ana@db:~$ psql shop -c "SHOW huge_pages" -c "SHOW shared_memory_size" -c "SHOW shared_memory_size_in_huge_pages"
 huge_pages 
------------
 try
(1 row)

 shared_memory_size 
--------------------
 143MB
(1 row)

 shared_memory_size_in_huge_pages 
----------------------------------
 72
(1 row)

ana@db:~$ grep -E "^(HugePages_Total|HugePages_Free|Hugepagesize)" /proc/meminfo
HugePages_Total:       0
HugePages_Free:        0
Hugepagesize:       2048 kB
```

`shared_memory_size_in_huge_pages`, new in PostgreSQL 16, is the server's whole shared memory
divided into pages of the size the kernel reports: 143 MB is 72 pages of 2 MB. The kernel has
**none reserved**, and huge pages must be reserved in advance, so **`try` quietly fell back to
ordinary pages** and said nothing. Reserving them is one more line in the same file, sized from
that number with a little room, followed by a restart of PostgreSQL so it allocates again:

```conf
vm.nr_hugepages = 80
```

and, in a configuration file of PostgreSQL's from lesson 5, the setting that turns the silent
fallback into a refusal to start:

```ini
huge_pages = on
```

**`on` is the honest value once they are reserved**: if the reservation is ever lost, the server
says so at start instead of running slower with nobody told. Like the overcommit settings, these
were not run here. On the course's 4 GB virtual machine, with 128 MB of shared buffers, the gain
is too small to measure; on a server with tens of gigabytes of cache it is worth the line.
