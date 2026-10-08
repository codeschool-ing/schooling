---
title: Ending what is already open
version: 1
---

Withdrawing access has two halves: stop new connections, and **end the ones already open**. The first is
the rule; the second, on Linux, is removing the conntrack entries, after which the next packet of the
session matches nothing and falls to the policy.

The session is opened again, after the database rule is put back on `db` with
`nft -f /dev/stdin <<<"$(sed "s/# app withdrawn from the database, ticket 6203/ip saddr { 192.168.20.10 } tcp dport 5432 accept/" /root/segment.nft)"`
and the client on `app` is started as before. This time the withdrawal does both, loading the rules
and deleting the application's entries for port 5432:

```
root@db:~# nft -f segment.nft && conntrack -D -p tcp --dport 5432 -s 192.168.20.10 -u ASSURED 2>&1 >/dev/null
conntrack v1.4.8 (conntrack-tools): 2 flow entries have been deleted.
```

Two entries deleted: the new session, and the previous one, closed and still waiting out its
`TIME_WAIT`. What the client received this time:

```
root@app:~# cat client.out
first
```

**Only the first line.** The second was sent into a session the database no longer recognised, and it
never arrived. The table confirms nothing is left:

```
root@db:~# conntrack -L -p tcp --dport 5432 2>/dev/null | grep ESTABLISHED | sed "s/ src=192.168.20.30.*//"
```

Every access-control system that can revoke has to answer this question somewhere, and the answers
look alike:

| layer | how a live session is ended |
|---|---|
| a Linux host firewall | delete the conntrack entries, as here |
| a network firewall | clear its session table for the address |
| TLS with client certificates | close the connections; the next handshake checks the certificate again (lesson 20) |
| an application | invalidate the session on the server side, as lesson 7 asked of cookies |
| single sign-on | revoke the tokens, and keep their lifetimes short so the rest expire soon |

**A revocation that leaves open sessions running is only a schedule.** The last row states the general
answer: keep every grant short, so that re-verification happens on its own, often, and a withdrawal
takes effect within one lifetime even where nothing actively cuts the session.
