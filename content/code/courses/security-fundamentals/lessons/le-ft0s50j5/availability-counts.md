---
title: Availability is a security property too
version: 1
---

A common mistake is to treat a shop that stops working as an operations problem and a shop whose
data leaks as a security problem. **For the triad, both are security failures.** The business
loses either way, and the same attacker who can steal data can often stop a system instead,
which is exactly what ransomware does.

In the lab, availability is easy to see, because it is the one property whose loss is visible
from outside:

```
ana@laptop:~$ curl -s http://www.example.com/
shop.example.com: open
root@www:~# kill $(cat /srv/portal/portal.pid)
ana@laptop:~$ curl -s http://www.example.com/; echo "exit $?"
exit 7
root@www:~# portal-restart
portal restarted
ana@laptop:~$ curl -s http://www.example.com/
shop.example.com: open
```

The first request gets the shop's front page. Then the administrator, at the `root@www` prompt on
the server, stops the program that serves it. The same request now gets nothing: `curl` prints no
page, and `exit 7` is its way of saying it could not connect at all. `portal-restart` brings the
program back and the page returns.

Nothing was read and nothing was changed. **Confidentiality and integrity are intact, and the shop
is still losing every sale until somebody notices.** Here the cause was a deliberate command; in
real life the same symptom comes from many places:

| cause | example | what defends availability |
|---|---|---|
| failure | a disk dies, a server's power supply burns | redundancy: a second disk, a second server |
| mistake | an update with a bug, a deleted table | testing, change control, backups |
| attack | a flood of traffic, ransomware | filtering, capacity, offline backups |
| dependency | the payment provider is down | knowing your dependencies and having a plan |

Availability is also where security and the business most often argue. Every control has some
cost in availability: a firewall rule can block a legitimate customer, a patch needs a restart,
MFA locks out somebody who lost their phone. A control that protects confidentiality by making
the system unusable has not made it secure. It has moved the harm from one corner of the triangle
to another.

**Availability is measured, not felt.** "The shop was up 99.9% of the month" is a number that
allows about 43 minutes of downtime in a 30-day month. Lesson 12 comes back to this with backups,
where the questions become how much data the shop can afford to lose and how long it can afford
to be down.
