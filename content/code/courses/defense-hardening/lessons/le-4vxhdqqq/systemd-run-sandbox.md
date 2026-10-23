---
title: Walls from systemd
version: 1
---

**systemd can build a sandbox around any command, with the same options it offers every
service.** `systemd-run` starts the command as a temporary service, and each `-p` adds one wall.
The ones this lesson uses each answer one of the script's three attempts, plus two that cost
nothing:

| option | the wall |
|---|---|
| `ProtectHome=tmpfs` | every home directory is replaced by an empty one; `BindReadOnlyPaths=` puts back the single file the program is allowed to read |
| `ProtectSystem=strict` | the whole file system is read-only, `/etc` included |
| `PrivateNetwork=yes` | the program gets a network of its own with only a loopback interface in it |
| `PrivateTmp=yes` | a `/tmp` nobody else shares |
| `NoNewPrivileges=yes` | nothing it runs can gain rights, through `sudo` or a set-user-id program |

`--uid=ana` runs it as you, so the walls are the only difference from running it yourself:

```
ana@web:~$ sudo systemd-run -q --wait --pipe --uid=ana -p ProtectHome=tmpfs -p BindReadOnlyPaths=/home/ana/relatorio.sh -p ProtectSystem=strict -p PrivateNetwork=yes -p PrivateTmp=yes -p NoNewPrivileges=yes bash /home/ana/relatorio.sh
formatting the report...
ls: cannot access '/home/ana/.ssh': No such file or directory
/home/ana/relatorio.sh: line 5: /etc/relatorio-was-here: Read-only file system
could not write to /etc
could not reach 192.168.60.66
done
```

**Each attempt failed, and each failure has a different reason.** The SSH directory is not there,
because the home the program sees is an empty one with a single file in it. `/etc` refused the new
file as a read-only file system. And the connection to `trap` never left, because there is no
network to leave by. The script still ran to its end and printed `done`, which is the point: a
sandbox does not need to know what a program is, only what it may touch.

## Walls with a gap

None of these options is a promise about a program designed to escape. They are namespaces and
filters in the same kernel the rest of the machine runs on, and a flaw in that kernel is a flaw in
every wall at once. That is why the last section of lesson 8 put real EDR sensors outside the
containers, and why a file that may have been **built** to escape goes to a virtual machine. For a
program that is merely untrusted, or for a service you run and want to limit, these walls are the
cheapest protection on the machine.
