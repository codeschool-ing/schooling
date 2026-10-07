---
title: Namespaces, the walls that limit sight
version: 1
---

**A namespace gives a process its own copy of one kind of thing the kernel keeps, so that it sees
that copy and not the host's.** There is one kind for process ids, one for network interfaces,
one for the host name, one for mounts, and a few more. A container is a process placed in a set of
new ones at the moment it starts. Nothing is hidden by Docker after the fact; the kernel simply
answers each question from the namespace the process is in.

Ana starts a container and asks for its main process's number on the host. `--hostname` gives it a
name of its own, which will be useful in a moment:

```
ana@vm:~$ docker run -d --name web --hostname web alpine:3.22 sleep 600
918c0d43edc431356c583e79dfb9cdeff3c0840743d1ab092f4964fa54e439ba
ana@vm:~$ PID=$(docker inspect -f "{{.State.Pid}}" web); echo $PID
20052
```

## Every process carries a list of namespaces

Under `/proc/<pid>/ns/` the kernel lists the namespaces a process belongs to, one link per kind,
each pointing at a namespace by number. Ana reads four of them for the container's process, and the
same four for her own shell, `$$`:

```
ana@vm:~$ sudo readlink /proc/$PID/ns/pid /proc/$PID/ns/net /proc/$PID/ns/uts /proc/$PID/ns/mnt
pid:[4026532265]
net:[4026532266]
uts:[4026532263]
mnt:[4026532262]
ana@vm:~$ readlink /proc/$$/ns/pid /proc/$$/ns/net /proc/$$/ns/uts /proc/$$/ns/mnt
pid:[4026531836]
net:[4026531833]
uts:[4026531838]
mnt:[4026531832]
```

**Four different numbers for each kind.** Two processes in the same namespace show the same number,
so the container and Ana's shell share none of these four. Reading another user's process needs
`sudo`; the container's `sleep` runs as root.

`lsns` lists every namespace of a process with its type, and how many processes are in each:

```
ana@vm:~$ sudo lsns -p $PID
        NS TYPE   NPROCS   PID USER COMMAND
4026531835 cgroup     89     2 root kthreadd
4026531837 user       89     2 root kthreadd
4026532262 mnt         1 20052 root sleep 600
4026532263 uts         1 20052 root sleep 600
4026532264 ipc         1 20052 root sleep 600
4026532265 pid         1 20052 root sleep 600
4026532266 net         1 20052 root sleep 600
4026532317 time        1 20052 root sleep 600
```

Six namespaces were made for this container, each holding exactly one process, `sleep 600`: mount,
UTS (the host name), IPC, PID, network and time. **Two were not**: the `cgroup` and `user` rows
are shared with 89 processes on the host, starting with `kthreadd`, the kernel's own. The user
namespace matters most of the two: Docker does not give containers one by default, so **root
inside this container is the same root as on the host**, held back only by the other walls.
Lesson 3's runc bundle had one, and lesson 21 comes back to what that changes.

## What each wall looks like from inside

The host name is the simplest. Ana's machine is `vm`; the container answers with the name it was
given:

```
ana@vm:~$ hostname
vm
ana@vm:~$ docker exec web hostname
web
```

The network is the most visible. Every network interface is listed under `/sys/class/net`:

```
ana@vm:~$ docker exec web ls /sys/class/net
eth0
lo
ana@vm:~$ ls /sys/class/net
docker0
eth0
ifb0
ifb1
lo
vethb30f68a
```

Inside, two interfaces: `lo` and an `eth0` of its own. Outside, the host's list, including
`docker0`, the bridge Docker made, and a `veth` interface, which is the host's end of the virtual
cable whose other end is the container's `eth0`. Lesson 23 follows that cable.

## Stepping through the wall

`nsenter` runs a program inside another process's namespaces, chosen kind by kind. This is,
underneath, what `docker exec` does. Ana enters only the UTS and network namespaces of the
container, and runs the host's own `ip`, a program the container's image does not even have in
this form:

```
ana@vm:~$ sudo nsenter --target $PID --uts --net sh -c "hostname; ip -brief addr"
web
lo               UNKNOWN        127.0.0.1/8 
eth0@if97        UP             172.17.0.2/16 
```

A host program, seeing the container's host name and the container's network: its own loopback and
an `eth0` with the address `172.17.0.2`. Everything else, the files, the process list, stayed the
host's, because those namespaces were not entered. **A namespace is a property of a process, and a
process can be put into any combination of them.**

Lesson 1 drew the PID namespace as a wall around one process. The same picture holds for each
kind, with one wall per kind, and a container is the case where all of them are put up at once.
