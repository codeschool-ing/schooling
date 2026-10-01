---
title: Filtering where the VLANs meet
version: 1
---

Lesson 19 gave control as one of the reasons for VLANs, and this is where it is collected. Once
routing connects two VLANs, the default is that everything in one reaches everything in the other,
which is the flat network again with an extra hop. **The router between VLANs is the one place every
packet between them has to pass, so it is the place to decide which of them may.** On commercial
equipment the rules are called access control lists, ACLs; on Linux they are written with
`nftables`, and the switch from the last section is now the router to write them on.

The policy here is small and typical: VLAN 20 may use the web server srv on port 80 and nothing
else in VLAN 10. VLAN 10 is not restricted.

```
root@sw1:~# nft add table inet acl
root@sw1:~# nft add chain inet acl forward "{ type filter hook forward priority 0; policy accept; }"
root@sw1:~# nft add rule inet acl forward ct state established,related accept
root@sw1:~# nft add rule inet acl forward iifname "vlan20" oifname "vlan10" ip daddr 10.20.10.10 tcp dport 80 accept
root@sw1:~# nft add rule inet acl forward iifname "vlan20" oifname "vlan10" counter drop
```

Read the rules in order, because they are checked in order and the first that matches decides. The
chain hooks `forward`, which sees only packets the switch routes from one interface to another, not
packets addressed to the switch itself, and its policy is `accept`: what no rule drops goes through.
The first rule accepts anything belonging to a conversation already allowed (`ct state
established,related`). The second accepts packets that enter from `vlan20`, leave by `vlan10`, and
go to 10.20.10.10 on TCP port 80. The third drops everything else going from `vlan20` to `vlan10`,
and `counter` makes it keep a tally.

```
ana@pc2:~$ curl -s -m 3 http://10.20.10.10/
served by srv
ana@pc2:~$ ping -c 2 -W 1 -q 10.20.10.21
PING 10.20.10.21 (10.20.10.21) 56(84) bytes of data.

--- 10.20.10.21 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1015ms

ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.932/1.037/1.143/0.105 ms
root@sw1:~# nft list table inet acl
table inet acl {
	chain forward {
		type filter hook forward priority filter; policy accept;
		ct state established,related accept
		iifname "vlan20" oifname "vlan10" ip daddr 10.20.10.10 tcp dport 80 accept
		iifname "vlan20" oifname "vlan10" counter packets 2 bytes 168 drop
	}
}
```

The three tests each prove one rule. pc2 fetches the page from srv: the second rule. pc2's ping to
pc1 loses both packets: the third. pc1's ping to pc2 gets both replies, although those replies
travel from VLAN 20 to VLAN 10 exactly like the dropped ping did: **the first rule lets them through
because they answer a conversation pc1 started.** That is what makes a firewall stateful, and it is
why the policy could be written in one direction only.

The listing confirms it with numbers. The drop rule reads `counter packets 2 bytes 168`: the two
echo requests from pc2, 84 bytes of IP each, the same 84 bytes that every ping in these two lessons
has carried. nftables also printed `priority filter` where the command typed `priority 0`, because
`filter` is the name it gives that number.

Two habits make rules like these hold up. **Write the allowed traffic, then refuse the rest**, as the
third rule does for VLAN 20; a list of things to block is a list of everything somebody has not
thought of yet. And test both what should pass and what should not: a rule set that was only ever
tested with the traffic it allows has not been tested. The lab's chain keeps `policy accept` so that
VLAN 10's traffic and everything else on the switch keep working while the lesson adds one
restriction; a production router would more often refuse by default and list what is allowed.
