---
title: Verifying continuously, not once
version: 1
---

Lesson 20 made every **new connection** prove its identity. **Continuous verification** asks the harder
question: what about a connection, or a session, that was allowed a minute ago and should not be now?

Access changes while sessions are open. An employee leaves, a device fails its health check, a server
is found compromised, a ticket closes. A decision made at the start of a session and never revisited
keeps granting access its reasons no longer support.

The lab shows the gap precisely. The database stand-in on `db` now keeps a session open, as a real
database keeps a client's connection. `app` opens one, sends a line, and six seconds later another.
Both halves are started as root, the new stand-in on `db` and the client on `app`:

```sh
# on db: the one-line stand-in replaced by one that repeats what it is sent
kill $(ss -Hltnp "sport = :5432" | grep -o "pid=[0-9]*" | cut -d= -f2); sleep 0.3; setsid socat TCP-LISTEN:5432,bind=192.168.20.30,fork,reuseaddr EXEC:cat </dev/null >/dev/null 2>&1 &
# on app: the client, in the background, writing what comes back to client.out
rm -f /root/client.out; setsid bash -c "(echo first; sleep 6; echo second; sleep 1) | nc -N -w8 192.168.20.30 5432 > /root/client.out" </dev/null >/dev/null 2>&1 &
```

While it waits, the session is in `db`'s connection table:

```
root@db:~# conntrack -L -p tcp --dport 5432 2>/dev/null | grep ESTABLISHED | sed "s/ src=192.168.20.30.*//"
tcp      6 431997 ESTABLISHED src=192.168.20.10 dst=192.168.20.30 sport=52666 dport=5432
```

Then the policy changes: `app` is withdrawn from the database, and `db`'s rules are regenerated without
its accept line:

```
root@db:~# sed -i 's/ip saddr { 192.168.20.10 } tcp dport 5432 accept.*/# app withdrawn from the database, ticket 6203/' segment.nft && nft -f segment.nft && nft list chain inet host input | grep -c 5432
0
```

No rule on `db` mentions port 5432 any more. Six seconds later, what the client received:

```
root@app:~# cat client.out
first
second
```

**Both lines.** The second went through after the rule was gone. The host firewall's first rule, the
one from lesson 1, accepts `established` traffic, and the session was established before the change.
The new policy applies to **new** connections only.

The same property is what makes stateful firewalls efficient; here it is the gap continuous verification
has to close. The next section closes it.
