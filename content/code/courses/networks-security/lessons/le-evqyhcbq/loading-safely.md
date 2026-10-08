---
title: Checking a rule set before it is live
version: 1
---

A firewall's rule set is a program that runs on every packet, and it is edited by people in a hurry.
Two properties of `nft` make editing it safer, and both are worth using on purpose.

**Check before loading.** `nft -c` parses the file and checks it against the running kernel without
changing anything. A copy of the baseline with one word misspelt, `acept` where `accept` belongs, made
on `fw` with
`sed "s/ct state new accept comment \"staff browse\"/ct state new acept comment \"staff browse\"/" baseline.nft > typo.nft`:

```
root@fw:~# nft -c -f typo.nft; echo "exit $?"
typo.nft:7:88-94: Error: syntax error, unexpected comment
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new acept comment "staff browse"
                                                                                       ^^^^^^^
exit 1
root@fw:~# nft list ruleset | grep -c accept
11
```

The error names the file, the line and the columns, and the running rule set is untouched: 11
`accept`s before and after.

**Loading is atomic.** `nft -f` applies a whole file as one transaction: every line takes effect, or
none does. The same broken file, loaded for real:

```
root@fw:~# nft -f typo.nft; echo "exit $?"
typo.nft:7:88-94: Error: syntax error, unexpected comment
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new acept comment "staff browse"
                                                                                       ^^^^^^^
exit 1
root@fw:~# nft list ruleset | grep -c accept
11
```

Still 11. **Nothing half-applied.** That matters most with a file that begins `flush ruleset`, as
these do. Without atomic loading, a mistake on line 7 would leave the firewall flushed, with only
lines 1 to 6 loaded. Under a policy of `drop` almost nothing would pass; under `accept`, almost
everything would.

`iptables` loads one rule per command, so a script of fifty `iptables` lines that fails at line 20
leaves nineteen applied. `iptables-restore` exists for exactly this reason, and does for a whole
file what `nft -f` does.

A rule set that parses is not a rule set that is right. The only check of that is lesson 4's: probe
every cell from the zone where it starts, after every change.
