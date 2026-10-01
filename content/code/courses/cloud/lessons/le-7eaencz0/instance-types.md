---
title: "Instance types: a family, a generation and a size"
version: 1
---

The list of instance types looks like a catalogue of arbitrary codes, and a first-time user picks
one by scrolling. **The codes are a grammar**, and once you can read one you can place any type on
the menu without looking it up.

A type is a fixed combination of processor threads and memory, plus a network allowance and
sometimes local disks. What separates the families is the **ratio** of memory to processor, because
that is what differs between workloads: a web application wants some of both, a video encoder wants
processor and little memory, and an in-memory cache wants the opposite.

| family | what it is for | memory per vCPU on AWS |
|---|---|---|
| general purpose, `m` | most servers, when you have no reason to pick another | 4 GiB |
| compute optimised, `c` | work that is mostly arithmetic: encoding, compiling, batch | 2 GiB |
| memory optimised, `r` | databases, caches, anything that holds a lot in memory | 8 GiB |
| burstable, `t` | machines that are idle most of the time | varies |

The price sheet shows two of those ratios side by side. `m7i.large` is 2 vCPU with 8 GiB and
`c7i.large` is 2 vCPU with 4 GiB: the same processor, half the memory, and 0.13755 USD an hour
against 0.16065 in `sa-east-1`.

## Reading a name

`m7i.large` is four pieces of information, and the other providers' names break down the same way
with different letters.

| piece | in `m7i.large` | what it says |
|---|---|---|
| family | `m` | general purpose |
| generation | `7` | the seventh of this family; a higher number is newer hardware |
| attributes | `i` | the processor: `i` Intel, `a` AMD, `g` AWS's own Graviton, which is Arm |
| size | `large` | how much of the family's ratio you get; `xlarge` is twice as much |

More letters can follow the processor. `d` means the host carries local disks for the instance
(the instance store, which does not survive a stop; the section on disks in this lesson explains it), and `n` means
more network bandwidth. So `m7gd.large` is `m7g.large` with a local disk.

**The `g` is not a detail.** An Arm processor runs programs compiled for Arm, and a binary built for
x86-64 will not start on it. The major Linux distributions, the language runtimes and most
container images publish Arm builds, so a Python or Java service usually moves across unchanged;
a vendor's closed binary, or a native library nobody compiled for `arm64`, is where the move stops.

## A vCPU is a thread, not a core

**A vCPU is one hardware thread.** On the Intel and AMD types, each physical core runs two threads
at once (simultaneous multithreading), so the 2 vCPU of `m7i.large` are one core. Graviton
processors have no second thread, so the 2 vCPU of `m7g.large` are two whole cores. The same number
on the sheet therefore does not mean the same amount of processor across the two, which is one
more reason the next section says to measure rather than compare labels.

## Burstable types, in outline

The `t` family (`t3` on Intel, `t4g` on Graviton) sells a **baseline** rather than the whole
thread: a percentage of each vCPU that the instance may use all the time. Below the baseline it
earns CPU credits; above it, it spends them. When the credits run out, what happens depends on a
setting. In standard mode the instance is held down to its baseline, and in unlimited mode it keeps
running at full speed and the surplus is billed. AWS launches `t3` and `t4g` in unlimited mode
unless you say otherwise.

The sheet puts a number on the trade. `t3.medium` is 2 vCPU and 4 GiB for 0.06720 USD an hour in
`sa-east-1`; `c7i.large` is also 2 vCPU and 4 GiB, for 0.13755. **The burstable machine is half the
price because it is not promising you the processor all day.** For a staging server that is idle
between deployments that is a bargain. For a service that sits at 70% CPU from nine to six, it is a
machine that is either throttled or quietly billing surplus, and a fixed type would have been both
cheaper and faster.
