---
title: The system-call filter, and limits on memory and processes
version: 1
---

Two more controls are about the kernel rather than the files. **Seccomp filters which system calls
a process may make; resource limits cap how much memory and how many processes it may use.** The
first is on by default and the second is not, which is the opposite of what most people assume.

### Seccomp is already on

Every process talks to the kernel through system calls, a little over three hundred of them on
Linux, and a web service uses a few dozen. Docker starts every container with a filter, its default
seccomp profile, that refuses a list of calls an ordinary container has no use for: loading kernel
modules, rebooting, changing the clock, managing kernel keyrings, and creating some kinds of
namespace. `Seccomp: 2` in every status earlier in this lesson was that filter, in filtering mode:

```
ana@vm:~/linkbox$ docker info --format "{{.SecurityOptions}}"
[name=seccomp,profile=builtin]
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')
               ~~~~~~~~~~^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 1] Operation not permitted
ana@vm:~/linkbox$ docker run --rm --user 0 --security-opt seccomp=unconfined --entrypoint python3 linkbox:dev -c "import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')"
in a new user namespace
```

The first line says this daemon applies the built-in profile. The two runs ask for the same thing,
a new user namespace, as root and with the default capabilities. **With the default profile the
kernel answers `Operation not permitted`; with the filter removed, the same call succeeds.** Nothing
else differed between the two commands, so the refusal was the filter's. User namespaces are a
legitimate kernel feature, and they are also where a good share of the kernel's privilege-escalation
bugs have been reachable from, which is why the default profile only allows creating one to a
process that already holds `CAP_SYS_ADMIN`.

`seccomp=unconfined` appears here only to show what the filter is doing. **It belongs in no script
that starts a real container.** Where an application genuinely needs a call the default refuses,
the remedy is a custom profile that allows that call and nothing else; Docker's documentation
describes the format, and Kubernetes takes the same files, which is why lesson 10's manifest names
the profile explicitly rather than trusting a default.

The recording machine runs without AppArmor, so the daemon lists no AppArmor profile. On Ubuntu with AppArmor
enabled, Docker applies a second default profile, `docker-default`, which restricts file access
and mounts in a similar spirit, and `docker info` lists it beside seccomp.

### Memory

A container with no memory limit can use all the memory of the machine, and when the machine runs
out, the kernel's out-of-memory killer picks a victim that may well be another service. A limit
turns that into a contained failure: the container that exceeds its own allowance is the one
killed. Ask for 300 MB inside a 128 MB limit:

```
ana@vm:~/linkbox$ docker run --name hog --memory 128m --memory-swap 128m --entrypoint python3 linkbox:dev -c "b = bytearray(300 * 1024 * 1024)"; echo "exit $?"
exit 137
ana@vm:~/linkbox$ docker inspect --format "{{.State.OOMKilled}}" hog
true
ana@vm:~/linkbox$ docker rm hog
hog
```

**Exit status 137 is 128 plus 9, the process killed with `SIGKILL`, and Docker records why:
`OOMKilled` is true.** `--memory-swap` equal to `--memory` means no swap on top of the limit, so the
limit is the limit. A leak in linkbox, or a request that makes it load far more than it should, now
costs linkbox and nothing else on the host.

### Processes

A container with no process limit can also start processes or threads until the kernel's table is
full, and then nothing on the machine can start one: not a shell for the person investigating, not
the next request's worker. `--pids-limit` caps the count for the container. To watch it work, a
small program that starts threads until one is refused. **Run it only with a limit in place.**
Save it as `~/threads.py`:

```python
# Start threads that sleep, one after another, until the system refuses one.
# Run it only in a container with --pids-limit: on a machine with no limit it
# stops at whatever the kernel allows, which is a great many.
import threading
import time

started = 0
try:
    while True:
        threading.Thread(target=time.sleep, args=(5,), daemon=True).start()
        started += 1
except RuntimeError as error:
    print(f"{started} threads started, then: {error}")
```

The image has no copy of it, and it needs none: `python3 -` reads the program from standard input.

```
ana@vm:~/linkbox$ docker run --rm -i --pids-limit 32 --entrypoint python3 linkbox:dev - < ~/threads.py
31 threads started, then: can't start new thread
```

**31 threads and the main one make 32, the limit**, and the 33rd was refused with an error Python
could catch. The program reported it and exited, and the machine never noticed.

### Limits for linkbox

What to set comes from what the service uses, measured with room to spare, not from a guess. Run
linkbox with every control from this lesson and both limits, and ask Docker what it uses:

```
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 --cap-drop ALL --security-opt no-new-privileges --memory 256m --pids-limit 64 -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
301074253ca5b9515bb2e08216f9ce1f541603d469cb76f9dd978d8a6cb2c690
ana@vm:~/linkbox$ docker stats --no-stream --format "{{.Name}}  memory {{.MemUsage}}  pids {{.PIDs}}" linkbox
linkbox  memory 39.28MiB / 256MiB  pids 2
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

**39 MiB of 256 and two processes**, the gunicorn master and its one worker. 256 MiB leaves room for
traffic and a leak's early hours; 64 processes leaves room for more workers. A limit set far above
use protects the host and says little about the service; a limit set at today's use fails on the
first busy afternoon. The pipeline's staging run in the next section leaves both out, because it
lives for a minute and runs one scan. Lesson 10 sets them where they matter, on the Deployment that
runs linkbox for real, and there `kubernetes` lesson 19's rules on requests and limits apply.
