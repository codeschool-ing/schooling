---
title: Four resources, and the difference between busy and stuck
version: 1
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

## Utilisation is not saturation

This is the distinction that makes the numbers readable, and it is why "100%"
so often means nothing.

**Utilisation** is what fraction of the time the resource was busy. A processor
at 100% utilisation is working, which is what you bought it for.

**Saturation** is how much work is *waiting* because the resource is busy. That
is the number that corresponds to somebody's request being slow.

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 14507736  56092 1514136    0    0    71   358  431    1  3  0 97  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1074  218 100  0  0  0  0  0
 5  0      0 14507736  56092 1514136    0    0     0     0 1062  188 100  0  0  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1083  296 100  0  0  0  0  0
```

That is this machine with four busy loops on four cores. `us 100` is
**utilisation** — the processors are entirely in use. `r 4` and `r 5` is
**saturation** — that many processes wanted a core at the moment of sampling.

Four cores and four runnable processes is a machine working flat out and nobody
queueing. `r 40` on four cores would be the same utilisation and a very
different day.

**Read a utilisation number and a saturation number together, or you will
mistake a working machine for a broken one.**

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

Everything here was captured on this machine while it was genuinely busy: four
processes spinning on four cores, a gigabyte a second of writes to a real disk,
and a program walking past a hundred-megabyte memory limit until the kernel
killed it.

Where a number could not be produced here — `%steal`, which needs a hypervisor
that is overcommitted — the section says so rather than pasting one.
