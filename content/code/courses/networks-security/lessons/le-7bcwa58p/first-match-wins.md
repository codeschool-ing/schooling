---
title: First match wins, so position is meaning
version: 1
---

A chain is read from the top, and **the first rule whose conditions all match decides**. Every rule
below it is never consulted for that packet. That one fact explains most rule-set bugs: a rule can be
perfectly written and do nothing at all, because something above it already decided.

In your lab this lesson starts from `sudo bash nslab.sh reset`, and every section begins by loading
the company's policy afresh on `fw`, with `nft -f baseline.nft`, so that each mistake is made on a
clean copy. `laptop` has to be cut off while somebody investigates it. The administrator adds a rule
to the baseline:

```
root@fw:~# nft add rule ip filter forward ip saddr 192.168.10.20 counter drop comment '"laptop quarantined, ticket 5120"'
```

`nft add` appends: the rule goes to **the end** of the chain. Then `laptop` tries its usual services:

```
ana@laptop:~$ probe app:8080 www:443
app:8080               open
www:443                open
```

**Both still open.** The quarantine did nothing, and the rule listing says why:

```
root@fw:~# nft -a list chain ip filter forward | grep -E "staff use|quarantined" | sed "s/^\t*//"
iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application" # handle 10
ip saddr 192.168.10.20 counter packets 0 bytes 0 drop comment "laptop quarantined, ticket 5120" # handle 20
```

The staff rule, handle 10, sits above the quarantine, handle 20, and accepts `laptop`'s connection to
the application before the drop is ever read; the web rule does the same for `www`. The drop's counter
is **0 packets**. A rule that is **shadowed**, entirely covered by rules above it, looks exactly like a
working rule in the file, and only its counter gives it away.

The fix is position. The handles show where things are:

```
root@fw:~# nft -a list chain ip filter forward | sed -n "3,4p;/quarantined/p" | sed "s/^\t*//"
type filter hook forward priority filter; policy drop;
ct state established,related accept # handle 3
ip saddr 192.168.10.20 counter packets 0 bytes 0 drop comment "laptop quarantined, ticket 5120" # handle 20
root@fw:~# nft delete rule ip filter forward handle 20
root@fw:~# nft insert rule ip filter forward position 4 ip saddr 192.168.10.20 counter drop comment '"laptop quarantined, ticket 5120"'
```

`insert … position 4` puts the rule before handle 4, directly after the rule for established traffic,
so every new connection from `laptop` meets it before any `accept`:

```
root@fw:~# nft list chain ip filter forward | sed -n "3,6p" | sed "s/^\t*//"
type filter hook forward priority filter; policy drop;
ct state established,related accept
ip saddr 192.168.10.20 counter packets 0 bytes 0 drop comment "laptop quarantined, ticket 5120"
ct state invalid drop
ana@laptop:~$ probe app:8080 www:443
app:8080               blocked
www:443                blocked
root@fw:~# nft list chain ip filter forward | grep quarantined | sed "s/^\t*//"
ip saddr 192.168.10.20 counter packets 2 bytes 120 drop comment "laptop quarantined, ticket 5120"
```

Blocked, and the counter shows the two attempts. The quarantine in lesson 9 used `insert` without a
position, which puts a rule at the very top, above even established traffic, and cuts connections that
were already open. Which of the two is wanted is a decision; **`add` is almost never what a quarantine
wants.**

Order also costs time. Every packet walks the chain until something matches, so rules that match most
traffic belong near the top, which is why lesson 1 put `established,related` first. Long lists of
addresses belong in a set, which nftables looks up in one step rather than rule by rule.
