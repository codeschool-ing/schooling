---
title: The out-of-memory killer, caught in the act
version: 1
---

When there is no memory left and nothing to reclaim, the kernel picks a process
and kills it. Not the one that asked — the one it scores worst.

Here is that happening on this machine. A control group with a hundred-megabyte
limit, and a program that allocates ten megabytes at a time until something
stops it:

```
root@vm:~# cat /home/ana/work/hog.py
import sys, time
chunks = []
mb = 0
while True:
    chunks.append(bytearray(10 * 1024 * 1024))
    mb += 10
    print(f"allocated {mb} MB", flush=True)
    time.sleep(0.2)
root@vm:~# mkdir -p /sys/fs/cgroup/memory/oomlab
root@vm:~# echo 100M > /sys/fs/cgroup/memory/oomlab/memory.limit_in_bytes
root@vm:~# cat /sys/fs/cgroup/memory/oomlab/memory.limit_in_bytes
104857600
root@vm:~# bash -c 'echo $$ > /sys/fs/cgroup/memory/oomlab/cgroup.procs; exec python3 /home/ana/work/hog.py' | tail -3; echo "exit status ${PIPESTATUS[0]}"
allocated 70 MB
allocated 80 MB
allocated 90 MB
exit status 137
```

**It reached 90 MB against a 100 MB limit and stopped.** No error message, no
exception, no traceback — the program did not get a chance to fail, it was
ended.

## 137

`exit status 137` is the only thing the shell has to tell you, and it is
enough.

**137 = 128 + 9**, and signal 9 is `KILL`. Lesson 6 section 14's convention, and
lesson 6 section 08's table: a process terminated by a signal reports `128 + N`,
and `KILL` is the one that cannot be caught, blocked or ignored.

So when a container exits 137, or `kubectl describe pod` says `OOMKilled`, or a
service disappears with `status=9/KILL` in `systemctl`, they are all this.

**Anything you find dead with 137 and no log entry of its own was killed from
outside**, and the first place to look is memory.

## The evidence

```
root@vm:~# cat /sys/fs/cgroup/memory/oomlab/memory.oom_control
oom_kill_disable 0
under_oom 0
oom_kill 1
root@vm:~# cat /sys/fs/cgroup/memory/oomlab/memory.max_usage_in_bytes
104857600
```

`oom_kill 1` — one kill, in this group, since it was created. `max_usage`
exactly the limit, to the byte, because that is where it stopped.

On cgroup v2 the same counters live in `memory.events`, with an `oom_kill` line
in it.

And the kernel logs it, in detail:

```
root@vm:~# dmesg -T | grep -i 'killed process' | tail -1
[Tue Sep 15 11:29:26 2026] Memory cgroup out of memory: Killed process 16351 (python3) total-vm:116352kB, anon-rss:102016kB, file-rss:5264kB, shmem-rss:0kB, UID:0 pgtables:260kB oom_score_adj:0
```

**That one line is the whole report.** Which process, by name and pid; how much
it had (`anon-rss` 102 MB — its own data, which is what counted against the
limit); its `oom_score_adj`; and, crucially, `Memory cgroup out of memory`
rather than plain `Out of memory`, which tells you it hit *a limit* and not *the
machine*.

```sh
dmesg -T | grep -i 'killed process'       # the kernel ring buffer, with dates
journalctl -k | grep -i 'out of memory'   # the same lines, on a systemd machine
```

`-T` is what turns `[16469.175098]` — seconds since boot — into a timestamp you
can compare against somebody's complaint.

The kernel also dumps the group's memory statistics and the score of every
candidate it considered just above that line, which is worth reading when the
process it chose was not the one you expected.

## Which process gets chosen

Not the biggest, and not the one that asked. The kernel scores every candidate
and picks the highest:

```
ana@vm:~$ for p in 1 103 $$; do echo "$p rss=$(awk '/VmRSS/{print $2}' /proc/$p/status) score=$(cat /proc/$p/oom_score)"; done
1 rss=4240 score=0
103 rss=413036 score=683
16762 rss=3568 score=666
```

`oom_score` runs from 0 to 1000, and three things in that output are worth
noticing. **PID 1 scores zero** — init is exempt, because killing it kills the
machine. The 400 MB process scores higher than the 3 MB one, so the ordering
follows memory. And the gap between them is seventeen points, not seventy, which
is the scale being compressed by something other than these two processes — the
formula weighs a process against the limit it is under, and inside a container
that is not the machine's total.

`oom_score_adj` is `-1000` to `1000` and is your thumb on that scale.

`oom_score_adj` of `-1000` makes a process immune; `1000` volunteers it first.
Setting `-1000` on your database and `1000` on a batch job is a real technique
and an easy way to make the machine unkillable in a bad way.

**The score is roughly proportional to memory used**, which means the OOM killer
usually kills exactly the process you care about, because the process you care
about is the one using the memory. This is not a bug; there is no better answer
available at that moment.

## Preventing it

| | |
|---|---|
| a memory limit per service | `MemoryMax=` in a unit file, or the container's limit |
| `oom_score_adj` | protect one process at the cost of another |
| swap | converts the kill into a slowdown. Previous section |
| monitoring `available` | the only one that fixes anything |

**`MemoryMax=2G` in a systemd unit (lesson 5 section 11) does not stop the kill
— it moves it.** The service is killed when it exceeds its own limit instead of
when the machine does, which contains the damage to one thing instead of letting
the kernel choose.

## What to do when you find one

1. **`exit 137` or `OOMKilled`** — confirm it was memory, not something else
   sending `KILL`.
2. **`dmesg -T | grep -i 'killed process'`** — get the process name and the size
   it had reached.
3. **Was it the machine or a cgroup?** The limit it hit decides what you change.
4. **Was it growing steadily or did it spike?** A leak and a large request need
   different fixes, and only a graph over time answers this.

Step 4 is the one that needs to have been set up in advance, which is the
argument for having any monitoring at all.
