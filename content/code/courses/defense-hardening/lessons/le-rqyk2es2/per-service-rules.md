---
title: Rules per service
version: 1
---

**systemd starts every service in a control group of its own, and a control group can carry
network rules.** The group is the service: every process the service starts, under whatever
account, stays in it. That gives two more ways to write a rule about a program, and both survive
an account change that the per-account rule does not.

## In the unit, with systemd

systemd can deny a service network access by address, written in the service's own configuration.
Save this on `web` as `10-network.conf`; it is a drop-in, a file that adds settings to a unit
without editing the unit's own file:

```schooling-example
{"language": "ini", "file": "10-network.conf", "parts": [{"code": "[Service]\nIPAddressDeny=any\nIPAddressAllow=localhost", "note": "The same promise, made by systemd instead of the firewall: every address is denied to this one service except the loopback range. systemd enforces it with a small filter attached to the service's own control group, so it follows the service wherever it runs, and it is written next to the service rather than in a rule set somebody else maintains."}]}
```

Put it in the portal's drop-in directory, reload systemd so it reads it, and restart the portal:

```
ana@web:~$ sudo mkdir -p /etc/systemd/system/portal.service.d && sudo cp 10-network.conf /etc/systemd/system/portal.service.d/
ana@web:~$ sudo systemctl daemon-reload && sudo systemctl restart portal && systemctl show portal -p IPAddressDeny -p IPAddressAllow
IPAddressAllow=::1/128 127.0.0.0/8
IPAddressDeny=0.0.0.0/0 ::/0
ana@desk:~$ curl -s http://web/
Jatobá Contabilidade: client portal
```

systemd accepted the settings and shows them, resolved into address ranges, and the portal still
serves `desk`. Now check that the rule refuses something, which is the part people skip. A one-off
service with the same two settings, asked to reach `desk`:

```
ana@web:~$ sudo systemd-run -q --wait --pipe -p IPAddressDeny=any -p IPAddressAllow=localhost nc -zv -w2 desk 22 2>&1
Connection to desk (192.168.60.20) 22 port [tcp/ssh] succeeded!
```

**It connected.** The settings are in force on paper and do nothing here. systemd enforces them
with small BPF programs attached to the service's control group, and inside this lab's containers
the kernel does not let systemd attach them; systemd carries on without them and without an error
on the screen. In your own virtual machine, outside the containers, the same command is refused by
the kernel, as systemd's documentation describes; that was not run for this course.

That is lesson 1's rule in its sharpest form: **a setting is a claim until a client has been
refused.** A firewall setting that silently does nothing is worse than none, because everybody
believes it.

## In nftables, by control group

nftables can match the control group a socket belongs to by its path, which is how a firewall rule
names a service rather than an account. It has one surprise, and the first command shows it:

```
ana@web:~$ sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/probe.service" counter reject
Error: cgroupv2 path fails: No such file or directory
add rule inet portal_out output socket cgroupv2 level 2 system.slice/probe.service counter reject
                                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
ana@web:~$ sudo systemd-run -q --unit probe sh -c "sleep 3; nc -zv -w2 desk 22"
ana@web:~$ sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/probe.service" counter reject
ana@web:~$ sleep 4; sudo journalctl -u probe -o cat --no-pager | grep nc:
nc: connect to desk (192.168.60.20) port 22 (tcp) failed: Connection refused
ana@web:~$ sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/portal.service" counter
ana@desk:~$ for i in 1 2 3; do curl -s -o /dev/null http://web/; done
ana@web:~$ sudo nft list chain inet portal_out output | grep cgroupv2
		socket cgroupv2 level 2 27005 counter packets 1 bytes 60 reject
		socket cgroupv2 level 2 "system.slice/portal.service" counter packets 6 bytes 312
```

The first attempt fails because **nftables looks the group up when the rule is loaded**, and a
service that is not running has no group. So the second attempt starts the service first, a probe
that waits three seconds and then tries `desk`, and adds the rule while it waits. The probe's
connection is refused, and this time the refusal comes from the rule. A second rule, which only
counts, shows the portal's own packets being attributed to `portal.service`.

Look at how the listing prints the probe's rule now that the probe has ended: a number where the
path was. The rule holds the group's identity, not its name, and a service that is restarted gets a
new group. **A rule written this way has to be reloaded every time the service starts**, which is
why it belongs in the service's own start-up, or why the per-account rule of the last section is
often the simpler choice.
