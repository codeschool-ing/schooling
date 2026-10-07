---
title: Capabilities
version: 2
---

**Linux does not treat root as one power. It splits it into about forty capabilities**: changing a
file's owner, binding a low port, loading a kernel module, changing the clock. A process holds some
set of them, and the kernel checks the one each operation needs. Lesson 14 made `shelf` a user other
than root; this lesson takes away what is left.

## What a container gets by default

```
ana@vm:~$ docker run --rm alpine:3.22 grep CapEff /proc/self/status
CapEff:	00000000a80425fb
ana@vm:~$ capsh --decode=00000000a80425fb
0x00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
ana@vm:~$ grep CapEff /proc/self/status
CapEff:	0000000000000000
```

**A root process in a container holds 14 capabilities**, not all of them, and `capsh` names them. Ana's
own shell, as an ordinary user, holds none. The 14 are a compromise Docker chose so that most images
work unmodified: enough to change file owners, switch users and open raw sockets, and short of loading
modules or changing the clock.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Capabilities held by a container&#x27;s root process in Ana&#x27;s lab, as bars. With --cap-drop ALL: none. By default: 14, among them chown, setuid, net_raw and mknod. With --privileged: 40, every capability the daemon itself holds, together with every device of the host, 111 entries in /dev against 14 by default. shelf runs with none.\"><text x=\"150\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">--cap-drop ALL</text><rect x=\"165\" y=\"40\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"175\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0: what shelf runs with</text><text x=\"150\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">default</text><rect x=\"165\" y=\"100\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"165\" y=\"100\" width=\"140\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"315\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">14: chown, setuid, net_raw, mknod…</text><text x=\"150\" y=\"175\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">--privileged</text><rect x=\"165\" y=\"160\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"165\" y=\"160\" width=\"400\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"175\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--ink)\">40, and all 111 devices in /dev</text><text x=\"565\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capabilities of the root process</text></svg>", "caption": "The default is a middle, not a minimum. shelf needs the left end, and nothing needs the right."}
```

## Dropping them

`--cap-drop ALL` removes every one:

```
ana@vm:~$ docker run --rm alpine:3.22 chown nobody /tmp && echo "chown worked"
chown worked
ana@vm:~$ docker run --rm --cap-drop ALL alpine:3.22 chown nobody /tmp
chown: /tmp: Operation not permitted
ana@vm:~$ docker run --rm --cap-drop ALL alpine:3.22 grep CapEff /proc/self/status
CapEff:	0000000000000000
```

**`chown` worked with the defaults and failed without them**, as root, inside the container. That is
the whole mechanism: the user is still UID 0, and the operation is refused because the capability is
not there.

`shelf:1.0.0` here is the image lesson 15 built. If your machine no longer has it, the build that
lesson shows makes it again.

`shelf` runs as UID 65532 and binds port 8080; it needs none of the 14:

```
ana@vm:~$ docker run -d --name web --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 shelf:1.0.0
8524d5c6ddf20a9d987543feee5b198c2f1d8d97019b4b8f6650e8946d2695b8
ana@vm:~$ curl -s localhost:8080/version
1.0.0
ana@vm:~$ docker inspect web --format "caps dropped: {{.HostConfig.CapDrop}}  options: {{.HostConfig.SecurityOpt}}"
caps dropped: [ALL]  options: [no-new-privileges]
```

**`--security-opt no-new-privileges` is the other half.** It stops any process in the container from
gaining privileges it did not start with, which is what a setuid program like `sudo` or `passwd` is
for. With both, nothing inside can climb back to the powers just removed.

When a program does need one, add back that one: `--cap-drop ALL --cap-add NET_BIND_SERVICE` for a
root process that binds port 80. **Start from nothing and add what a test proves is missing**, never
the other way round.
