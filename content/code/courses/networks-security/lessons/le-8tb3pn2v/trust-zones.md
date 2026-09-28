---
title: A zone is a set of machines trusted the same way
version: 1
---

The common picture of network security is a castle: a strong wall around the outside, and
everything inside trusted because it is inside. **That picture is the problem this lesson solves.**
In a flat network, one compromised machine anywhere reaches every other machine, and the wall only
mattered until the first thing got through it.

A **trust zone** is a group of machines that face the same risks and deserve the same trust, so that
one rule can speak for all of them. The lab's segments are its zones:

| zone | holds | trusted by the others | exposed to the internet |
|---|---|---|---|
| internet | everybody else | not at all | it is the internet |
| DMZ | the shop's proxy, the public DNS | very little | yes, on purpose |
| staff LAN | people's computers | a little | no, but people read e-mail and browse |
| servers | the application and the database | most | no |
| management | the machine administrators work from | enough to administer the others | no |

**Segmentation** is putting a firewall between zones, so that every conversation from one to another
has to be allowed by a rule. Before any rule is loaded, `fw` routes everything, and a stranger on the
internet reaches whatever answers:

```
ana@remote:~$ probe db:5432 app:22 app:8080 laptop:22 www:443
db:5432                open
app:22                 open
app:8080               open
laptop:22              refused
www:443                open
```

The database, the application, SSH on the application server: all `open`. `laptop:22` says
`refused`, which is still an answer: a machine replied that nothing listens there. `probe`, a small
command the lab installs, prints one of three words, and the difference between them matters all
lesson:

| probe says | what happened |
|---|---|
| `open` | the connection was accepted |
| `refused` | a machine answered that nothing listens on that port |
| `blocked` | nothing came back within a second: something dropped the packet |

Zones are a decision about **people and data**, not about cables. The staff LAN is less trusted than
the servers segment not because its machines are worse but because people use them: they open
attachments and visit websites, which is how lesson 9's problems arrive.
