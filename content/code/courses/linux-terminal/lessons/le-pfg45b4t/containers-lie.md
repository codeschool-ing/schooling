---
title: Inside a container, every tool in this lesson reads the wrong number
version: 1
---

This machine is a container. So is almost every machine you will be asked about
now, and it changes the answer to every question in this lesson.

```
ana@vm:~$ head -1 /proc/meminfo
MemTotal:       16482220 kB
ana@vm:~$ cg=$(awk -F: '/:memory:/{print $3}' /proc/self/cgroup); echo "$cg"
/process_api/01a0a3d8-ffc7-75b6-823b-37ba3b6b8c0e/claude-code-bash
ana@vm:~$ numfmt --to=iec $(cat /sys/fs/cgroup/memory/$cg/memory.limit_in_bytes)
14G
ana@vm:~$ numfmt --to=iec $(( $(awk '/MemTotal/{print $2}' /proc/meminfo) * 1024 ))
16G
```

**Sixteen gigabytes according to `/proc/meminfo`, fourteen according to the
control group this shell is in.**

`free` reads `/proc/meminfo`. So does `top`, and so does every monitoring agent
that was written before about 2018. All of them will tell you this machine has
16 GB, and all of them are wrong by two — and on a container with a 512 MB limit
they are wrong by thirty times.

## Why

`/proc` is not namespaced for these files. A container gets its own process
tree, its own network stack and its own mount table, and then `/proc/meminfo`,
`/proc/cpuinfo` and `/proc/loadavg` show it **the host's** figures, because there
is no per-container version of them to show.

The limits are somewhere else entirely, in the control group:

```sh
# cgroup v1 — this machine
/sys/fs/cgroup/memory/<path>/memory.limit_in_bytes
/sys/fs/cgroup/cpu/<path>/cpu.cfs_quota_us
/sys/fs/cgroup/cpu/<path>/cpu.cfs_period_us

# cgroup v2 — anything recent
/sys/fs/cgroup/<path>/memory.max
/sys/fs/cgroup/<path>/cpu.max
```

`/proc/self/cgroup` is how you find `<path>`, which is what the `awk` above is
doing.

## The processor is the same story

```
ana@vm:~$ nproc
4
ana@vm:~$ grep -c ^processor /proc/cpuinfo
4
ana@vm:~$ cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us /sys/fs/cgroup/cpu/cpu.cfs_period_us
-1
100000
```

Four cores, and a quota of `-1` — **unlimited**, so on this machine the two
agree and there is nothing to catch.

They usually do not. A `cfs_quota_us` of `200000` against a `cfs_period_us` of
`100000` means **two cores' worth of processor time per period**, on a machine
that reports 64. And `nproc` says 64, and the JVM sizes its thread pool for 64,
and the Go runtime sets `GOMAXPROCS` to 64, and all of them get throttled.

The symptom is specific and does not look like a shortage: the application is
fast, then stops dead for a few tens of milliseconds, then is fast again.

```
ana@vm:~$ cat /sys/fs/cgroup/cpu/cpu.stat
nr_periods 0
nr_throttled 0
throttled_time 0
nr_bursts 0
burst_time 0
```

**`nr_throttled` and `throttled_time` are the proof.** Zero here, because the
quota is unlimited and there is nothing to throttle against. A rising
`nr_throttled` is a container hitting its quota, and there is no other number on
the machine that says so — `%util`, load average and `top` all look fine, because
from the host's point of view nothing is wrong.

`/sys/fs/cgroup/cpu.stat`, without the `cpu/`, is the same file on cgroup v2.

## Load average is the host's

`/proc/loadavg` is not namespaced either. **The load average you read inside a
container is the whole machine's**, including every other tenant.

So a container showing load 40 may be entirely idle, sharing a host with
somebody having a bad day. And section 178's advice — compare it to the core
count — compares the host's load to the host's cores, which is at least
consistent and tells you nothing about your own container.

## What actually works

| | |
|---|---|
| `/sys/fs/cgroup/.../memory.current` | **your** memory use, v2 |
| `/sys/fs/cgroup/.../memory.max` | your limit |
| `/sys/fs/cgroup/.../cpu.stat` | your processor use and throttling |
| `/sys/fs/cgroup/.../io.stat` | your disk, per device |
| `/proc/pressure/*` | stall time — and **is** namespaced under cgroup v2 |

**Modern monitoring agents read the cgroup files.** `cAdvisor`, the Kubernetes
metrics pipeline, and recent versions of most commercial agents all do. The ones
that do not are the hand-written scripts, and the `free -m | awk` one-liner in
somebody's alerting config is exactly the thing that reports a healthy container
as having 15 GB spare while it is being OOM-killed.

## The first question on a modern machine

**Before any of this lesson: am I in a container, and what does it allow?**

```
ana@vm:~$ systemd-detect-virt --container
docker
```

One word, and it decides whether every other number you are about to read means
anything. It prints `none` on a machine that is not in a container, and
`systemd-detect-virt` on its own reports the *virtualisation* — `kvm`, `qemu`,
`microsoft` — which is a different question and is worth asking too.

Two more, when that one is not available:

```sh
cat /proc/self/cgroup                       # anything but "/" on every line means yes
ls /sys/fs/cgroup/memory.max 2>/dev/null    # exists on a v2 container
```
