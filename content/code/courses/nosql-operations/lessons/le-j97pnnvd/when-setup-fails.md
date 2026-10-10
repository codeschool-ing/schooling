---
title: When the setup does not work
version: 1
---

Everything in the last section can fail, and nearly every failure prints a sentence that says which
part. **Read the sentence before trying anything else.** Each failure below was caused on purpose in
the lab, so what you see is the real message.

## `permission denied while trying to connect to the docker API`

Every `docker` command answers with that sentence, followed by the path of the daemon's socket,
`/var/run/docker.sock`. The daemon is running and refuses you: your user is not in the `docker`
group, or it was added and this shell was opened before. Run `id -nG`. If `docker` is not in the
list, leave the shell and open it again; if it still is not, the `usermod` line was skipped.

## `Conflict. The container name "/mongo" is already in use`

```
ana@vm:~$ docker run -d --name mongo --network nosql mongo:8.0
docker: Error response from daemon: Conflict. The container name "/mongo" is already in use by container "5a79e581561e308a9b5e12e43035de3951093e0c5a43402a481e4aeecca4fd92". You have to remove (or rename) that container to be able to reuse that name.

Run 'docker run --help' for more information
```

You are running a `docker run` from a lesson for the second time, and the first container is still
there, running or stopped. **This is the commonest message in the course**, because many lessons
start their servers fresh. Either keep the one you have (`docker start mongo`), or remove it and run
the line again (`docker rm -f mongo`), and decide knowing that removing it removes its data.

## `network nosql-lab not found`

```
ana@vm:~$ docker run -d --name redis --network nosql-lab redis:7.4
e5d04362abb0c29db3de51006e4cf46c5e431541bea645d10bc20e18122297fd
docker: Error response from daemon: failed to set up container networking: network nosql-lab not found

Run 'docker run --help' for more information
ana@vm:~$ docker ps -a --filter name=redis --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
redis     Created
ana@vm:~$ docker rm redis
redis
```

A typo in the network name, or `docker network create nosql` never ran on this machine. **Notice the
long id printed before the error**: the container was created and only failed to start, so its name
is now taken by a container in state `Created`. Fix the name, `docker rm` the half-made container,
and run the line again; otherwise the next attempt meets the conflict above.

## `not found` when pulling

```
ana@vm:~$ docker pull mongo:8.0.99
Error response from daemon: failed to resolve reference "docker.io/library/mongo:8.0.99": docker.io/library/mongo:8.0.99: not found
```

The registry answered and has no image with that tag. The course uses `mongo:8.0`, `redis:7.4` and
`cassandra:5.0`, and every one of those is a tag Docker Hub publishes. A pull that hangs instead, or
fails with a word like `timeout` or `TLS`, is a different problem: the VM cannot reach the
internet, and `curl -sI https://registry-1.docker.io/v2/` from the VM tells you whether it can.

## `Connection refused` from `cqlsh`

The previous section showed it: Cassandra is still starting. Wait with the `until` loop and try
again. If two minutes pass and it still refuses, the container has probably stopped, which is the
next case.

## Cassandra exits with code 137

```
ana@vm:~$ docker run -d --name cassandra --network nosql --memory 400m cassandra:5.0
c9e234cf64ee21e5536c4cd3341f104f617caf1a4330b8dafa41bb629622e963
ana@vm:~$ docker ps -a --filter name=cassandra --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
cassandra   Exited (137) 59 seconds ago
ana@vm:~$ docker inspect --format "{{.State.OOMKilled}}" cassandra
true
```

This one was caused by capping the container at 400 MB **and leaving out the two `-e` settings**,
so Cassandra sized its heap for the whole machine and was killed for using more than it was allowed.
Exit code 137 is a process killed by signal 9, and `OOMKilled` `true` says the kernel did it for
lack of memory. On a 4 GB VM with no cap, the same thing happens to the second or third node of
lessons 16 to 19 if the settings are missing, or if MongoDB and Redis are still running beside them.
Check the `-e` settings, `docker stop` what you are not using, and give the VM more memory if you
can.

## Below all of these: the virtual machine

If Multipass refuses to start the machine with a message about virtualisation being disabled,
**the processor can do it and the computer's firmware has it switched off.** It is a setting in the
BIOS or UEFI menu, reached by a key pressed while the computer starts, and the manufacturer's site
says which key. If you cannot change it, the installed path or the online one needs no
virtualisation of your own.

A VM whose disk fills up fails in ways that look unrelated, from a pull that stops halfway to a
database that refuses writes. `df -h /` inside the VM shows it. `docker system prune` asks first and then
removes stopped containers, unused networks and untagged images; volumes stay unless you
add `--volumes`, the flag that deletes data.

## Starting again

Nothing here is precious yet. `docker rm -f mongo redis cassandra` and the three `docker run` lines
put the lab back to the state the next lesson expects, and `multipass delete vm` followed by
`multipass purge` throws away the whole machine so you can build another. A second installation is a
small price for knowing exactly what you are standing on.
