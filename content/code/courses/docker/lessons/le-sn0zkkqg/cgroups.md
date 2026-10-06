---
title: Cgroups, the walls that limit use
version: 1
---

**A control group (cgroup) is a set of processes the kernel counts together and can hold to a
limit together**: memory, CPU time, the number of processes, disk throughput. Namespaces decide
what a container can see; cgroups decide how much it can take. Without one, a single container can
use all the memory on the machine and starve every other one.

Ana starts a container with three limits: 64 MB of memory, half of one processor, and at most 20
processes. Then she asks the kernel which cgroups its process is in:

```
ana@vm:~$ docker run -d --name capped --memory 64m --cpus 0.5 --pids-limit 20 alpine:3.22 sleep 600
01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
ana@vm:~$ ID=$(docker inspect -f "{{.Id}}" capped); grep -E ":(memory|pids|cpu):" /proc/$(docker inspect -f "{{.State.Pid}}" capped)/cgroup
8:pids:/docker/01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
4:memory:/docker/01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
1:cpu:/docker/01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
```

Each line is one **controller**, the part of the kernel that limits one resource, followed by the
group the process is in: `/docker/` and the container's full id. Docker made one group per
container, under a group of its own.

## The limits are files

On this machine every controller is a directory under `/sys/fs/cgroup`, and every limit is a file
in it. Ana reads the three she set:

```
ana@vm:~$ cat /sys/fs/cgroup/memory/docker/$ID/memory.limit_in_bytes
67108864
ana@vm:~$ cat /sys/fs/cgroup/cpu/docker/$ID/cpu.cfs_quota_us /sys/fs/cgroup/cpu/docker/$ID/cpu.cfs_period_us
50000
100000
ana@vm:~$ cat /sys/fs/cgroup/pids/docker/$ID/pids.max
20
```

- **`memory.limit_in_bytes`** is 67108864, which is 64 × 1024 × 1024: the 64m she asked for.
- **`cpu.cfs_quota_us`** is 50000 out of a **`cpu.cfs_period_us`** of 100000: in every tenth of a
  second, the container's processes may use 50 milliseconds of CPU in total. That is what
  `--cpus 0.5` means. It is a share of time, not a particular processor, and lesson 2 showed that
  `nproc` cannot tell the difference.
- **`pids.max`** is 20.

**These paths are cgroup v1, which the lab machine runs.** Most current distributions use cgroup
v2, where all controllers share one tree, and the same three limits appear as `memory.max`,
`cpu.max` and `pids.max` in a single directory per container. The idea is identical and only the
file names move; Docker writes whichever the machine has.

## Hitting a limit

**The process limit refuses a new process.** Ana asks the capped container to start 30 `sleep`
processes in the background:

```
ana@vm:~$ docker exec capped sh -c "for i in \$(seq 30); do sleep 5 & done; wait" 2>&1 | tail -3
sh: can't fork: Resource temporarily unavailable
ana@vm:~$ cat /sys/fs/cgroup/pids/docker/$ID/pids.current
19
```

The shell could not fork any further, and stopped. Counting the `sleep 600` that is the container's
main process and the shell itself, the twentieth process was the last one allowed. The shell gave
up, and the `sleep` processes it had already started were still running, so the count afterwards
reads 19. A program that forks out of control inside a container stops at the limit instead of
taking the machine down with it.

**The memory limit kills.** Ana runs a shell loop that doubles a string forever, so its memory use
doubles each turn, in a container limited to 64 MB:

```
ana@vm:~$ docker run --name hog --memory 64m alpine:3.22 sh -c "x=a; while true; do x=\$x\$x; done"
ana@vm:~$ echo $?
137
ana@vm:~$ docker inspect -f "OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}" hog
OOMKilled=true ExitCode=137
```

`docker run` returned **137**, and Docker recorded **`OOMKilled=true`**. When a cgroup reaches its
memory limit and the kernel cannot reclaim enough, the kernel's out-of-memory killer ends a process
in it with `SIGKILL`, signal 9, and 137 is how a shell reports that: 128 plus the signal number.
**A container that exits with 137 and `OOMKilled=true` ran out of memory**; with 137 and `false`,
something else sent it `SIGKILL`. Lesson 17 shows how to pick a limit that does not end there.

The CPU limit does neither: a container at its quota is not refused or killed, only made to wait
for the next period. The program runs slower, which is often harder to notice than a crash.
