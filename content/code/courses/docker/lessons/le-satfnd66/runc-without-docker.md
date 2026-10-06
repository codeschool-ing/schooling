---
title: A container without Docker
version: 1
---

**The runtime specification needs two things to start a container: a directory to use as the root
filesystem, and a `config.json` that describes the process.** Together they are called a
**bundle**. Docker builds one for every container it starts and hands it to runc. Ana can build one
herself and leave Docker out of the starting altogether.

## The filesystem

`docker export` writes out the files of a container as a tar archive; `docker create` makes a
container without starting it, just to have something to export. Ana unpacks the result into
`bundle/rootfs`:

```
ana@vm:~$ mkdir -p bundle/rootfs
ana@vm:~$ docker export $(docker create alpine:3.22) | tar -x -C bundle/rootfs
ana@vm:~$ ls bundle/rootfs
bin
dev
etc
home
lib
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
```

That is Alpine's root directory, unpacked from the layer of the previous section. Docker's part
ends here.

## The configuration

`runc spec` writes a default `config.json`. `--rootless` adjusts it for an ordinary user, which Ana
is: no `sudo` anywhere in this section.

```
ana@vm:~$ cd bundle && runc spec --rootless && ls
config.json
rootfs
ana@vm:~/bundle$ jq '{ociVersion, process: {terminal: .process.terminal, args: .process.args, cwd: .process.cwd}, root, hostname}' config.json
{
  "ociVersion": "1.3.0",
  "process": {
    "terminal": true,
    "args": [
      "sh"
    ],
    "cwd": "/"
  },
  "root": {
    "path": "rootfs",
    "readonly": true
  },
  "hostname": "runc"
}
```

The configuration answers the questions the previous section's image configuration also answered,
in the runtime's own terms: which process to run (`args`, here `sh`), in which directory, with
which filesystem as root (`rootfs`, mounted read-only), under which host name (`runc`). And it
lists the walls:

```
ana@vm:~/bundle$ jq -c '.linux.namespaces' config.json
[{"type":"pid"},{"type":"ipc"},{"type":"uts"},{"type":"mount"},{"type":"user"}]
```

**Five namespaces: processes, inter-process communication, host name, mounts and users.** Each line
is one wall from lesson 1, asked for by name. There is no `network` namespace in the rootless
default, so this container would share Ana's network. Lesson 4 looks at each kind.

## Running it

The default process is an interactive shell attached to a terminal. Ana swaps it for a command
that prints three things and exits, turns the terminal off, and runs the bundle:

```
ana@vm:~/bundle$ jq '.process.terminal = false | .process.args = ["sh", "-c", "hostname; cat /etc/alpine-release; ps"]' config.json > c.json && mv c.json config.json
ana@vm:~/bundle$ runc --root /tmp/runc-ana run demo
runc
3.22.6
PID   USER     TIME  COMMAND
    1 root      0:00 ps
ana@vm:~/bundle$ echo $?
0
```

**A container, started with no Docker involved.** It printed the host name from `config.json`,
`runc`, rather than Ana's machine's; the Alpine version from its own filesystem; and a process list
with exactly one entry, PID 1, because it has its own process namespace. `ps` reports the user as
`root`, though Ana started it as herself: the user namespace maps her ordinary account to root
inside, and outside it is still only Ana. Lesson 21 returns to that mapping, because it is one of
the strongest walls there is.

## What Docker adds on top

If runc can start a container, what is Docker for? Everything around the start:

| Docker does | runc alone |
| --- | --- |
| pulls images from a registry and checks their digests | has a directory and nothing else |
| builds the root filesystem from layers, sharing them between containers | uses whatever directory it is given |
| writes `config.json` from `docker run`'s flags | reads a `config.json` somebody else wrote |
| creates networks, publishes ports, attaches volumes | starts a process in namespaces |
| keeps a record of containers, their logs and their states | forgets the container when it exits |
| answers an API that other tools call | has a command line |

**The runtime is the smallest piece and the one everything rests on.** Docker, containerd,
Podman and Kubernetes are all, in the end, ways of writing that `config.json`.
