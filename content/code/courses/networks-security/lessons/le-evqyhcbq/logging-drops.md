---
title: Logging what the policy drops
version: 1
---

A policy of `drop` is silent by design: the sender gets nothing, and neither does the administrator.
A rule placed **last in the chain**, just before the policy, can record what is about to be dropped:

```
root@fw:~# nft list chain ip filter forward | tail -3
		limit rate 5/second burst 5 packets log prefix "fw-drop " group 1 comment "what the policy is about to drop"
	}
}
```

`log group 1` hands each packet to netfilter's logging group 1, where any program can read it, and
the prefix labels the lines. `limit rate 5/second` matters as much as the log itself: without it,
anybody can fill the disk by sending packets the firewall drops, and the log becomes the attack.

`tcpdump` can read that group directly. With it listening on `fw`, `remote` tries two cells that are
closed, and `laptop` one:

```
ana@remote:~$ probe db:5432 app:22
db:5432                blocked
app:22                 blocked
ana@laptop:~$ probe db:6379
db:6379                blocked
root@fw:~# cat drops.txt
15:35:01.265985 IP 203.0.113.50.46266 > 192.168.20.30.5432: Flags [S], seq 2762589466, win 64240, options [mss 1460,sackOK,TS val 1098298975 ecr 0,nop,wscale 10], length 0
15:35:01.266119 IP 203.0.113.50.37090 > 192.168.20.10.22: Flags [S], seq 656771972, win 64240, options [mss 1460,sackOK,TS val 1254501168 ecr 0,nop,wscale 10], length 0
15:35:03.286338 IP 192.168.10.20.58758 > 192.168.20.30.6379: Flags [S], seq 4277655433, win 64240, options [mss 1460,sackOK,TS val 4274771377 ecr 0,nop,wscale 10], length 0
```

Three dropped connection attempts, each a TCP `SYN` with its source, destination and port. **This is
what the drop log is for.** `203.0.113.50` trying the database and SSH is the internet doing what it
does all day. `192.168.10.20` trying port 6379 is a machine on the staff LAN reaching for a service
it was never given. The second kind is far rarer and far more interesting, and a drop log
is often where somebody first notices a misconfigured program, or a compromised laptop.

Two cautions. A busy firewall's drop log is mostly the internet's background noise, so it is read by
filtering, not by eye; lesson 23 decides what is worth keeping. And a log rule anywhere but last
records traffic that later rules would have allowed, which is noise of a different kind.
