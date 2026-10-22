---
title: When Docker refuses
version: 1
---

Most of what goes wrong here goes wrong between your user and the engine, and each case prints a
sentence that says which side failed. Read it before anything else.

## `permission denied while trying to connect to the docker API`

This is the one nearly everybody meets, minutes after installing. It comes from a terminal that was
already open when `usermod` ran:

```
ana@vm:~/bookshop$ id -nG
ana
ana@vm:~/bookshop$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

**The engine is running and refused you.** `id -nG` shows why: this shell's user is in one group
only. `usermod` changed the list of groups the system keeps for the user, and a process keeps the
groups it started with, so the shell, and everything started from it, still lacks `docker`. The fix
is the one the installation section gave: log out and back in, and check `id -nG` again.

Two other fixes circulate, and both are wrong. `sudo chmod 666 /var/run/docker.sock` makes the
socket writable by every account on the machine, which is handing root to all of them, and it is
undone by the next restart of the engine anyway. And `sudo` in front of every `docker` command works
until Maven runs the tests: Testcontainers runs inside Maven's JVM, as your user, and `sudo mvn`
would leave files owned by root in `target/` and in `~/.m2`.

## `failed to connect to the docker API`

```
ana@vm:~/bookshop$ DOCKER_HOST=unix:///run/not-running.sock docker ps
failed to connect to the docker API at unix:///run/not-running.sock; check if the path is correct and if the daemon is running: dial unix /run/not-running.sock: connect: no such file or directory
```

**Nothing answered at all**, which is a different failure from a refusal. Either the engine is
stopped, and `sudo systemctl start docker` starts it, or `docker` was pointed at a socket where no
engine listens. The lab produced it with `DOCKER_HOST`, the variable that points the client
elsewhere, and a `DOCKER_HOST` left over in `~/.bashrc` from some tutorial is how it happens by
accident. The path in the message says which socket was tried.

## `Could not find a valid Docker environment`

The same refusal reaches the tests as a different sentence. Here is `mvn verify` from the shell
without the group, with the integration tests of the next section in place:

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E 'o.t.d.DockerClientProviderStrategy|valid Docker environment for|Skipped: 0$|BUILD'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
2026-10-22T20:18:58.446-03:00  WARN 5316 --- [bookshop] [           main] [] o.t.d.DockerClientProviderStrategy       : DOCKER_HOST unix:///var/run/docker.sock is not listening
2026-10-22T20:18:58.463-03:00 ERROR 5316 --- [bookshop] [           main] [] o.t.d.DockerClientProviderStrategy       : Could not find a valid Docker environment. Please check configuration. Attempted configurations were:
Could not find a valid Docker environment for Testcontainers.
[ERROR] Tests run: 2, Failures: 0, Errors: 2, Skipped: 0
[INFO] BUILD FAILURE
```

**Testcontainers says "not listening" about a socket that is there and refused it**, so do not
take the words literally. Run `docker ps` in the same terminal: its answer is one of the two
sentences above, and the fix is beside it. The unit tests passed, because they never reach Docker;
both integration test classes failed with errors before running a single assertion, and `verify`
failed the build.

## Other sentences you may meet

**A shell that has never heard of `docker`**, while the VM has it: the command was typed in a
terminal of your own computer rather than in the VM. The engine was installed inside the VM, and
the tests run there too.

**`429 Too Many Requests` while an image downloads**: Docker Hub limits how many images one address
may pull without an account, and a school or an office shares one address between everybody. Wait,
or log in with `docker login` and a free Docker account, which raises the limit. `docker` lesson 5
has more on this one.

**The tests pass on your machine and a container is still running afterwards**, seen with
`docker ps`: it is Ryuk, still waiting the few seconds it waits before cleaning up, and the next
section shows it going.
