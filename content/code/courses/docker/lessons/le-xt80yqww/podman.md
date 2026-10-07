---
title: Podman
version: 2
---

**Podman runs the same images with the same commands, and two architectural differences: there is no
daemon, and it runs without root by default.** Each `podman` command does its work itself and exits,
and the containers it starts belong to the user who started them.

Podman is in Ubuntu's own archive, and on Ubuntu 24.04 that is version 4.9.3, the one below. It
installs beside Docker without touching it:

```sh
sudo apt-get install podman
```

## A registry configuration of its own

Podman reads `registries.conf`, not Docker's `daemon.json`. Ana gives hers the same mirror lesson 6
gave Docker:

```toml
[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "mirror.gcr.io"
```

## Root inside, Ana outside

```
ana@vm:~$ podman --version
podman version 4.9.3
ana@vm:~$ podman run --rm --network none docker.io/library/alpine:3.22 id 2>&1 | grep -v "shared mount"
Trying to pull docker.io/library/alpine:3.22...
Getting image source signatures
Copying blob sha256:53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887
Copying config sha256:c83674e1999044d33d751661371b873539f47e5b5c5ca3320c7e0377acca6238
Writing manifest to image destination
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
ana@vm:~$ podman run --rm --network none docker.io/library/alpine:3.22 cat /proc/self/uid_map 2>&1 | grep -v "shared mount"
         0      30033          1
         1     165536      65536
ana@vm:~$ podman run -d --name sleeper --network none docker.io/library/alpine:3.22 sleep 300 2>&1 | grep -v "shared mount"
175e2046587a9c40349ff1efdccf12c10f2f6f207ade868ac14db6df0eab7c82
ana@vm:~$ ps -o user,pid,args -C sleep
USER       PID COMMAND
ana      28969 sleep 300
ana@vm:~$ podman ps --format "{{.Names}} {{.Image}} {{.Status}}" 2>&1 | grep -v "shared mount"
sleeper docker.io/library/alpine:3.22 Up Less than a second
```

**`id` says root, the user map says otherwise, and `ps` on the host says `ana`.** Read
`/proc/self/uid_map`: UID 0 inside is UID 30033 outside, Ana's own; UIDs 1 to 65536 inside are
165536 and up outside, the range `/etc/subuid` gave her. This is the user namespace lesson 21
described as a daemon option: **with Podman it is the default**, so a process that got past every wall
would arrive on the host as Ana, with nothing she does not already have.

Two notes on what the lab cannot show. Rootless networking needs `/dev/net/tun`, which the lab does
not give an unprivileged user, so these containers run with `--network none`; on a normal machine
they get a network and `-p` works for ports above 1023. And Podman's warning that `/` is not a shared
mount, a property of the lab machine, is filtered out with `grep`.

## The same Dockerfile

```
ana@vm:~$ cd shelf && podman build -q --network none --build-arg VERSION=1.0.0 -t shelf:1.0.0 . 2>&1 | grep -v "shared mount" | tail -1; cd ..
Error: creating build container: short-name "golang:1.25" did not resolve to an alias and no unqualified-search registries are defined in "/home/ana/.config/containers/registries.conf"
```

**Podman refused `golang:1.25`.** Docker reads a name with no registry as Docker Hub (lesson 15);
Podman will not guess, because a short name that resolves to whichever registry answers first is a
way to run somebody else's image. Ana says which registry short names mean:

```toml
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "mirror.gcr.io"
```

```
ana@vm:~$ cd shelf && podman build -q --network none --build-arg VERSION=1.0.0 -t shelf:1.0.0 . 2>&1 | grep -v "shared mount" | tail -1; cd ..
fc1c9fefdd83c88203bea789f26245b6a45e30822e694becf1fd68e80b224e87
ana@vm:~$ podman run -d --name shelf --network none localhost/shelf:1.0.0 2>&1 | grep -v "shared mount"
3dc2b41e879241301284f70845ea9906defecb1112423aa5d8643b458494d520
ana@vm:~$ podman logs shelf 2>&1 | grep -v "shared mount"
2026/10/06 21:44:52 catalogue: built in, 3 books
2026/10/06 21:44:52 shelf 1.0.0 listening on :8080
ana@vm:~$ podman images --format "{{.Repository}}:{{.Tag}}" 2>&1 | grep -v "shared mount"
localhost/shelf:1.0.0
<none>:<none>
docker.io/library/alpine:3.22
docker.io/library/golang:1.25
gcr.io/distroless/static-debian12:nonroot
ana@vm:~$ docker images --format "{{.Repository}}:{{.Tag}}" | grep shelf
shelf:1.0.0
```

**The same Dockerfile built, and `shelf` ran under Podman.** Its image is `localhost/shelf:1.0.0`,
Podman's name for an image built locally, and it lives in Ana's own store: Docker's `shelf:1.0.0` is a
separate copy in a separate place. Podman also runs Compose files through `podman compose`, which hands them to a Compose provider, and its
`docker` compatibility package lets scripts that type `docker` run it unchanged; neither was used here.
