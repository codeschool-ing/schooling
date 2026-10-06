---
title: Drawing the zones
version: 1
---

The policy for the shop fits in three sentences, and each becomes one rule:

1. the internet may reach the shop's web server, on the web port, and nothing else;
2. the shop's web server may reach the database, on the database port, and nothing else;
3. the office may reach the internet and the shop.

Everything not named is refused. That last sentence is the most important line in the policy and
it is not a rule at all: it is the firewall's **default**. A policy that lists what is allowed and
refuses everything else is called **default deny**, and it is the only kind that stays safe when
somebody adds a machine and forgets to think about it.

Here are the rules as the lab's firewall reads them, in `nftables`, the firewall built into Linux.
The administrator shows the file, then loads it:

```
root@fw:~# cat zones.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport 80 accept comment "the internet reaches the shop"
    iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.30 tcp dport 5432 accept comment "the shop reaches its database"
    iifname "eth2" oifname { "eth0", "eth1" } accept comment "the office reaches the internet and the shop"
  }
}
root@fw:~# nft -f zones.nft
```

You do not need to learn the syntax to read it. `policy drop` is default deny: anything that reaches
the end of the list is dropped. The line beginning `ct state established,related` lets replies come
back on connections that were already allowed, so each rule only has to describe the side that
starts the conversation. The three lines after it are the three sentences above, each with a
comment saying so. `eth0` is the firewall's leg on the internet, `eth1` on the DMZ, `eth2` on the
office and `eth3` on the servers.

Now the same probes, from the same three places:

```
ana@outside:~$ probe www:80 db:5432
www:80                 open
db:5432                blocked
ana@www:~$ probe db:5432 db:22 laptop:22
db:5432                open
db:22                  blocked
laptop:22              blocked
ana@laptop:~$ probe www:80 db:5432
www:80                 open
db:5432                blocked
```

Every line is the policy, tested:

| from | to | before | after | why |
|---|---|---|---|---|
| the internet | `www:80` | open | open | rule 1 |
| the internet | `db:5432` | open | **blocked** | nothing allows it |
| `www` | `db:5432` | open | open | rule 2 |
| `www` | `db:22` | refused | **blocked** | rule 2 names port 5432 only |
| `www` | `laptop:22` | refused | **blocked** | the DMZ may not reach the office |
| the office | `www:80` | open | open | rule 3 |
| the office | `db:5432` | open | **blocked** | rule 3 does not include the servers |

Two rows changed from `refused` to `blocked`, and the difference matters. Before, the attempt
reached the machine and the machine said no. Now the attempt never arrives. A compromised `www`
cannot even learn which ports `laptop` has open, which is the first thing an attacker moving
laterally would want to know.

**Testing from every zone is part of writing the rule.** A rule set that was only tested from the
office, where its author sits, says nothing about what the internet or a compromised server can do.
The table above is the test, and it is short enough to run again every time a rule changes.
