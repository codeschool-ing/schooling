---
title: A container runtime for lesson 18
version: 1
---

Lesson 18 puts the binary this lesson built into a container image and runs it. That needs a
container runtime, the one thing this course adds to the lab of lesson 1, and lesson 1's table promised
it here. **The runtime this course uses is Podman, from Ubuntu 24.04's archive, run as an ordinary
user.** It needs no daemon and no root: each `podman` command is a program Ana runs, and the
containers it starts belong to her.

## The steps, in brief

One package, and it brings what it needs:

```sh
sudo apt install podman
```

**Rootless containers need a range of user ids of their own.** Inside a container there is a root
user and often others, and Podman maps them onto ids that the kernel lets Ana's account use, listed in
`/etc/subuid` and `/etc/subgid`. Ubuntu's tools for creating accounts give every new one a range of
65,536, so on most machines there is nothing to do. Two helpers that Podman needs come in as
recommended packages, which `apt install` installs unless it is told not to.

## Four checks

As Ana, in any directory:

```
ana@vm:~/small$ podman --version
podman version 4.9.3
ana@vm:~/small$ podman info --format "{{.Host.Security.Rootless}}"
true
ana@vm:~/small$ grep ana /etc/subuid /etc/subgid
/etc/subuid:ana:165536:65536
/etc/subgid:ana:165536:65536
ana@vm:~/small$ apt-cache depends podman | grep -E "uidmap|slirp4netns"
  Recommends: slirp4netns
  Recommends: uidmap
ana@vm:~/small$ podman run --rm --network=none docker.io/library/busybox:1.36 echo ok
ok
```

**`podman version 4.9.3` is the release every transcript in lesson 18 was recorded with.** `Rootless`
says `true`: this Podman runs as Ana, with no daemon behind it. Her range starts at id 165536 and is
65,536 ids long. `apt-cache depends` shows `slirp4netns`, which gives a rootless container its network,
and `uidmap`, whose helpers set up the id mapping, under `Recommends`. The last command started a
container from `busybox`, a tiny image of standard Unix tools on Docker Hub, and printed `ok` from
inside it. The image was already in Ana's storage, so no download shows; Ben's first run, at the end
of this section, shows one.

That last command carries `--network=none`, and on this machine it has to. Without it:

```
ana@vm:~/small$ podman run --rm docker.io/library/busybox:1.36 echo ok; echo $?
Error: /usr/bin/slirp4netns failed: "open(\"/dev/net/tun\"): Permission denied\nWARNING: Support for seccomp is experimental\nWARNING: Support for IPv6 is experimental\nchild failed(1)\nWARNING: Support for seccomp is experimental\nWARNING: Support for IPv6 is experimental\n"
126
ana@vm:~/small$ stat -c "%A %U %n" /dev/net/tun
crw------- root /dev/net/tun
```

**Exit status 126, and a message about `/dev/net/tun`.** A rootless container's network is built by
`slirp4netns` through that device, and on this machine it is readable and writable only by root,
which is a property of the sandbox the lab runs in. On an ordinary Ubuntu installation the plain
command prints `ok`. Every container in lesson 18 runs with `--network=none` for this reason, and
loses nothing by it, since `hits` reads a file and never opens a connection.

## Three ways to have a container runtime

```
ana@vm:~/small$ dpkg-query -W -f="\${Installed-Size} KB  \${Package} \${Version}\n" podman
42601 KB  podman 4.9.3+ds1-1ubuntu0.2
ana@vm:~/small$ apt-cache show --no-all-versions docker.io containerd | grep -E "^(Package|Version|Installed-Size)"
Package: docker.io
Installed-Size: 134107
Version: 29.1.3-0ubuntu3~24.04.2
Package: containerd
Installed-Size: 100805
Version: 2.2.1-0ubuntu1~24.04.3
```

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **Podman** (recommended) | rootless containers, no daemon | 42,601 KB for Podman itself, plus the runtime and helpers it brings | match |
| **Docker Engine** | the `docker` command, and a daemon running as root | 134,107 KB for `docker.io` and 100,805 KB for `containerd`, the archive's candidates | `podman` becomes `docker`; the output differs in places |
| **a virtual machine or an online sandbox** | Podman inside lesson 1's virtual machine, or a container playground in a web page | the virtual machine's disk and memory, or nothing | in the virtual machine, match |

**Docker Engine is the other common choice**, and Ubuntu's archive carries it as `docker.io`. Podman's
command line was made to follow Docker's, so `docker run --rm busybox:1.36 echo ok` is the same
request. The difference is the daemon: `docker` asks a service running as root to do the work, and
being allowed to ask it, by being in the `docker` group, amounts to being root on that machine. None
of the commands in this course was run with Docker.

A virtual machine is lesson 1's path again, with the steps above inside it, and it is the right one
on Windows and macOS, where containers need a Linux kernel to run on. Online playgrounds such as Play
with Docker exist, but they come and go and none of this course depends on one.

## When it fails

The failure that stops most people is an account with no id range: one created by a tool that does
not write `/etc/subuid`, or a machine where somebody tidied the file. Here it is on a second account,
`ben`, whose lines were taken out of both files. `sed` strips the timestamp Podman puts at the start
of each log line:

```
ben@vm:~$ grep ben /etc/subuid /etc/subgid; echo $?
1
ben@vm:~$ podman run --rm --network=none docker.io/library/busybox:1.36 echo ok 2>&1 | sed "s/^time=\"[^\"]*\" //"
level=warning msg="\"/\" is not a shared mount, this could cause issues or missing mounts with rootless containers"
level=error msg="cannot find UID/GID for user ben: no subuid ranges found for user \"ben\" in /etc/subuid - check rootless mode in man pages."
level=warning msg="Using rootless single mapping into the namespace. This might break some images. Check /etc/subuid and /etc/subgid for adding sub*ids if not using a network user"
Trying to pull docker.io/library/busybox:1.36...
Getting image source signatures
Copying blob sha256:034d6572bf287fa79604fee9be062f0683809ae3a3685bc7b0e17bd1c48c50e8
Error: copying system image from manifest list: writing blob: adding layer with blob "sha256:034d6572bf287fa79604fee9be062f0683809ae3a3685bc7b0e17bd1c48c50e8": processing tar file(potentially insufficient UIDs or GIDs available in user namespace (requested 65534:65534 for /home): Check /etc/subuid and /etc/subgid if configured locally and run "podman system migrate": lchown /home: invalid argument): exit status 1
```

**`no subuid ranges found for user "ben"` is the cause, and everything after it is the consequence.**
Podman falls back to mapping one id, Ben's own. The image's files belong to several owners, `nobody`
among them, with id 65534, and there is nothing to map that owner to, so unpacking the image fails
with `insufficient UIDs or GIDs`. The fix is a range that overlaps nobody else's. Ana's ends at
231071, so Ben's can start at 231072:

```sh
sudo usermod --add-subuids 231072-296607 --add-subgids 231072-296607 ben
```

Then, as Ben, `podman system migrate` makes Podman pick up the new range, and the same command works:

```
ben@vm:~$ grep ben /etc/subuid /etc/subgid
/etc/subuid:ben:231072:65536
/etc/subgid:ben:231072:65536
ben@vm:~$ podman system migrate
ben@vm:~$ podman run --rm --network=none docker.io/library/busybox:1.36 echo ok 2>&1 | sed "s/^time=\"[^\"]*\" //"
level=warning msg="\"/\" is not a shared mount, this could cause issues or missing mounts with rootless containers"
Trying to pull docker.io/library/busybox:1.36...
Getting image source signatures
Copying blob sha256:034d6572bf287fa79604fee9be062f0683809ae3a3685bc7b0e17bd1c48c50e8
Copying config sha256:b116e155074440ffd9e449559433feb4cd2341eb3554b1da1c638c976e56451d
Writing manifest to image destination
ok
```

This time the image was pulled and unpacked, and `ok` came from inside the container. The first line
is a warning about how this sandbox mounts its root filesystem; it shows for Ben's new account and
stops nothing. With `podman run ... echo ok` printing `ok`, the lab is ready for lesson 18.
