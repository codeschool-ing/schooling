---
title: Two flags that undo everything
version: 1
---

**Everything this course has said about a container's walls stops being true with two things:
`--privileged`, and the Docker socket mounted inside.** Both appear in tutorials, both work, and both
are worth recognising on sight in somebody else's command or Compose file.

## `--privileged`

```
ana@vm:~$ docker run --rm alpine:3.22 sh -c "ls /dev | wc -l; grep CapEff /proc/self/status"
14
CapEff:	00000000a80425fb
ana@vm:~$ docker run --rm --privileged alpine:3.22 sh -c "ls /dev | wc -l; grep CapEff /proc/self/status"
111
CapEff:	000001fffeffffff
```

**From 14 capabilities to 40, every one the daemon itself holds, and from 14 entries in `/dev` to
111**: the host's disks, terminals and every other device. AppArmor and seccomp, the other two
restrictions Docker applies by default, are switched off as well. What is left of the container is a
separate view of processes and network; a process in it can reach the host's hardware directly.

Some tools genuinely need it, such as one that runs Docker inside Docker. Most that ask for it need
one capability or one device, which `--cap-add` and `--device` grant without the rest.

## The Docker socket

Lesson 6 showed that whoever can talk to `/var/run/docker.sock` controls the daemon, which runs as
root, and that being in the `docker` group is therefore root on the machine. **Mounting the socket
into a container gives that same power to whatever runs in it:**

```
ana@vm:~$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock docker:29.8.2-cli docker ps --format "{{.Names}} {{.Image}}"
sharp_herschel docker:29.8.2-cli
```

**The container listed itself, because it was asking the host's daemon.** The same connection can
start containers, with any flags and any mounts the daemon accepts, and the daemon accepts them all.
A container with the socket is a container that can start a privileged one. Never mount it into a
service that faces a network, and treat any image that asks for it with the suspicion you would give
a request for the root password.

## Finding them on a host

Both leave traces in the container's configuration, so a short script finds them:

```sh
#!/bin/sh
# Lists every running container that holds more than a container should.
docker ps -q | xargs docker inspect --format \
  '{{.Name}} privileged={{.HostConfig.Privileged}} caps={{.HostConfig.CapAdd}}{{range .Mounts}}{{if eq .Source "/var/run/docker.sock"}} DOCKER-SOCKET{{end}}{{end}}'
```

```
ana@vm:~$ docker run -d --name ok shelf:1.0.0 >/dev/null; docker run -d --name risky --privileged -v /var/run/docker.sock:/var/run/docker.sock alpine:3.22 sleep 300 >/dev/null
ana@vm:~$ sh audit.sh
/risky privileged=true caps=[] DOCKER-SOCKET
/ok privileged=false caps=[]
```

**`risky` is both, and the script says so in one line.** Run on every host, from a scheduled job or a
monitoring agent, this catches the container somebody started in a hurry. In a cluster the same rule
belongs in the admission policy (lesson 25 of the `kubernetes` course), where such a container is
refused before it starts.
