---
title: Reading `systemctl status`
version: 1
---

**A note before the picture.** Every transcript in this course was run on the machine it was
recorded on. This one could not be: process one here is a container supervisor rather than systemd,
so there is no `systemctl status` to capture. What follows is a **drawing**, labelled as one, and
the fields are where a real status block puts them. Section 08 explains why that machine is built
the way it is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 364\" role=\"img\" aria-label=\"A drawing of a systemctl status block for nginx, with six numbered callouts: the status dot, the Loaded line, the Active line, the Main PID line, the CGroup tree and the journal lines at the bottom.\"><rect x=\"20\" y=\"16\" width=\"680\" height=\"202\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"34.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"52\" y=\"34.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">● nginx.service - A high performance web server</text><text x=\"36\" y=\"49.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"52\" y=\"49.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)</text><text x=\"36\" y=\"65.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"52\" y=\"65.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     Active: active (running) since Mon 2026-09-14 09:12:03 UTC; 2h 41min ago</text><text x=\"36\" y=\"80.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"52\" y=\"80.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">   Main PID: 1284 (nginx)</text><text x=\"52\" y=\"96.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">      Tasks: 3 (limit: 4657)</text><text x=\"52\" y=\"111.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     Memory: 8.4M</text><text x=\"36\" y=\"127.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><text x=\"52\" y=\"127.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     CGroup: /system.slice/nginx.service</text><text x=\"52\" y=\"142.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">             ├─1284 nginx: master process /usr/sbin/nginx</text><text x=\"52\" y=\"158.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">             └─1285 nginx: worker process</text><text x=\"36\" y=\"189.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><text x=\"52\" y=\"189.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Sep 14 09:12:03 vm systemd[1]: Starting nginx.service...</text><text x=\"52\" y=\"204.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Sep 14 09:12:03 vm systemd[1]: Started nginx.service.</text><text x=\"40\" y=\"250.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"58\" y=\"250.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the dot: green running, red failed, hollow stopped</text><text x=\"40\" y=\"265.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"58\" y=\"265.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Loaded: which unit file, and whether it starts at boot</text><text x=\"40\" y=\"280.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"58\" y=\"280.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Active: the state right now, and for how long</text><text x=\"40\" y=\"295.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"58\" y=\"295.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Main PID: the process number, for lesson 6</text><text x=\"40\" y=\"310.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><text x=\"58\" y=\"310.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">CGroup: every process this service owns</text><text x=\"40\" y=\"325.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><text x=\"58\" y=\"325.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and the last lines of its journal, for free</text><text x=\"40\" y=\"346.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">drawn, not captured: this machine does not run systemd as PID 1</text></svg>", "caption": "The shape of `systemctl status`. This block is a drawing rather than a transcript, because the machine this course was recorded on runs a container supervisor as process one; on a machine that boots normally the fields are where this puts them."}
```

## The first line: is it up, in one glance

```
● nginx.service - A high performance web server
```

The dot is the summary, and it is coloured:

| | |
|---|---|
| green `●` | running |
| red `●` | **failed** — it tried and did not make it |
| hollow `○` | stopped, and nobody is complaining |

Then the unit's name and its `Description=` from section 11. **A service you have never heard of
introduces itself on that line**, which is worth more than it sounds when you are reading
`systemctl --failed` on a machine somebody else built.

## `Loaded:` answers *is it set up*

```
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
```

Three facts on one line:

| | |
|---|---|
| `loaded` | systemd read a unit file for it. `not-found` means there is no such service |
| the path | **which** file, which matters when there are two — section 11 |
| `enabled` | it will start at the next boot. Section 09's symlink, reported back |

**`loaded … disabled` on a service that is currently running is a normal and alarming thing to
see.** It means somebody started it by hand and it will be gone after a reboot.

## `Active:` answers *is it up, and since when*

```
     Active: active (running) since Mon 2026-09-14 09:12:03 UTC; 2h 41min ago
```

| | |
|---|---|
| `active (running)` | it is up, and it has a process |
| `active (exited)` | it ran, it finished, and that was the point — a one-shot setup job |
| `inactive (dead)` | stopped |
| `failed` | it stopped **and systemd thinks that was wrong** |
| `activating` / `deactivating` | in between, right now |

**`active (exited)` confuses everybody once.** A unit that mounts something, or sets a sysctl, or
loads a firewall ruleset has nothing left running when it succeeds, and that is success.

And the time is the piece people skip. **"Since 2 minutes ago" on a service you did not touch is
the whole answer** — something restarted it, and section 12's journal will say what.

## `Main PID:` and `CGroup:` connect it to lesson 6

```
   Main PID: 1284 (nginx)
     CGroup: /system.slice/nginx.service
             ├─1284 nginx: master process /usr/sbin/nginx
             └─1285 nginx: worker process
```

The PID is a number you can hand to everything in the next lesson — `ps`, `kill`, `/proc/1284`.

The CGroup tree is section 08's third idea, made visible. **Those are all the processes this
service owns**, including the ones it forked, and systemd knows about them because the kernel is
keeping the list. That is what makes `systemctl stop` reliable where killing a PID file's contents
was not.

`Tasks`, `Memory` and `CPU` come from the same accounting, and they are free — no monitoring agent
involved.

## The bottom lines are the journal

```
Sep 14 09:12:03 vm systemd[1]: Starting nginx.service...
Sep 14 09:12:03 vm systemd[1]: Started nginx.service.
```

`status` prints the last ten lines of the service's log without being asked. **On a failure, the
reason is usually right there**, and people go straight to `journalctl` without reading what was
already on screen.

`systemctl status -n 50` shows more; `-l` stops it truncating long lines.

## How to read a failure, in order

When the dot is red, four lines answer it and they are in this order on the screen:

1. **`Loaded:`** — is it `not-found`? Then the unit file is missing or misnamed, and nothing else
   matters.
2. **`Active: failed (Result: …)`** — the `Result` word says *how* it failed: `exit-code`,
   `timeout`, `signal`, `core-dump`.
3. **`Process: … status=…`** — the exit status the program gave. Lesson 6 section 14 reads those.
4. **The journal lines** — what the program itself said before it stopped. This is the one that
   usually contains the answer: a port in use, a file missing, a permission denied.

**Read all four before you change anything**, and read them in that order. Restarting a failed
service without reading them is how an afternoon disappears.

## And one thing `status` does not tell you

It shows the service's own log lines, not the machine's. A service that failed because something
*else* failed — the network, a mount, a database it depends on — will show you its own confusion
rather than the cause.

`journalctl -b` in section 12 shows the boot in order, and that is where a cascade becomes
readable.
