---
title: A way in: port forwarding
version: 1
---

Every connection so far started inside the office. The other direction is the one NAT does not handle
by itself: **a connection that starts outside has only the public address to aim at, and nothing in
r1's table says which machine inside should get it.**

Try it from the provider's side. isp is first given a route to the office's private network through
r1 — which a real provider would never have, done here to show that the address is not the only
obstacle — and then asks for srv's web page, directly and through the public address:

```
root@isp:~# ip route add 10.20.10.0/24 via 203.0.113.2
root@isp:~# curl -s -m 4 http://10.20.10.10/; echo "exit status $?"
exit status 28
root@isp:~# curl -s -m 4 http://203.0.113.2:8080/; echo "exit status $?"
exit status 7
```

Both fail, for different reasons, and the exit status says which. `28` is curl's code for a timeout:
the request to `10.20.10.10` reached r1, and r1's forward chain, whose policy is `drop`, dropped it,
since no rule allows a connection from eth1 into eth0. The firewall answered by not answering. `7` is
curl's code for a failure to connect: the request to `203.0.113.2:8080` was addressed to r1 itself,
r1 has nothing on port 8080, and its kernel refused at once — the same refusal lesson 5 met on port
8000.

**Port forwarding, or destination NAT, is a rule that says: what arrives on this public port goes to
that inside address and port.** On r1 it takes a chain, a rule and a permission:

```
root@r1:~# nft add chain ip nat prerouting "{ type nat hook prerouting priority dstnat; }"
root@r1:~# nft add rule ip nat prerouting iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80
root@r1:~# nft insert rule inet filter forward ct status dnat accept
```

- the first command creates a `prerouting` chain in the `nat` table. It runs as a packet arrives,
  before r1 decides where to send it, which is the moment the destination has to change;
- the second is the forward itself: arriving on `eth1`, TCP to port `8080`, change the destination to
  `10.20.10.10:80`;
- the third lets those connections through the firewall: `ct status dnat` matches any connection whose
  destination was translated, and `insert` puts the rule at the top of the forward chain, ahead of the
  drop.

From isp, the public address now answers:

```
root@isp:~# curl -s -m 4 http://203.0.113.2:8080/
served by srv
```

`served by srv`: the page came from the server inside. r1's table shows the translation:

```
root@r1:~# conntrack -L -p tcp --dport 8080
conntrack v1.4.8 (conntrack-tools): 1 flow entries have been shown.
tcp      6 119 TIME_WAIT src=203.0.113.1 dst=203.0.113.2 sport=40940 dport=8080 src=10.20.10.10 dst=203.0.113.1 sport=80 dport=40940 [ASSURED] mark=0 use=1
```

isp connected to `203.0.113.2` port `8080`, and r1 expects the reply from `10.20.10.10` port `80`.
This time it is the destination that was rewritten, and on the way back r1 rewrites the reply's source
so that it seems to come from 203.0.113.2:8080. srv saw the connection arrive from isp's real address,
`203.0.113.1`, because nothing rewrote the source. The whole ruleset, with the forward in it:

```
root@r1:~# nft list ruleset
table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oifname "eth1" masquerade
	}

	chain prerouting {
		type nat hook prerouting priority dstnat; policy accept;
		iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80
	}
}
table inet filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct status dnat accept
		ct state established,related counter packets 52 bytes 3603 accept
		iifname "eth0" oifname "eth1" counter packets 7 bytes 444 accept
		counter packets 4 bytes 240 comment "everything else: dropped"
	}
}
```

The `nat` table now has two chains, one for each direction of translation. In `inet filter`, the
counters keep the history: 4 packets reached the last rule and were dropped, among them the attempts on
10.20.10.10 that timed out, while 52 packets of established connections went through.

**A forward opens a service to the whole internet**, so it is a decision rather than a setting.
Forward only the ports a service needs, to the one machine that serves them; keep that machine
patched, because anyone can now reach it; and where the clients are known, put their addresses in the
rule. A non-standard public port such as 8080 hides nothing — scanners try every port. And home
routers that open ports on request from devices inside, through UPnP, take the same decision without
anybody taking it, which is the reason to switch that off where nothing needs it.
