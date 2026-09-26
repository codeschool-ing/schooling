---
title: What a container sees
version: 1
---

From inside, a container looks like a small system of its own:

```
ana@host:~$ sudo podman run --rm docker.io/library/ubuntu:24.04 bash -c "echo my pid is \$\$; hostname; ls /"
my pid is 1
96e7cc50c11d
bin
boot
dev
etc
home
lib
lib64
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

Its shell is **process 1**, the first process of its world, although on the host it is one process among
many. It has **its own hostname**, the container's id. And it has **its own files**, a whole
Ubuntu directory tree, which came from the image. That is what the kernel's *namespaces* do: each
gives a group of processes its own view of one thing, the process list, the name, the files, the
network, while all of them run on the same kernel.

The image is small because it holds no kernel and no firmware, only files: `ubuntu:24.04` is
80.7 MB, where the lab's Ubuntu disk holds a 3.5 GiB system. And **the image does not change**: the
container writes into a layer of its own on top of it, lesson 1's overlay again, and that layer goes
when the container is removed.
