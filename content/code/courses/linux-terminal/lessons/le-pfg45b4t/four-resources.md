---
title: Four resources, and the difference between busy and stuck
version: 2
---

"The machine is slow" is not a report. It becomes one when you can say which of
four things it has run out of.

| | measured with | |
|---|---|---|
| **processor** | `vmstat`, `mpstat`, `top` | is anything waiting for a core |
| **memory** | `free`, `/proc/meminfo` | is anything waiting for a page |
| **disk space** | `df`, `du` | is there room to write |
| **disk throughput** | `iostat`, `vmstat` | is anything waiting for a read or a write |

Network is a fifth and behaves like the fourth — it is a device with a queue —
so it gets a section of its own but not a new idea.

**Almost every performance problem is one of these four**, and the skill is
asking them in order and stopping when one of them answers rather than
collecting every number you know how to collect.

## The tools, and the load this lesson puts on the machine

`vmstat`, `free`, `df` and `top` come with every Ubuntu. `mpstat`, `iostat`,
`pidstat` and `sar` are one package, `sysstat`, which some installations include
and some do not. If `mpstat` answers `command not found`, install it:

```sh
sudo apt install sysstat
```

A machine doing nothing gives numbers with nothing to read in them, so this
lesson makes two kinds of work on purpose, with two small scripts. `spin.sh`
keeps every core busy; `fill.sh` writes to the disk as fast as it will take it.
Both run until you stop them:

```sh
mkdir -p ~/work/load && cd ~/work/load
cat > spin.sh <<'END'
#!/bin/bash
# One busy loop per core, until this script is stopped: pkill -f spin.sh
trap 'kill $(jobs -p); exit' TERM INT
for i in $(seq "$(nproc)"); do
  bash -c 'while :; do :; done' &
done
wait
END
cat > fill.sh <<'END'
#!/bin/bash
# Two writers, each rewriting a 1000 MB file in place, straight to the disk
# past the page cache (oflag=direct), until stopped: pkill -f fill.sh
trap 'kill $(jobs -p); exit' TERM INT
for i in 1 2; do
  bash -c "while :; do dd if=/dev/zero of=fill$i.tmp bs=1M count=1000 oflag=direct conv=notrunc status=none; done" &
done
wait
END
chmod +x spin.sh fill.sh
```

Each section says when to start one and when to stop it. `fill.sh` needs two
gigabytes free, and leaves its two files behind for you to delete.

## Utilisation is not saturation

This is the distinction that makes the numbers readable, and it is why "100%"
so often means nothing.

**Utilisation** is what fraction of the time the resource was busy. A processor
at 100% utilisation is working, which is what you bought it for.

**Saturation** is how much work is *waiting* because the resource is busy. That
is the number that corresponds to somebody's request being slow.

Start the busy loops, give them a few seconds, and look:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 5  0      0 15704828   6896 371396    0    0   140 10094 1040    2  8  2 90  1  0  0
 4  0      0 15704828   6896 371396    0    0     0     0 1052  230 98  0  0  0  2  0
 4  0      0 15704576   6896 371396    0    0     0     0 1074  199 99  0  0  0  1  0
 4  0      0 15704576   6896 371396    0    0     0     0 1063  296 99  0  0  0  1  0
```

That is this machine with four busy loops on four cores. `us 98` and `us 99` is
**utilisation** — the processors are entirely in use, bar the one or two per
cent in `st` that section 04 explains. `r 4` is **saturation** — that many
processes wanted a core at the moment of sampling.

Four cores and four runnable processes is a machine working flat out and nobody
queueing. `r 40` on four cores would be the same utilisation and a very
different day.

**Read a utilisation number and a saturation number together, or you will
mistake a working machine for a broken one.**

Leave the loops running: the next section starts by watching the load average
climb because of them.

## Errors are the third thing

The full checklist — Brendan Gregg's, and worth knowing by its name, the **USE
method** — is: for every resource, check **Utilisation, Saturation and Errors**.

Errors are the ones nobody looks at until much later than they should:

```sh
ip -s link show eth0              # RX/TX errors and drops
dmesg -T | grep -iE 'error|fail'  # the kernel's own complaints
cat /proc/net/dev                 # the same counters, raw
```

A network card dropping one packet in ten thousand does not show up as
utilisation or saturation anywhere. It shows up as an application that is
occasionally, unreproducibly slow.

## The one number that is not on the list

There is no "is the machine slow" number, and the one people reach for —
**load average** — is the most misread figure on a Linux system. It is the next
section, and it is first because you have to unlearn it before the rest helps.

## What this lesson measures on

Everything here was captured while the machine was genuinely busy, with the two
scripts above: four loops spinning on four cores, and a gigabyte a second of
writes to a real disk. That machine has four cores, 16 GB and no swap, and it is
a container, which one section turns into a lesson of its own.

Two sections needed what it does not have — control groups of the current kind,
and `systemd` — and were captured on an Ubuntu 24.04 virtual machine, the one
lesson 1 recommends. Each of them says so where it starts.

Where a number could not be produced at all — swapping, on a machine with no
swap — the section says so rather than pasting one.
