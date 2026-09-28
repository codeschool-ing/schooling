---
title: One service, one source
version: 1
---

The firewall cannot separate `app` from `db`, so `db` does it itself, with a host firewall that knows
exactly one client for each of its two services:

```
root@db:~# cat host.nft
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    ip saddr 192.168.20.10 tcp dport 5432 accept comment "the application, and nothing else, uses the database"
    ip saddr 192.168.99.10 tcp dport 22 accept comment "administration from the jump host only"
  }
  chain output {
    type filter hook output priority filter; policy drop;
    ct state established,related accept
    oifname "lo" accept
    comment "the database starts no connections of its own"
  }
}
root@db:~# nft -f host.nft
```

The input chain allows **5432 from `app`'s address and nothing else**, and **SSH from `admin` and
nothing else**. The output chain is the less common half: a policy of `drop` on what the machine itself
starts, with only replies and loopback allowed. The comment on the empty rule says it in words: **the
database starts no connections of its own.**

From each machine that used to reach it:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  blocked
ana@admin:~$ probe db:5432 db:22
db:5432                blocked
db:22                  open
```

`app` keeps the database and loses SSH; `admin` keeps SSH and never had the database. And from `db`
outwards:

```
ana@db:~$ probe app:8080 www:443
app:8080               blocked
www:443                blocked
```

Nothing. A database has no reason to open a connection to the application, to the web or to anywhere
else, and one that tries has been told to by somebody who should not be telling it anything. **Output
filtering is the least used and most revealing of these controls**: when it drops something, the
counters say that a server tried to do something no server of its kind ever needs to do.

The price of output filtering is knowing what the machine legitimately starts: updates, time, logs
shipped to a collector, name resolution. Each is a line with a destination. A server whose
outbound needs nobody can list is a server nobody fully understands, which is worth finding out
before an incident rather than during one.
