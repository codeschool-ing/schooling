---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up here, on an error about a machine they have
only just built. These are the failures that actually happen, roughly in the order you would meet
them, with what each one means. Where the machine this course was recorded on can produce one, it
is shown as that machine printed it.

**The VM will not start, and the message mentions virtualisation, VT-x, AMD-V or SVM.** The
processor's virtualisation support is switched off in the computer's firmware. It is a setting in
the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and many laptops ship with
it off. No program can switch it on for you. Docker Desktop on Windows fails on the same setting,
as the section on installing it said.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than the default wait. `multipass launch` accepts
`--timeout` in seconds; give it 1800 and let it finish.

**`apt-get` says it could not get a lock.** Ubuntu runs its own updates in the first minutes after
a machine boots, and only one program may install packages at a time. Wait a few minutes and run
the command again. Deleting the lock file is the advice you will find online, and it is how a
package database gets corrupted.

**`permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`.**
The engine is running and refused you. Either your user is not in the `docker` group, or it is and
you have not logged in again since; `id -nG` without `docker` in it says which. Leave the shell and
open it again. Two fixes you will be offered are both wrong: `sudo chmod 666` on the socket gives
every account on the machine what lesson 6 shows the group amounts to, and `sudo` before every
`docker` leaves files owned by root in your own directories.

**`failed to connect to the docker API`.** Nothing is listening on the socket at all: the engine is
stopped, or `docker` is pointed at another engine. The previous section ends on that message and
what it means; on the VM, `sudo systemctl start docker` starts the engine.

**`429 Too Many Requests` from Docker Hub.** Docker Hub limits how many images an address may pull
without logging in, and a school, an office or a café shares one address between everybody behind
it, so the limit arrives sooner there than at home. The lab met it while this lesson was being
written: the same `docker buildx imagetools inspect` answered 429 one minute and worked the next.
`docker login` with a free Docker account raises the limit, waiting brings it back, and a registry
mirror, which lesson 6 shows in the daemon's configuration, sends the pulls somewhere else.

**A program inside a container cannot verify a certificate.**

```
ana@vm:~$ docker run --rm alpine:3.22 wget -q -O /dev/null https://dl-cdn.alpinelinux.org/alpine/
28DB5418077F0000:error:0A000086:SSL routines:tls_post_process_server_certificate:certificate verify failed:ssl/statem/statem_clnt.c:2124:
ssl_client: SSL_connect
wget: error getting response: Connection reset by peer
```

This is the lab's own network, and it is common at work and at school: the network opens encrypted
connections, inspects them and signs them again with a certificate of its own. The machine was told
to trust that certificate, so `docker pull` works. A container brings its own list of trusted
certificates, which does not have it, and refuses, correctly. Trying the same command on another
network, a phone's hotspot for instance, settles whether this is the cause. The way out is the
network's certificate, from whoever runs it, added to the image. Switching the check off
(`wget --no-check-certificate`, `curl -k`) is never the way out: it accepts whoever answers. This is
why some later lessons say a step needing the network inside a container was not run here, and why
`shelf` keeps its dependency in the project.

**`port is already allocated`.**

```
ana@vm:~$ docker run -d --name one -p 127.0.0.1:8080:8080 alpine:3.22 sleep 600
c255de10585a3fc1fb896a68b1e272ff0ee8b455892a43b2fed4d6eb33d4338a
ana@vm:~$ docker run -d --name two -p 127.0.0.1:8080:8080 alpine:3.22 sleep 600
6a5b8277272753750a73b1f9ac64f08ad2717be39ec408a4b9f1659f0e71cef4
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint two (5d0ab47a76029ff0445b66c2bd7e330c699bf22355a714947e01d1d6b444a4ba): Bind for 127.0.0.1:8080 failed: port is already allocated

Run 'docker run --help' for more information
ana@vm:~$ docker ps -a --format "{{.Names}}  {{.Status}}  {{.Ports}}"
two  Created  
one  Up Less than a second  127.0.0.1:8080->8080/tcp
ana@vm:~$ docker rm -f one two
one
two
```

Only one thing may hold an address and a port, and here a container from earlier holds it. `docker
ps` names it. Notice the id printed before the error: **the second container was created anyway**,
and sits in `Created` with its name taken, so running the same command again fails on the name
instead. `docker rm` frees both. When `docker ps` shows nothing on the port, a program outside
Docker holds it, and lesson 17 shows how to find it with `ss`.

**`no space left on device`.** Images, stopped containers and the build cache add up, and the
course pulls about 4.5 GB of images before counting what you build. `docker system df` says where the
space went, lesson 22 shows how to give it back, and `multipass stop vm` followed by
`multipass set local.vm.disk=40G` gives the VM a bigger disk.

**And when nothing else works**, delete the machine and build it again: `multipass delete --purge vm`,
then the commands of the first section. It feels like giving up. It is what professionals do with
a machine whose state nobody can explain any more, and it is why this lesson builds everything from
commands rather than from settings clicked once. Copy out anything you want to keep first; from
lesson 11 on, that is `~/shelf`.
