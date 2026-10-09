---
title: When the setup fails
version: 1
---

A lab that fails to build is where most people stop, so here are the failures this one has actually
produced, with what each message means.

**`RTNETLINK answers: File exists`.** The script tried to add an address or a route that your computer
already has. It happened while this course was being recorded: the recording machine already used
`192.0.2.0/24` for its own network, which is why the lab's middle network is `198.51.100.0/24` instead.
Run `ip route` and look for any of the lab's four networks (`203.0.113.0/24`, `198.51.100.0/24`,
`192.168.20.0/24`, `192.168.99.0/24`). If one is already there, your computer is using it; change that
network in every line of the script where it appears.

**`Cannot create namespace file "/run/netns/fw": File exists`.** A previous `up` was interrupted and left
machines behind. `bash soclab.sh down`, then `up` again.

**`Operation not permitted`** on the first `ip` command. You are not root (`sudo -i` first), or you are
inside a container that is not allowed to create namespaces, which is common for online "playground"
shells. Use a virtual machine instead.

**`ts: command not found`** or **`nfpcapd: command not found`.** A package from the `apt install` line is
missing. `moreutils` provides `ts`, and `nfdump` provides `nfpcapd`.

**The SSH log stays empty.** Check that the servers run with `pgrep -a sshd`: you should see one listening
on `198.51.100.22` and one on `192.168.20.10`. If `/run/sshd` was removed by a reboot, `down` and `up`
recreate it.

When a message is not on this list, read it for the name of the command that failed; the script stops
there, so the last line printed is the one to search for. And restore the snapshot you took before the
lesson: in a virtual machine, that costs seconds.
