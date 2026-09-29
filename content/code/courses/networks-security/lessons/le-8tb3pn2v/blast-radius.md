---
title: The blast radius of a compromised server
version: 1
---

Segmentation is not about stopping the first compromise. Something exposed to the internet will be
compromised eventually. It is about **what the attacker can reach from there**, the blast radius.

Suppose `www` is taken over through a flaw in some piece of software on it. Whoever controls it now
starts connections **from `www`**, so the question is what `www` may reach:

```
ana@www:~$ probe app:8080 db:5432 app:22 laptop:22 admin:22 remote:80 remote:443
app:8080               open
db:5432                blocked
app:22                 blocked
laptop:22              blocked
admin:22               blocked
remote:80              blocked
remote:443             blocked
```

**One door, the one the proxy needs, and nothing else.** Not the database, not SSH on the
application server, not the staff, not the management machine, and not the internet either:
`remote:80` and `remote:443` are blocked because the matrix gives the DMZ no row towards the
internet. Software that takes over a server usually calls
back out to receive instructions or to send what it found. A DMZ that cannot start outbound
connections makes that much harder, and makes any attempt visible in the firewall's counters.

```
root@fw:~# nft list ruleset | grep -c "iifname \"eth1\""
1
```

Of all the rules on `fw`, one starts in the DMZ. That count is the blast radius written as a number,
and it is worth watching: every rule added with `iifname "eth1"` makes it larger.

**What the DMZ cannot protect is the one path it allows.** `www` reaches `app` on 8080, so a flaw in
the application is reachable from a compromised proxy. The firewall has done its part by making
that the only thing reachable; the application's own defences, and the WAF of lesson 3, have to do
the rest.

A server that does need to call out, to fetch its updates for instance, gets a rule to one
destination, ideally an update proxy inside the company, rather than to the whole internet.
