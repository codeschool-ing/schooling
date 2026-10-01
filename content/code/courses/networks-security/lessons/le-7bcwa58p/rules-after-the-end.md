---
title: Rules after the end
version: 1
---

Some rule sets end with an explicit catch-all, a rule with no conditions that drops and counts
everything left, so that the final verdict is written in the chain rather than implied by the policy:

```
root@fw:~# nft add rule ip filter forward counter drop comment '"drop everything else, and count it"'
```

A sensible habit. Then, weeks later, finance needs its reporting tool on the staff LAN to read the
database, and the new rule is appended in the usual way:

```
root@fw:~# nft add rule ip filter forward iifname eth2 oifname eth3 ip daddr 192.168.20.30 tcp dport 5432 counter accept comment '"finance reporting reads the database"'
```

From the staff LAN, the database:

```
ana@laptop:~$ probe db:5432
db:5432                blocked
```

Blocked, and the listing shows the new rule sitting **below the catch-all**, which has already dropped
the attempt:

```
root@fw:~# nft list chain ip filter forward | tail -4 | head -2 | sed "s/^\t*//"
counter packets 1 bytes 60 drop comment "drop everything else, and count it"
iifname "eth2" oifname "eth3" ip daddr 192.168.20.30 tcp dport 5432 counter packets 0 bytes 0 accept comment "finance reporting reads the database"
```

The catch-all counted **1 packet**; the finance rule counted **0**, and nothing will ever reach it.
Every rule after an unconditional verdict is unreachable. It is the same first-match rule as the
shadowed quarantine, in its most blatant form, and it is common because appending is the default in
every tool: `nft add`, `iptables -A`, a web interface's *new rule* button.

**Two defences, both cheap.** Keep the rule set in a file, where the catch-all is visibly the last line
and a new rule is written above it, rather than editing the running chain. And rely on the policy for
the final verdict, with a counting rule that has no verdict of its own, as lesson 1 did; a rule that
only counts cannot hide anything below it.
