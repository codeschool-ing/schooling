---
title: Firejail, a sandbox for one command
version: 1
---

**Firejail is a ready-made sandbox for desktop programs and scripts.** It builds the same kind of
walls as `systemd-run`, from the same kernel features, but with options written for a person at a
keyboard rather than for a service, and with profiles for hundreds of common programs already in
the package. It is installed on every machine of the lab.

The three walls the script needs are one option each: no network, a home directory where only the
script itself is visible, and `/etc` read-only.

```
ana@web:~$ firejail --quiet --net=none --whitelist=~/relatorio.sh --read-only=/etc bash relatorio.sh
formatting the report...
ls: cannot access '/home/ana/.ssh': No such file or directory
relatorio.sh: line 5: /etc/relatorio-was-here: Read-only file system
could not write to /etc
could not reach 192.168.60.66
done
```

The result is the same as before: no SSH directory to list, nothing written to `/etc`, no network.
`--whitelist` turns the home directory into a view of the named paths and nothing else, which is
the gentler cousin of `ProtectHome`: the program sees what it was given.

## Disposable, not just confined

A confined process still runs on the machine it is confining. **For a file you would rather not
have on the machine at all, the next step is a machine you throw away afterwards.** The lab is
already one: `sudo bash hostlab.sh up trap` gives a fresh `trap` in seconds, and whatever a file
does there is gone at the next `up`. Outside the lab the same idea is a virtual machine restored
from a snapshot after every use, or Windows Sandbox, a throwaway Windows that Microsoft ships with
the Pro and Enterprise editions, which closes and forgets everything when its window is closed;
Windows Sandbox was not run for this course.

The order of preference for an unknown file is then simple: a service that analyses it somewhere
else, lesson 19; a disposable machine; a confined process, as here, when the file must be opened
on this machine and nothing better is available.
