---
title: Hardening a service you run
version: 1
---

**The cheapest sandbox on a server is the one around the services it already runs.** The portal is
not suspicious; it is the firm's own program. But it reads requests from strangers all day, and a
flaw in it would hand whoever found it everything its service is allowed to do. Today that is a
great deal, and systemd will measure how much:

```
ana@web:~$ systemd-analyze security portal | tail -1
→ Overall exposure level for portal.service: 9.2 UNSAFE :-{
ana@web:~$ systemd-analyze security portal | grep -E "PrivateNetwork=|ProtectHome=|ProtectSystem=|CapabilityBoundingSet=~CAP_SYS_ADMIN"
✗ ProtectSystem=                                              Service has full access to the OS file hierarchy                             0.2
✗ ProtectHome=                                                Service has full access to home directories                                  0.2
✗ CapabilityBoundingSet=~CAP_SYS_ADMIN                        Service has administrator privileges                                         0.3
✗ PrivateNetwork=                                             Service has access to the host's network                                     0.5
```

`systemd-analyze security` checks a unit against the sandboxing options systemd offers and scores
the result from 0, fully confined, to 10, not confined at all. The portal scores as a service that
was given nothing, and the lines underneath name a few of the walls it lacks: its own network, a
hidden home, a read-only system, and root's most powerful capability. Save this drop-in as
`20-sandbox.conf` in your home on `web`:

```schooling-example
{"language": "ini", "file": "20-sandbox.conf", "parts": [{"code": "[Service]\nProtectSystem=strict\nProtectHome=yes\nPrivateTmp=yes\nPrivateDevices=yes\nNoNewPrivileges=yes\nProtectKernelTunables=yes\nProtectKernelModules=yes\nProtectControlGroups=yes\nRestrictAddressFamilies=AF_INET AF_UNIX\nRestrictNamespaces=yes\nCapabilityBoundingSet=\nSystemCallFilter=@system-service", "note": "Each line takes away something the portal never uses: write access to the system, the home directories, a shared `/tmp`, the hardware devices, the kernel's settings and modules, every network family except IPv4 and local sockets, the creation of namespaces, every capability root would have, and every system call outside the set systemd lists for ordinary services."}]}
```

Install it next to the unit, restart the portal, and check that it still works before reading the
new score:

```
ana@web:~$ sudo mkdir -p /etc/systemd/system/portal.service.d && sudo cp 20-sandbox.conf /etc/systemd/system/portal.service.d/
ana@web:~$ sudo systemctl daemon-reload && sudo systemctl restart portal && sleep 1 && curl -s http://localhost/
Jatobá Contabilidade: client portal
ana@web:~$ systemd-analyze security portal | tail -1
→ Overall exposure level for portal.service: 2.4 OK :-)
```

**Check the service before the score.** A sandbox that breaks the program it protects gets removed
in a hurry and never comes back, so the order is always: add the walls, confirm the job still
works, then read the number. Here the page still answers, after the second the portal takes to
open its port, and the exposure fell to the figure on the last line.

The score is a guide, not a target. Some of its checks do not apply to a given service, and a few
walls cost more than they protect. What it does well is turn "is this service confined?" into a
list somebody can read in a review, and every option on that list is the kind of decision lesson 1
made about services and accounts: take away what the job does not need.
