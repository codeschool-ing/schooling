---
title: Testing every cell from where it starts
version: 1
---

A rule set is a claim about what can reach what, and **a claim is checked by trying it from where the
traffic starts**. Reading the rules proves what they say; only a connection attempt proves what they
do. So `probe` runs from one machine in each zone, against the cells that should be open and the ones
that should not:

```
ana@remote:~$ probe www:443 www:80 dns:53 app:8080 db:5432 laptop:22
www:443                open
www:80                 open
dns:53                 blocked
app:8080               blocked
db:5432                blocked
laptop:22              blocked
```

From the internet, the shop answers on both ports and everything inside is `blocked`, not `refused`:
the packets never reached anything that could refuse them. `dns:53` is blocked too, and that is the
matrix working: `probe` tries **TCP**, and the internet's cell allows only UDP. The name server still
answers the internet, over the transport the rule allows:

```
ana@remote:~$ dig +short @192.0.2.53 www.example.com
192.0.2.80
ana@laptop:~$ dig +short @192.0.2.53 db.corp.example.com
192.168.20.30
```

Then from the staff LAN and the management segment:

```
ana@laptop:~$ probe www:443 app:8080 db:5432 app:22 remote:443
www:443                open
app:8080               open
db:5432                blocked
app:22                 blocked
remote:443             open
ana@admin:~$ probe app:22 db:22 www:22 app:8080 db:5432
app:22                 open
db:22                  open
www:22                 refused
app:8080               blocked
db:5432                blocked
```

`laptop` browses and uses the application and reaches nothing else on the servers segment. `admin`
reaches SSH on both servers and cannot use the application or the database, because administering a
machine and using its service are different cells. `www:22` says `refused` from `admin`: the rule let
the connection through, and `www` simply runs no SSH server.

**The internet, staff and management rows have now been tested from the zones they start in**, the
allowed cells and a sample of the denied ones; the next section tests the DMZ's row from `www`. Keep that test. After any change to the rules, run it again: a rule added
in a hurry to fix one thing is the usual way another cell opens by accident, and lesson 18 collects
the classic ways it happens.
