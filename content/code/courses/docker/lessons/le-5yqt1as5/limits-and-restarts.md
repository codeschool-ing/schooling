---
title: Limits and restart policy
version: 1
---

**A container with no limits may use all of the machine.** Lesson 4 showed the cgroups that can stop
it; `docker run` sets them with a few flags, and by default sets none.

## By default, the whole machine

```
ana@vm:~$ docker run -d --name web shelf:1.0.0
c8417bdbc5e2e3dc3487d69fa4d85e4cc670a4288f987e17199bbdcc4eb85bf5
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}"
NAME      CPU %     MEM USAGE / LIMIT     PIDS
web       0.00%     2.172MiB / 15.72GiB   8
```

`LIMIT 15.72GiB` is the machine's memory: `shelf` could take all of it. One leaking program in one
container can starve every other container and the host itself.

## Memory: the kernel enforces it

Ana runs a program that does nothing but allocate, `tail` reading `/dev/zero`, which never finds a
line ending and keeps buffering, with a limit of 64 MB:

```
ana@vm:~$ docker run -d --name hog --memory 64m alpine:3.22 tail /dev/zero
018583260c9147c0dd7e78545f25a36486993a842e7405ef9d05f4ddca2e7d04
ana@vm:~$ docker inspect hog --format "{{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}"
exited exit=137 oom=true
```

**Exit code 137 and `OOMKilled: true`**: the kernel's out-of-memory killer ended the process when it
reached the limit, within the four seconds before Ana looked. 137 is 128 plus 9, the number of `SIGKILL`.
The program got no warning and no chance to clean up, which is why a memory limit is sized from what
the program actually uses, with room to spare, rather than guessed low.

## CPU: the scheduler shares it out

Two containers spin in an endless loop, one with `--cpus 0.5`:

```
ana@vm:~$ docker run -d --name spin --cpus 0.5 alpine:3.22 sh -c "while :; do :; done"
18262e895c7ae534e8fbbffecf6019fd62bb3142a5319486b0502298efcb13ab
ana@vm:~$ docker run -d --name spin-free alpine:3.22 sh -c "while :; do :; done"
bfd6abd6b5ad65c16a48294167fb32ee8e469fd4bc7c3cd9e11c093c655ecd72
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"
NAME        CPU %
spin-free   99.38%
spin        49.21%
```

**Half a CPU, as asked, against a whole one without the limit.** A CPU limit never kills anything; it
slows the program down. Too low a value shows up as slow responses, not as errors.

## The three that `shelf` gets

```
ana@vm:~$ docker run -d --name web --memory 64m --cpus 0.5 --pids-limit 64 -p 127.0.0.1:8080:8080 shelf:1.0.0
df9ebf3a18dbf0db09983274100a27510c16a12de78f3dc9ebae0bf08905afe2
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}"
NAME      CPU %     MEM USAGE / LIMIT   PIDS
web       0.00%     2.156MiB / 64MiB    7
ana@vm:~$ docker inspect web --format "memory={{.HostConfig.Memory}} nanocpus={{.HostConfig.NanoCpus}} pids={{.HostConfig.PidsLimit}}"
memory=67108864 nanocpus=500000000 pids=64
```

`--memory 64m` for a program that uses about 2 MiB, `--cpus 0.5`, and **`--pids-limit 64`, which caps
the number of processes and threads**; `shelf` runs 7. Each of the three stops one runaway program
from becoming the whole machine's problem.

## Restart policy

**When the process in a container exits, the container stops, and by default it stays stopped.**
`shelf.env` names a database that does not exist, so `shelf` exits with status 1 straight away:

```
ana@vm:~$ docker run -d --name web --env-file shelf.env shelf:1.0.0
b6b2ea724905b02bb70e0e142e76a62a2b7e73a3df90d1210efd11b2007a356f
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Exited (1) 3 seconds ago
```

`--restart` tells the daemon what to do instead:

| policy | restarts when the process exits | after `docker stop` |
| --- | --- | --- |
| `no` | never, the default | stays stopped |
| `on-failure[:N]` | with a non-zero status, at most N times | stays stopped |
| `always` | always | stays stopped until the daemon restarts, then starts again |
| `unless-stopped` | always | stays stopped, including after the daemon restarts |

```
ana@vm:~$ docker run -d --name web --restart on-failure:3 --env-file shelf.env shelf:1.0.0
aa945fee58452b63414db412d62022c0e8fd940b955b5d9750fb044c445b9856
ana@vm:~$ docker inspect web --format "{{.State.Status}} restarts={{.RestartCount}} exit={{.State.ExitCode}}"
exited restarts=3 exit=1
ana@vm:~$ docker logs web 2>&1 | grep "database:" | cut -c1-47
2026/10/06 17:56:40 database: failed to connect
2026/10/06 17:56:40 database: failed to connect
2026/10/06 17:56:41 database: failed to connect
2026/10/06 17:56:41 database: failed to connect
```

**Four attempts in about a second, then the daemon gave up**: the first start and three restarts,
with a short delay before each that doubles every time. `on-failure:3` suits a program that fails
for a reason that might pass; for a database that is simply missing, more restarts only produce more
log lines. The real fix is starting things in the right order, and lesson 19 does that with Compose.

`unless-stopped` is the usual choice for a service that should come back with the machine:

```
ana@vm:~$ docker run -d --name web --restart unless-stopped -p 127.0.0.1:8080:8080 shelf:1.0.0
aa1781b48e80f0053b9c3d19e6136aa67844812bdb2bbef0b80d3b511b5de9ba
ana@vm:~$ docker stop web
web
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Exited (0) 3 seconds ago
ana@vm:~$ docker inspect web --format "{{.HostConfig.RestartPolicy.Name}}"
unless-stopped
ana@vm:~$ docker update --restart no web && docker inspect web --format "{{.HostConfig.RestartPolicy.Name}}"
web
no
```

`docker stop` is respected, and `docker update` changes the policy of an existing container without
recreating it. The rows of the table about the daemon restarting were not reproduced in the lab;
they are what Docker's documentation states for each policy.
