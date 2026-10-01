---
title: A way back, before you lock yourself out
version: 1
---

The classic firewall accident is not a hole. It is the administrator, connected over SSH, loading a
rule set that drops their own session, and then driving to the building. Network devices built for
this have a *commit confirmed*: the change reverts on its own unless it is confirmed within some
minutes. `nft` has no such command, and the same safety net takes one line.

First, save what works:

```
root@fw:~# nft list ruleset > known-good.nft; wc -l known-good.nft
21 known-good.nft
```

Then schedule the way back **before** making the change, and make it. The new file is a stricter input
chain that, by mistake, no longer allows SSH from the management segment:

```
root@fw:~# (sleep 5; nft -f known-good.nft; echo "rolled back at $(date +%T)" > rollback.log) > /dev/null 2>&1 & nft -f tighter.nft; date +%T; nft list ruleset | grep -c accept
15:34:47
2
ana@admin:~$ probe fw:22
fw:22                  blocked
```

`admin` is locked out, as the SSH session would have been. Five seconds later, the background job
restores the saved rule set whether anybody is still connected or not. If the change had worked, the
administrator would have killed that job instead, which is the *confirm*. In real use the timer is a
few minutes, long enough to test from where you are.

## The rollback that doubled the rules

The rollback ran, and the count of `accept` lines came back as **13**, not the 11 that were saved.
The input chain shows why:

```
root@fw:~# cat rollback.log; nft list ruleset | grep -c accept
rolled back at 15:34:52
13
root@fw:~# nft list chain ip filter input
table ip filter {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		ct state established,related accept
		iifname "lo" accept
		iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
	}
}
```

Every rule of the tighter file is there twice. **`nft list ruleset` prints the rules and not an
instruction to clear what was there before**, so loading its output adds to whatever is loaded now:
here, on top of the two rules of the stricter chain. A saved rule set has to begin with `flush
ruleset` to replace rather than merge:

```
root@fw:~# nft -f baseline.nft; { echo "flush ruleset"; nft list ruleset; } > known-good.nft; head -3 known-good.nft
flush ruleset
table ip filter {
	chain forward {
root@fw:~# nft -f known-good.nft; nft list ruleset | grep -c accept
11
```

With `flush ruleset` as its first line, the saved file puts back exactly what was saved: 11. A rollback
plan contains details like this one, and nobody tests them until the night they are needed. Test it
on an afternoon when nothing depends on it.
