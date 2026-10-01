---
title: Deny by default, because nobody knows the whole list
version: 1
---

There are two ways to write a firewall's policy. A **blocklist** allows everything and names what to
refuse. An **allowlist** refuses everything and names what to allow. They can describe the same
network on the day they are written, and they diverge from the next day on.

A blocklist, written by somebody who knows which ports are dangerous:

```
root@fw:~# cat blocklist.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy accept;
    iifname "eth0" tcp dport { 23, 445, 3389 } drop comment "ports we know are dangerous"
    iifname "eth0" tcp dport 5432 drop comment "the database"
  }
}
root@fw:~# nft -f blocklist.nft
ana@remote:~$ probe db:5432 app:22 app:8080
db:5432                blocked
app:22                 open
app:8080               open
```

The database is `blocked`. SSH on the application server and the application itself are `open` to
the whole internet, because nobody thought to list them. Then a developer installs a cache on `db`,
listening on 6379, and tells nobody:

```
ana@remote:~$ probe db:6379
db:6379                open
```

**The new service was exposed the moment it started**, with no change to the firewall. A blocklist
has to know every service that will ever exist, and the list is always written before the next one
arrives.

The same network under the baseline of lesson 4, whose policy is `drop`:

```
root@fw:~# nft -f baseline.nft
ana@remote:~$ probe db:5432 app:22 app:8080 db:6379 www:443
db:5432                blocked
app:22                 blocked
app:8080               blocked
db:6379                blocked
www:443                open
```

Everything the matrix does not name is `blocked`, **including the service nobody told the firewall
about**. The shop still answers, because it is named. The cost of an allowlist is the opposite
mistake: something legitimate that nobody listed is refused, and somebody complains. That failure is
loud and gets fixed within the day. The blocklist's failure is silent and gets found by whoever is
scanning the internet that week.

**Deny by default** is this choice made once, for every chain: the policy is `drop`, and every
`accept` is a decision somebody can point to. It is also why lesson 4 wrote a matrix whose empty cells
mean *denied*, rather than a list of things to stop.
