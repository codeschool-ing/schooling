---
title: The out-of-memory killer, caught in the act
version: 2
---

When there is no memory left and nothing to reclaim, the kernel picks a process
and kills it. Not the one that asked — the one it scores worst.

Here is that happening: a control group with a hundred-megabyte limit, and a
program that allocates ten megabytes at a time until something stops it. The
program first:

```sh
cd ~/work
cat > hog.py <<'END'
import sys, time
chunks = []
mb = 0
while True:
    chunks.append(bytearray(10 * 1024 * 1024))
    mb += 10
    print(f"allocated {mb} MB", flush=True)
    time.sleep(0.2)
END
```

Control groups belong to root, so the rest is in a root shell. **This section was
captured on an Ubuntu 24.04 virtual machine**, the one lesson 1 recommends,
because the machine the other sections ran on uses the older cgroup v1, where
these files have other names. A directory made under `/sys/fs/cgroup` is a new
group; writing a process id into its `cgroup.procs` moves that process in:

```
ana@vm:~$ sudo -i
root@vm:~# mkdir /sys/fs/cgroup/oomlab
root@vm:~# echo 100M > /sys/fs/cgroup/oomlab/memory.max
root@vm:~# cat /sys/fs/cgroup/oomlab/memory.max
104857600
root@vm:~# bash -c 'echo $$ > /sys/fs/cgroup/oomlab/cgroup.procs; exec python3 /home/ana/work/hog.py' | tail -3; echo "exit status ${PIPESTATUS[0]}"
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
root@vm:~# cat /sys/fs/cgroup/oomlab/memory.events
low 0
high 0
max 35
oom 1
oom_kill 1
oom_group_kill 0
root@vm:~# cat /sys/fs/cgroup/oomlab/memory.peak
104857600
```

`oom_kill 1` — one kill, in this group, since it was created. `max 35` is how
many times the group reached its limit and the kernel tried to reclaim memory
before giving up. And `memory.peak` is the limit exactly, to the byte, because
that is where it stopped.

On cgroup v1, the machine the rest of this lesson ran on, the same counters are
`memory.oom_control` and `memory.max_usage_in_bytes`, and the limit is
`memory.limit_in_bytes`.

And the kernel logs it, in detail:

```
root@vm:~# dmesg -T | grep -i 'killed process' | tail -1
[Wed Oct  7 13:59:39 2026] Memory cgroup out of memory: Killed process 1726 (python3) total-vm:120784kB, anon-rss:102016kB, file-rss:6528kB, shmem-rss:0kB, UID:0 pgtables:268kB oom_score_adj:0
root@vm:~# rmdir /sys/fs/cgroup/oomlab
root@vm:~# exit
logout
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
ana@vm:~$ for p in 1 $(pgrep -x multipathd) $$; do echo "$p $(cat /proc/$p/comm) rss=$(awk '/VmRSS/{print $2}' /proc/$p/status) score=$(cat /proc/$p/oom_score) adj=$(cat /proc/$p/oom_score_adj)"; done
1 systemd rss=13348 score=0 adj=0
392 multipathd rss=27300 score=0 adj=-1000
1638 bash rss=5516 score=667 adj=0
```

`oom_score` is the kernel's ranking, and three things in that output are worth
noticing. **PID 1 scores zero** — init is exempt, because killing it kills the
machine. **`multipathd` scores zero too**, and the reason is its last column: an
`oom_score_adj` of `-1000`, which it sets for itself, because a server that
loses the daemon managing its paths to disk can lose its disks.

And the shell, using five megabytes, scores 667. That is not because it is
large; it is where the scale starts. The kernel adds a process's share of
memory, in thousandths, to 1000, and shows two thirds of the result. So a
process using nothing reads 666 or 667, one using all the memory reads 1333,
and only the differences between two processes mean anything.

`oom_score_adj` is `-1000` to `1000` and is your thumb on that scale.
`-1000` makes a process immune, as `multipathd` is; `1000` volunteers it first.
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
