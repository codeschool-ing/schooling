---
title: A check that runs inside the guest
version: 1
---

Checking the doors one command at a time is easy to get wrong and tedious to repeat, so here is a short
script that tries each one from inside the guest and says what it found. Each line is **a command that
succeeds only when the door is open**:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# Run inside a lab guest, with the host's address on the lab network.\nhost=${1:?usage: check.sh HOST_ADDRESS}", "note": "The host's address comes in as an argument, `10.20.0.1` on labnet. `${1:?...}` stops the script with the usage line if it is missing."}, {"code": "check() {\n  if \"${@:2}\" >/dev/null 2>&1; then echo \"$1: OPEN\"; else echo \"$1: closed\"; fi\n}", "note": "**Every check is a command that succeeds only if the door is open.** The first argument is the name to print, the rest is the command. Its output is thrown away; only whether it succeeded counts."}, {"code": "check \"a route out of the lab\"  ip route get 10.0.0.50", "note": "Asks the guest's own routing table for a way to an address on the real network, the office printer. With no `default via` line there is none."}, {"code": "check \"the host's ssh\"          nc -z -w 3 \"$host\" 22\ncheck \"the host's port 8000\"    nc -z -w 3 \"$host\" 8000", "note": "`nc -z` only knocks: it connects and hangs up at once. `-w 3` gives up after three seconds, which is what a dropped packet looks like from inside."}, {"code": "check \"a shared folder\"         grep -qE \" (9p|virtiofs) \" /proc/mounts", "note": "The two kinds of shared folder from lesson 12, looked for in the guest's list of mounted filesystems. Not `findmnt -t 9p,virtiofs`: it exits with success even when it finds nothing, so the check would say OPEN on every guest."}, {"code": "check \"a clipboard agent\"       pgrep -x \"spice-vdagent|VBoxClient\"", "note": "The programs that carry a shared clipboard inside the guest: SPICE's agent for QEMU, and VirtualBox's own. With neither running, nothing can pass the clipboard in or out."}]}
```

Run on the client before anything was changed:

```
ana@client:~$ bash check.sh 10.20.0.1
a route out of the lab: closed
the host's ssh: OPEN
the host's port 8000: OPEN
a shared folder: closed
a clipboard agent: closed
```

The way out is closed and there is no shared folder and no clipboard agent, because this lab never had
them. The two doors into the host are **OPEN**, as the last section found by hand. That is the list of
what to fix.

A check like this is worth keeping for the same reason as the snapshot in lesson 14: **the next time
the lab changes, it takes one command to find out whether a door opened again.**
