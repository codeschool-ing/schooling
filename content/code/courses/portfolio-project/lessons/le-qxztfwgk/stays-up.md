---
title: Proving it stays up
version: 1
---

*It stays up* is a claim, and this lesson is about evidence, so here is the evidence. First, the health
check the unit file declared, run by hand and read back:

```
ana@srv:~$ sudo podman healthcheck run systemd-loanbook && echo healthy
healthy
ana@srv:~$ sudo podman inspect --format '{{.State.Health.Status}}' systemd-loanbook
healthy
```

Then the real test: **kill it**. `podman kill` stops the container abruptly, the way a crash would, and
systemd's restart counter shows what happened next:

```
ana@srv:~$ systemctl show -p NRestarts loanbook
NRestarts=0
ana@srv:~$ sudo podman kill systemd-loanbook
systemd-loanbook
ana@srv:~$ systemctl show -p NRestarts loanbook
NRestarts=1
ana@srv:~$ systemctl is-active loanbook
active
ana@laptop:~$ curl -sS https://loans.lab/healthz
{"ok": true}
ana@laptop:~$ curl -sS https://loans.lab/api/items | python3 -c 'import json,sys; print(len(json.load(sys.stdin)), "items")'
8 items
```

The counter went from 0 to 1: systemd saw the service die and started it again, within seconds, with no
one touching it. From laptop, the address still answers, and the list still has eight items, because the
database lives in the volume and not in the container that died.

The last check is the boot. A reboot was not recorded, because the lab's machines are containers
themselves and one that reboots does not come back on its own. What can be shown is that both services
are wired to start at boot:

```
ana@srv:~$ systemctl is-enabled loanbook caddy
generated
enabled
```

`generated` is how systemd describes a unit Quadlet wrote; its `WantedBy=multi-user.target` is what
starts it at boot. `enabled` is Caddy's. On a real server, reboot it once before calling the deploy done.

These three checks, health, a crash and a boot, are the difference between *I ran it on a server* and *it
is deployed*, and each is one or two commands. Put them in the README's deploy section, lesson 16, and
they become part of the evidence.
