---
title: Disk throughput, and why 100% busy is not a verdict
version: 2
---

Space is one question; whether the disk can keep up is a different one, and the
tool is `iostat`.

Start the writers, and give them a few seconds:

```sh
cd ~/work/load
./fill.sh &
sleep 10
```

Here is this machine writing as fast as its disk will take it:

```
ana@vm:~$ iostat -xz 2 2 | tail -6
           0.25    0.00    9.95   41.44    1.01   47.36

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
vda              0.00      0.00     0.00   0.00    0.00     0.00 2062.50 1055746.00     0.00   0.00    1.63   511.88    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    3.36  99.80


```

| | |
|---|---|
| `-x` | the extended columns. Without it you get four, and none of them is `await` |
| `-z` | omit devices with no activity. On a machine with twelve disks this is the difference between readable and not |
| `2 2` | two samples, two seconds apart. **The first is since boot** |

That last point again, because it is the same trap as `vmstat`: **the first
block `iostat` prints is an average since the machine booted.** The `tail -6`
above is throwing it away.

## The columns that matter

Out of twenty-odd columns, five:

| | |
|---|---|
| `r/s` `w/s` | **IOPS** — operations per second, read and written |
| `rkB/s` `wkB/s` | **throughput** — kilobytes per second |
| `r_await` `w_await` | **milliseconds a request waited**, queue time plus service time |
| `aqu-sz` | average queue depth |
| `%util` | percentage of time the device had at least one request in flight |

Reading the capture above: 2062 writes a second, a gigabyte a second of data,
a queue depth of 3.36, **1.63 milliseconds of write await**, and 99.8% utilisation.

**That is a healthy disk working hard.** A millisecond and a half of wait on a
device doing a gigabyte a second is nothing; the queue is three deep, about one
and a half per writer; nothing is suffering.

## `%util` stopped meaning saturation

`%util` is the fraction of time at least one request was outstanding. On a
mechanical disk with one head, that was saturation: busy meant busy.

**On anything with a queue — every SSD, every NVMe device, every RAID
controller, every cloud volume — it is not.** A device that can serve thirty-two
requests at once shows `%util 100` while handling one request at a time, and it
shows `%util 100` while handling thirty-two. The number is the same and the
machine is in completely different states.

So `%util 99.80` above is a fact and not a diagnosis. **The diagnosis is in
`await`**:

| | |
|---|---|
| `await` under a millisecond | NVMe or a cache, working |
| a few milliseconds | an SSD, or a mechanical disk not queueing |
| tens of milliseconds | a mechanical disk with a queue, or a cloud volume at its limit |
| hundreds | something is very wrong, and applications are noticing |

And read `aqu-sz` alongside it. Await rising while the queue stays at one means
each request got slower; await rising because the queue is forty deep means you
are asking for more than the device can do.

## `vmstat`'s two columns

You do not always need `iostat`:

```
ana@vm:~$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 1  2      0 15709852   6988 371876    0    0   137 15593 1056    2  9  2 88  1  0  0
 3  1      0 15713056   6988 371876    0    0     0 1010688 3933 4592  0 10 45 43  1  0
 0  2      0 15713056   6988 371876    0    0     0 1001472 3914 4764  0 10 52 36  1  0
```

**`b 2` and `wa 36` with `r 0` is the whole diagnosis in six characters.**
Nothing wants a processor, two things are blocked, and over a third of the
machine's processor time was idle-because-of-disk. `bo` is a million blocks a second going
out.

That combination — high `wa`, high `b`, low `r` — is what an I/O problem looks
like from `vmstat`, and it is why `vmstat 1` is the first command and `iostat`
is the second.

Stop the writers, and delete what they wrote:

```sh
cd ~/work/load
pkill -f fill.sh
sleep 3
rm -f fill1.tmp fill2.tmp
```

## Reads, writes and flushes are different

`iostat -x` splits them for a reason:

**Reads** are usually synchronous: something is waiting for the answer right
now, so `r_await` maps directly onto somebody's request being slow.

**Writes** are usually not: the kernel takes them into the page cache and
returns immediately, and writes them out later. `w_await` measures the flush,
which nobody is waiting for — until the cache fills, and then everybody is.

**`f/s` and `f_await` are flushes** — `fsync()`, which is a program insisting
that data really is on the medium. Databases do this constantly, and a high
`f_await` on a database volume is the most direct "this disk is too slow for
this workload" signal there is.

## The write cliff

The two states to know about:

| | |
|---|---|
| `Dirty` in `/proc/meminfo` small and steady | writeback is keeping up |
| `Dirty` large and growing, `wa` climbing | it is not, and the cliff is coming |

When dirty pages reach `vm.dirty_ratio` — 20% of memory by default — the kernel
stops being generous and makes the *writing process* do the writeback itself.
Throughput does not degrade gently; it falls off a step, and an application that
was fine a second ago is now blocking on every write.

A machine that is fine for fifty seconds and terrible for ten, repeatedly, is
usually this.

## In order

```sh
vmstat 1                 # is wa high and b non-zero
iostat -xz 2             # which device, and what is await
pidstat -d 1             # which process — the next section
```
