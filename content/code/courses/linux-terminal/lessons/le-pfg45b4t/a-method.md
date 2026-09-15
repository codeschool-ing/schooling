---
title: A method, for when somebody says the machine is slow
version: 1
---

The commands are not the skill. The order is.

## Sixty seconds

This is the checklist, in the order that rules things out fastest. Each line is
one command, and most investigations end in the first four.

```sh
uptime                  # 1. is anything queueing at all
dmesg -T | tail -20     # 2. did the kernel already tell you
vmstat 1 5              # 3. processor, memory, io — all three at once
mpstat -P ALL 1 3       # 4. one core or all of them
pidstat -u 1 3          # 5. which process, for processor
iostat -xz 2 3          # 6. which disk, and is await bad
free -m                 # 7. is available falling
sar -n DEV 1 3          # 8. is the network moving
ss -s                   # 9. are sockets piling up
```

**Steps 1 to 4 tell you which of the four resources it is.** Steps 5 to 9 are
the follow-up for whichever one answered, and you do not run the others.

Step 2 is the one people skip and it is free. An OOM kill, a disk error, a
filesystem remounted read-only, a network card resetting — the kernel wrote it
down already, and it takes three seconds to look.

## The decision, written out

| what you see | what it is | where to go next |
|---|---|---|
| `r` > cores, `us` high | processor, in user code | `pidstat -u`, then a profiler |
| `r` > cores, `sy` high | processor, in the kernel | `pidstat -u`, then `strace -c` |
| `wa` high, `b` > 0, `r` low | **disk** | `iostat -xz`, then `pidstat -d` |
| `si`/`so` busy | memory, swapping | `ps --sort=-rss`, find the grower |
| `available` near zero | memory | the same, and check `dmesg` for kills |
| `st` non-zero | the host is oversubscribed | not yours to fix |
| everything idle, still slow | **not this machine** | network, a dependency, a lock |

**That last row is the most important one.** A machine with four idle cores,
free memory and a quiet disk is not the problem, and every minute spent looking
harder at it is a minute not spent on the database it is waiting for.

## Four questions to ask before any of it

**When did it start?** A change at 14:05 and an incident at 14:06 is a different
investigation from one that has been degrading for a month.

**Is it everything or one thing?** One endpoint slow is an application problem
wearing a performance costume.

**Is it this machine?** See above. `ss -ti`, a `curl -w` against the dependency,
or a `ping` will tell you in one command.

**What changed?** A deployment, a configuration push, a cron job, a certificate
that expired, a disk that filled. Performance problems that appear without a
cause are rare; performance problems whose cause nobody mentioned are not.

## Fix the measurement before the machine

Two traps, and both waste a day.

**Do not tune anything you have not measured.** Every `sysctl` in a blog post
was the right answer for somebody else's workload. `vm.swappiness`,
`vm.dirty_ratio`, the scheduler, the readahead size — each of them is a real
knob and each of them is a way to make the machine worse if you are guessing.

**Do not fix the symptom.** A disk filling up is not fixed by deleting logs; it
is fixed by finding out why they grew. `df` at 95% is a deadline, not a
diagnosis.

## The one-line summary of the lesson

| | |
|---|---|
| load average | **not a percentage**, counts disk waiters, compare it to cores |
| `free` | **low free is healthy**, read `available` |
| `%util` | **not saturation** on anything with a queue, read `await` |
| the first line | **an average since boot**, on `vmstat`, `iostat` and `sar` |
| inside a container | **every one of them reads the host**, check the cgroup |

Those five sentences are the whole of what this lesson is for. The commands you
can look up.
