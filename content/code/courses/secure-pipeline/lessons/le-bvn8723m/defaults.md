---
title: What a container may do by default
version: 1
---

Lesson 8 shipped an image with no shell, no pip and a user that is not root, and it is tempting to
call that a hardened container. **It is a hardened image. How the container runs is decided by
whoever starts it**, with flags the image has no say in, and the defaults of `docker run` are
generous. `docker` lesson 21 took those defaults apart on a small service of its own; this lesson
applies the same controls to linkbox and then puts them where nobody can forget them, in the
pipeline's staging run.

### The defaults, asked

Build the image if it is not on your machine any more, and start it the way lesson 8 did:

```
ana@vm:~$ cd ~/linkbox
ana@vm:~/linkbox$ docker build -q -t linkbox:dev .
sha256:0aded474c783e199e98d8e61bd240bcd2c4b983eea05786c1dbd259181cf2259
```

```
ana@vm:~/linkbox$ docker run -d --name linkbox -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
adaaeb4e3cfa7b8e9ece836a2e25a6c6fbff9c739ff5f18009b002662c8d0077
ana@vm:~/linkbox$ docker inspect --format 'read-only={{.HostConfig.ReadonlyRootfs}} cap-drop={{.HostConfig.CapDrop}} security-opt={{.HostConfig.SecurityOpt}} memory={{.HostConfig.Memory}} pids-limit={{.HostConfig.PidsLimit}}' linkbox
read-only=false cap-drop=[] security-opt=[] memory=0 pids-limit=<nil>
```

**Every restriction Docker offers is off.** The root filesystem is writable, no capability was
dropped, no security option was set, and the container may use all the memory and start as many
processes as the machine allows. None of that is wrong for a quick test; all of it is what a
container in staging or production inherits unless somebody writes otherwise.

### What the process holds

The kernel keeps a summary of every process in `/proc/<pid>/status`, and the lines that matter
here are the user, the capability sets, `NoNewPrivs` and `Seccomp`. The image has no `grep`, so a
line of Python does the filtering. Keep it in a shell variable, because the lesson asks the same
question of several containers:

```
ana@vm:~/linkbox$ status='import re; print("".join(l for l in open("/proc/1/status") if re.match("(Uid|Cap|NoNewPrivs|Seccomp)", l)), end="")'
ana@vm:~/linkbox$ docker exec linkbox python3 -c "$status"
Uid:	65532	65532	65532	65532
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
NoNewPrivs:	0
Seccomp:	2
Seccomp_filters:	1
```

Read it from the top. **`Uid` is 65532**, the image's user. Of the five capability sets, two
matter here. `CapEff`, the capabilities the process can use right now, is zero: an ordinary user
holds none. `CapBnd`, the bounding set, is `a80425fb`, the same fourteen capabilities `docker`
lesson 21 decoded, among them `chown`, `setuid` and `net_raw`. The bounding set is the ceiling: no
process in this container can ever hold a capability outside it, whatever it executes.
`NoNewPrivs: 0` says that executing a program can still raise privileges, through a setuid file or a
file capability. `Seccomp: 2` says a system-call filter is active, Docker's default profile, which
the fourth section of this lesson looks at.

So the process itself is unprivileged, and **the container around it still keeps fourteen
capabilities within reach** for anything that runs as root or through a setuid file.

### What it can write

```
ana@vm:~/linkbox$ docker exec linkbox python3 -c "open('/tmp/dropped.py', 'w').write('print(1)'); print('written')"
written
ana@vm:~/linkbox$ docker exec linkbox python3 -c "open('/app/app.py', 'a')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    open('/app/app.py', 'a')
    ~~~~^^^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 13] Permission denied: '/app/app.py'
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

A file in `/tmp` is written without complaint, and a Python file at that, which `python3` would run.
The application's own code cannot be changed, because it belongs to root and the process is 65532:
lesson 8's `COPY` without `--chown` is doing its job. **The defence rests on one fact, the user, and
the user is a default anybody can override:**

```
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "$status"
Uid:	0	0	0	0
CapInh:	0000000000000000
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
NoNewPrivs:	0
Seccomp:	2
Seccomp_filters:	1
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "open('/app/app.py', 'a').write('# changed'); print('app.py changed')"
app.py changed
```

`--user 0` is one flag, accepted by every container runtime and every orchestrator that runs this
image, and with it the process is root with the full bounding set effective, and it rewrites
`app.py`. Nothing in the image prevents it: `USER` in a Dockerfile is the user a container starts
as **when nothing says otherwise**. In real deployments what says otherwise is seldom an attacker: a
manifest written by somebody in a hurry to fix a permission error, a debugging session started as
root and left running, a platform default that nobody changed.

That is why the rest of this lesson sets controls that do not depend on the user. A read-only
filesystem refuses the write whoever asks. A container with no capabilities has none to give to
root. And lesson 10 adds the one thing that does check the user: Kubernetes' `runAsNonRoot`, which
refuses to start a container whose user is 0.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"sp-l09-layers\" aria-label=\"The controls around linkbox's process, nested from the outside in: memory and process limits; Docker's seccomp filter, the only one on by default; a read-only root with two tmpfs mounts; no capabilities and no new privileges; and at the centre gunicorn as user 65532, the one control the image itself sets and the one a single flag overrides.\"><defs></defs><rect x=\"20\" y=\"20\" width=\"520\" height=\"290\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">memory and process limits</text><rect x=\"58\" y=\"58\" width=\"444\" height=\"214\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">seccomp: the default filter</text><rect x=\"96\" y=\"96\" width=\"368\" height=\"138\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"108\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">read-only root, tmpfs on /tmp and /data</text><rect x=\"134\" y=\"134\" width=\"292\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"146\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no capabilities, no new privileges</text><rect x=\"185\" y=\"168\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">user 65532</text><text x=\"280.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">set by the image; --user 0 undoes it</text><rect x=\"560\" y=\"120\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">on by default</text><rect x=\"560\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"586\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">off unless asked for</text></svg>", "caption": "Only the filter is on without asking. Everything else is a flag on the command that starts the container, and the innermost ring is the one a single flag removes."}
```
