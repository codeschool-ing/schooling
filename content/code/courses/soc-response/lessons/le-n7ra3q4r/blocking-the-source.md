---
title: Blocking the source, and what it is worth
version: 1
---

The logins on Thursday came from `203.0.113.66`. Blocking that address at the firewall is the move everybody
reaches for first, and it is worth seeing exactly what it buys. `nc -z` only opens a connection and closes it
again; `-s` picks which of `outside`'s addresses it leaves from:

```
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
root@soc:~# ip netns exec fw nft insert rule ip fw forward ip saddr 203.0.113.66 counter drop comment '"INC-2026-014 source"'
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"
exit 1
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.200 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
```

Before the rule, `203.0.113.66` reaches `gw`'s SSH port. `nft insert rule` puts the new rule at the **top**
of the chain, not the end, so it is checked before anything else. After it, the same connection fails (`nc`
exits with `1`). And then the last line: **the same machine, leaving from a different address, gets straight
through.**

That is lesson 9's pyramid of pain, from the defender's side. An IP address sits near the bottom: it costs
the other side almost nothing to change. A block on one address stops the laziest next attempt and nothing
more. **It is still worth doing**, because it costs almost nothing and it is quick, but it is not what
contains Thursday's incident. What the intruder had was **bruno's password, and then a key on `gw`**. Those
work from any address in the world, and the firewall knows nothing about them.

So the move that really contains a compromised account is the account: lock it, reset the password, and
revoke every key and session it has, on every host in the scope. Lesson 14 is where the key that was added on
`gw` gets found and removed, with the evidence of it kept; here the account is locked so that the key, the
password and any session cannot be used in the meantime.

Every rule added in a response is temporary, and it has to come out again on purpose. The handle is how:

```
root@soc:~# ip netns exec fw nft -a list chain ip fw forward
table ip fw {
	chain forward { # handle 1
		type filter hook forward priority filter; policy accept;
		ip saddr 203.0.113.66 counter packets 9 bytes 420 drop comment "INC-2026-014 source" # handle 4
		ct state new log prefix "fw-new " group 1 # handle 2
		ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter packets 5 bytes 300 drop comment "INC-2026-014 files egress" # handle 3
	}
}
root@soc:~# ip netns exec fw nft delete rule ip fw forward handle 4
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
```

The insert put the new rule at handle **4**, on top of the chain; `nft delete rule ... handle 4` removes it,
and the connection works again. Deleting by handle removes exactly that rule and no other. **Every rule
added during an incident goes into the decision log with its handle and its comment**, so that removing it
is a lookup and not an archaeology project. A forgotten emergency rule is how a firewall ends up with three
hundred lines nobody dares touch.
