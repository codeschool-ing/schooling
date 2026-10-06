---
title: The price of sharing a kernel
version: 1
---

**Sharing the kernel is where a container's speed comes from, and it is also the source of every
limit this section lists.** None of them is a bug. Each follows from the one fact the previous
section showed: there is one kernel, and every container uses it.

## The walls do not hide the machine's size

Ana starts a container limited to 256 MB of memory, and asks it how much memory there is:

```
ana@vm:~$ free -m
               total        used        free      shared  buff/cache   available
Mem:           16094         726       13625          13        2039       15368
Swap:              0           0           0
ana@vm:~$ docker run --rm --memory 256m alpine:3.22 free -m
              total        used        free      shared  buff/cache   available
Mem:          16095         439       13617          14        2039       15360
Swap:             0           0           0
```

**The limited container reports the host's 16 GB.** `free` reads `/proc/meminfo`, and that file
describes the kernel's memory, which is the whole machine's; the limit of 256 MB is enforced
separately, by a cgroup, and `free` knows nothing about it. The processor count behaves the same
way:

```
ana@vm:~$ nproc
4
ana@vm:~$ docker run --rm --cpus 1 alpine:3.22 nproc
4
```

`--cpus 1` limits the container to one processor's worth of time, and `nproc` still answers 4.

**This catches real programs.** A runtime that sizes itself from what it sees can size itself for the whole host inside a container
limited to a fraction of it, and then hit the limit: a thread pool with one thread per processor, a
heap that takes a quarter of the memory. Modern runtimes
read the cgroup limits for this reason, and the JVM does it by default since Java 10. A program
that reads `/proc/meminfo` itself still gets the host's number. Lesson 4 shows where the real limit
lives, and lesson 17 how to set one.

## A binary has to match the processor

**An image carries programs compiled for one processor architecture, and the shared kernel cannot
run anything else.** The lab machine is `x86_64`, the architecture Docker calls `amd64`. Ana asks
for the `arm64` variant of the same image, which is what an Apple silicon Mac or a Raspberry Pi
runs:

```
ana@vm:~$ docker info --format "{{.OSType}}/{{.Architecture}}"
linux/x86_64
ana@vm:~$ docker run --rm --platform linux/arm64 alpine:3.22 uname -m
exec /bin/uname: exec format error
```

`exec format error` is the kernel saying the file is not a program for this processor. The image
was found and unpacked; it is the first instruction that cannot be run. Docker Desktop on an Apple
silicon Mac runs the reverse case for `amd64` images through an emulator, and Linux can do the
same with QEMU registered as a handler for foreign binaries. Neither is set up on the lab machine,
which is why it fails here. Emulation works and is slow, and lesson 5 comes back to it, because it
is the first surprise of many people who move to a new Mac.

## A Linux kernel runs Linux containers

**A container's operating system is the kernel's operating system.** Linux containers need a Linux
kernel, and Windows containers, which exist, need a Windows kernel. On a Mac or a Windows laptop,
Docker runs Linux containers by starting a small Linux virtual machine and running them inside it;
that is lesson 5. And for the same reason a container cannot load a kernel module of its own or
pick a different kernel version: there is only the one.

## The boundary is thinner than a VM's

**A VM's boundary is a hypervisor emulating hardware; a container's is a set of kernel features
around an ordinary process.** Both are real boundaries, and the container's is the thinner one: a
flaw in the kernel is a flaw in every container's wall at once, and the kernel offers far more ways
in than a virtual network card does. That is why a cloud provider separates two customers with
VMs, and why lesson 21 is about narrowing what a containerised process may ask the kernel for.

## Choosing

| you need | use |
| --- | --- |
| the whole machine's performance for one workload, like a large database server | bare metal, or a VM sized to the machine |
| a different operating system, or a different kernel, from the host | a virtual machine |
| strong separation between parties who do not trust each other | a virtual machine, with containers inside if you like |
| many programs with conflicting dependencies on one machine, starting fast | containers |
| the same program, packaged once, on a laptop, a CI runner and a server | containers |
