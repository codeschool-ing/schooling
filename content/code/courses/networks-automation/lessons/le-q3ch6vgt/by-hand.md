---
title: The change, made by hand
version: 1
---

The operations team has moved its jump hosts into the management network, `192.0.2.0/24`, and
asks for one thing: **every router carries a prefix list called `MGMT` that permits that
network**, so the policies built on it later have one name to point at. Three routers, one line
each. This is the way it has always been done, one SSH session per router:

```
ana@ctl:~$ ssh netops@core1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

core1# configure terminal
core1(config)# ip prefix-list MGMT seq 10 permit 192.0.2.0/24
core1(config)# end
core1# write memory
Note: this version of vtysh never writes vtysh.conf
Building Configuration...
Integrated configuration saved to /etc/frr/frr.conf
[OK]
core1# exit
Connection to core1 closed.
```

Nothing in that session is difficult. `configure terminal` enters configuration mode, the line
goes in, `end` leaves, and `write memory` copies the running configuration to the file the router
boots from. **Leaving out that last command is the first classic mistake**: the change works until
the next reboot and then quietly disappears.

The second router, a few minutes later:

```
ana@ctl:~$ ssh netops@edge1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge1# configure terminal
edge1(config)# ip prefix-list MGMT seq 10 permit 192.0.12.0/24
edge1(config)# end
edge1# write memory
Note: this version of vtysh never writes vtysh.conf
Building Configuration...
Integrated configuration saved to /etc/frr/frr.conf
[OK]
edge1# exit
Connection to edge1 closed.
```

Read the prefix list again. `192.0.12.0/24` is not `192.0.2.0/24`: one key pressed twice. The
router accepted it without a word, because `192.0.12.0/24` is a perfectly valid network. **A CLI
checks syntax; it has no idea what you meant.**

The third router never got its session. Something else came up. That is the whole story of a
manual change, and it becomes visible only when somebody asks every router the same question:

```
ana@ctl:~$ for r in core1 edge1 edge2; do echo "== $r"; ssh netops@$r "show running-config" | grep MGMT; done
== core1
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
== edge1
ip prefix-list MGMT seq 10 permit 192.0.12.0/24
== edge2
```

One router right, one wrong, one missing, and each of the three looks fine on its own. The loop
that asked is plain shell on `ctl`, one `ssh` per router with the command as its argument, and it
is already a small piece of automation: it asked all three the same thing the same way, which a
person reading three terminals does not do.
