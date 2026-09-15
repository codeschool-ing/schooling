---
title: Memory, and why low free memory is what healthy looks like
version: 1
---

```
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       657Mi        13Gi        11Mi       1.5Gi        15Gi
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
Mem:           16095         661       14125          11        1558       15434
ana@vm:~$ dd if=/dev/zero of=/home/ana/work/cache.tmp bs=1M count=600 2>&1 | tail -1
629145600 bytes (629 MB, 600 MiB) copied, 3.4391 s, 183 MB/s
ana@vm:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16095         668       13510          11        2173       15426
```

Six hundred megabytes were written to a file. `buff/cache` went up by 615, and
`free` went **down** by 615.

**And `available` did not move**: 15434 before, 15426 after — eight megabytes,
which is noise.

That is the whole lesson in one measurement. **The 600 MB is not gone.** It is
holding a copy of a file, and the kernel will hand it back the instant a program
asks for memory. `available` knows that; `free` does not.

Delete the file and the cache goes with it:

```
ana@vm:~$ rm -f /home/ana/work/cache.tmp; free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16095         647       14139          11        1558       15448
```

Back to 1558, exactly where it started.

**So: a machine with 200 MB free and 30 GB of cache is not short of memory.** A
machine with 200 MB *available* is. The people who write scripts to "free up
memory" by dropping caches are making their machine slower and calling it
maintenance.

`echo 3 > /proc/sys/vm/drop_caches` exists, works, and is a debugging tool for
benchmark repeatability. It is not a fix for anything.

## Per process

`free` says the machine's total. `ps` says who:

```
ana@vm:~$ ps -eo pid,%cpu,%mem,rss,comm --sort=-%cpu | head -6
  PID %CPU %MEM   RSS COMMAND
16260  100  0.0  3388 bash
16258 99.8  0.0  3380 bash
16259 99.6  0.0  3348 bash
  103  4.1  2.4 403252 claude
16257  0.3  0.0 11156 python3
```

| | |
|---|---|
| `VSZ` | **virtual** size — everything mapped, including what was never touched |
| `RSS` | **resident** set size — physical pages actually in memory |
| `%MEM` | `RSS` as a share of total |

**`RSS` is the number people mean and it double-counts.** Shared libraries are
counted in the `RSS` of every process that maps them, so adding up the `RSS`
column of a hundred processes gives an answer larger than the machine.

`VSZ` is nearly meaningless on modern programs — a runtime that reserves 32 GB
of address space and touches 200 MB of it shows a `VSZ` of 32 GB and is using
200 MB.

For the number that does not double-count, there is `PSS` — proportional set
size, which divides each shared page between the processes sharing it:

```
ana@vm:~$ grep -E 'Rss|Pss' /proc/self/smaps_rollup
Rss:                2224 kB
Pss:                 667 kB
Pss_Dirty:           152 kB
Pss_Anon:            152 kB
Pss_File:            515 kB
Pss_Shmem:             0 kB
SwapPss:               0 kB
```

**2224 kB resident, 667 kB proportional.** Most of this shell's resident memory
is libc and the binary itself, shared with every other process on the machine,
and `Pss` charges it its fair share. Add up `Pss` across every process and the
total is the truth; add up `Rss` and it is not.

## `/proc/meminfo`, for when `free` is not enough

```
ana@vm:~$ grep -E 'MemTotal|MemFree|MemAvailable|^Cached|^Buffers|SwapTotal' /proc/meminfo
MemTotal:       16482220 kB
MemFree:        14493656 kB
MemAvailable:   15809336 kB
Buffers:           56096 kB
Cached:          1458848 kB
SwapTotal:             0 kB
```

`free` is a formatter for this file. Two more lines in it are worth knowing:

```
ana@vm:~$ grep -E '^Dirty|^Slab|^Writeback' /proc/meminfo
Dirty:               180 kB
Writeback:             0 kB
Slab:              81980 kB
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
