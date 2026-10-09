---
title: Memory, and why low free memory is what healthy looks like
version: 2
---

```
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       649Mi        14Gi        13Mi       369Mi        15Gi
Swap:             0B          0B          0B
```

Six columns, and **two of them are the ones to read**: `used` and `available`.
The others exist to be misunderstood.

| | |
|---|---|
| `total` | what the kernel can see |
| `used` | anonymous memory: programs' own data. **Real consumption** |
| `free` | memory the kernel has not put to any use. **Not a target** |
| `shared` | tmpfs and shared segments, counted inside `used` |
| `buff/cache` | file contents the kernel is holding on to |
| `available` | **what a new program could get without swapping.** The one that matters |

## The cache is not used memory

Empty memory does nothing for anybody, so the kernel fills it with the contents
of files you have read, in case you read them again. That is the page cache, and
it shows in `buff/cache`.

Watch it happen:

```
ana@vm:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16094         649       15351          13         369       15445
ana@vm:~$ dd if=/dev/zero of=/home/ana/work/cache.tmp bs=1M count=600 2>&1 | tail -1
629145600 bytes (629 MB, 600 MiB) copied, 2.68458 s, 234 MB/s
ana@vm:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16094         658       14734          13         985       15436
```

Six hundred megabytes were written to a file. `buff/cache` went up by 616, and
`free` went **down** by 617.

**And `available` did not move**: 15445 before, 15436 after — nine megabytes,
which is noise.

That is the whole lesson in one measurement. **The 600 MB is not gone.** It is
holding a copy of a file, and the kernel will hand it back the instant a program
asks for memory. `available` knows that; `free` does not.

Delete the file and the cache goes with it:

```
ana@vm:~$ rm -f /home/ana/work/cache.tmp; free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16094         645       15354          13         369       15449
```

Back to 369, exactly where it started.

**So: a machine with 200 MB free and 30 GB of cache is not short of memory.** A
machine with 200 MB *available* is. The people who write scripts to "free up
memory" by dropping caches are making their machine slower and calling it
maintenance.

`echo 3 > /proc/sys/vm/drop_caches` exists, works, and is a debugging tool for
benchmark repeatability. It is not a fix for anything.

## Per process

`free` says the machine's total. `ps` says who, and it is clearer with the
busy loops running:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ ps -eo pid,%cpu,%mem,rss,comm --sort=-%cpu | head -6
  PID %CPU %MEM   RSS COMMAND
11832 98.6  0.0  3412 bash
11833 98.6  0.0  3308 bash
11831 98.4  0.0  3388 bash
11834 97.6  0.0  3336 bash
   85  3.5  2.3 391944 claude
```

| | |
|---|---|
| `VSZ` | **virtual** size — everything mapped, including what was never touched |
| `RSS` | **resident** set size — physical pages actually in memory |
| `%MEM` | `RSS` as a share of total |

**`RSS` is the number people mean and it double-counts.** Shared libraries are
counted in the `RSS` of every process that maps them, so adding up the `RSS`
column of a hundred processes gives an answer larger than the machine.

That is all the loops were for here:

```sh
cd ~/work/load
pkill -f spin.sh
```

`VSZ` is nearly meaningless on modern programs — a runtime that reserves 32 GB
of address space and touches 200 MB of it shows a `VSZ` of 32 GB and is using
200 MB.

For the number that does not double-count, there is `PSS` — proportional set
size, which divides each shared page between the processes sharing it:

```
ana@vm:~$ grep -E 'Rss|Pss' /proc/self/smaps_rollup
Rss:                2196 kB
Pss:                 430 kB
Pss_Dirty:           152 kB
Pss_Anon:            152 kB
Pss_File:            278 kB
Pss_Shmem:             0 kB
SwapPss:               0 kB
```

**2196 kB resident, 430 kB proportional.** Most of this shell's resident memory
is libc and the binary itself, shared with every other process on the machine,
and `Pss` charges it its fair share. Add up `Pss` across every process and the
total is the truth; add up `Rss` and it is not.

## `/proc/meminfo`, for when `free` is not enough

```
ana@vm:~$ grep -E 'MemTotal|MemFree|MemAvailable|^Cached|^Buffers|SwapTotal' /proc/meminfo
MemTotal:       16480968 kB
MemFree:        15721760 kB
MemAvailable:   15818692 kB
Buffers:            6984 kB
Cached:           292264 kB
SwapTotal:             0 kB
```

`free` is a formatter for this file. Two more lines in it are worth knowing:

```
ana@vm:~$ grep -E '^Dirty|^Slab|^Writeback' /proc/meminfo
Dirty:                48 kB
Writeback:             0 kB
Slab:             109112 kB
WritebackTmp:          0 kB
```

| | |
|---|---|
| `Dirty` | modified pages not yet written to disk. Large and growing means the disk is behind |
| `Writeback` | pages being written out right now |
| `Slab` | kernel data structures — inode and dentry caches. Can be gigabytes and is reclaimable |

**`Slab` being enormous is the one that looks like a leak and is not**, on a
machine that has walked a filesystem with millions of files.

## When it really is memory

Three signs, in order of certainty:

| | |
|---|---|
| `available` falling towards zero | the real one |
| `si`/`so` in `vmstat` non-zero | the machine is swapping. Next section |
| processes being killed | the kernel gave up. Two sections on |

And one that is not a sign: `free` being small. It always is.
