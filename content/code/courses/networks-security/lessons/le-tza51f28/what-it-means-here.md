---
title: Least privilege, measured in connections
version: 1
---

**Least privilege** says every person, program and machine gets the access its job needs and nothing
more. On a network, access is concrete: **which machine may open a connection to which, on which port,
and when**. That makes the principle unusually testable here, because every privilege is a cell of the
matrix and a cell can be tried.

The baseline of lesson 4 already applies it between zones: the staff reach the application and not the
database, the proxy reaches the application and nothing else. What the zone matrix cannot express is
finer than a zone. In your lab this lesson starts from `sudo bash nslab.sh reset`, with the company's
policy loaded on `fw` by `nft -f baseline.nft`. Who reaches the database today:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  open
ana@laptop:~$ probe db:5432 db:22
db:5432                blocked
db:22                  blocked
ana@admin:~$ probe db:5432 db:22
db:5432                blocked
db:22                  open
```

From the staff LAN, nothing, as the matrix says. From the management machine, SSH, as the matrix says.
And from `app`, **both the database port and SSH**, because `app` shares the servers segment with `db`
and the firewall never sees that traffic (lesson 4). `app` needs the database; it has no reason to log in
to the database's machine. If `app` is compromised through a flaw in the application, that extra door is
the attacker's next step.

Least privilege on a network takes four forms, and this lesson builds each on the lab:

| form | the question it answers | here |
|---|---|---|
| **one service, one source** | who may open this port | `db` accepts 5432 from `app` only |
| **one way in for administration** | where administrators connect from | SSH only from the jump host, with a key tied to it |
| **no outbound by default** | what may this machine start | `db` starts no connections at all |
| **access that expires** | for how long | a vendor's access removed by the clock, not by memory |

The cost is the same as always: every privilege denied is one somebody may need someday, and the
answer to that is a change request and a new cell, never a wider rule written in advance just in case.
