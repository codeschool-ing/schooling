---
title: A flat network
version: 1
---

Before writing a rule, look at what the network does with none. The lab's firewall, `fw`, joins the
four segments and, as built, forwards everything. That is how a great many small networks really
run: a router that connects things and a plan that nobody wrote down.

`probe` is a small command in the lab that tries to open a connection to a machine and a port, and
says in one word what happened: **open** (something answered), **refused** (the machine answered
that nothing listens on that port), or **blocked** (nothing came back at all, which is what a
firewall that drops the attempt looks like). Here it runs from three places:

```
ana@outside:~$ probe www:80 db:5432
www:80                 open
db:5432                open
ana@www:~$ probe db:5432 db:22 laptop:22
db:5432                open
db:22                  refused
laptop:22              refused
ana@laptop:~$ probe www:80 db:5432
www:80                 open
db:5432                open
```

Read it as an attacker would, one line at a time.

**From the internet, `db:5432` is open.** The shop's database answers a stranger. Nothing about its
location stops it: the only reason this database is not being probed every minute in real life is
that real networks usually have NAT in the way, and the first reading of this lesson said that is
not a control anybody designed.

**From `www`, everything is reachable too.** `db:22` and `laptop:22` say `refused`, which only means
those machines run nothing on port 22; the network itself delivered the attempt. If `www` were
compromised, its attacker could try every port of every machine in the company, and the network
would carry every attempt.

**From the office laptop, the database is open.** Perhaps fine on purpose, perhaps an accident;
nobody decided either way.

This is a **flat network**: every machine reaches every other on every port. It is convenient, it
breaks nothing, and it turns one compromised machine into a compromised company, because the
attacker's next step, known as **lateral movement**, has nothing in its way.
