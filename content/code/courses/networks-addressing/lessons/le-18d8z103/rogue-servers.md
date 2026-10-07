---
title: A second server nobody asked for
version: 2
---

DHCP has no notion of an official server. **A client takes the first offer that arrives, from
whoever sent it**, and any machine on the subnet can answer a broadcast. A second DHCP server on a
LAN is most often an accident: a home router plugged in by one of its LAN ports to get a few more
sockets. Now and then it is an attack, because whoever answers decides the client's gateway and name
server. Either way, the clients that listen to it are cut off or sent somewhere else.

In the lab, the PC called rogue was turned into a second server that lends 10.20.10.200 upwards and
names itself, 10.20.10.66, as the gateway. How it was started is not part of this lesson; what it
does to the network is. Your `dhcp.sh` has no second server, so this section is one to read rather
than type: the output is the point. pc2 asks for an address, with a `tcpdump` running on pc2 in a second
terminal that prints after it:

```
ana@pc2:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"
DHCPOFFER of 10.20.10.101 from 10.20.10.10
DHCPACK of 10.20.10.101 from 10.20.10.10 (xid=0x25a4e4f)
bound to 10.20.10.101 -- renewal in 251 seconds.
root@pc2:~# timeout 12 tcpdump -n -i eth0 udp src port 67
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:21:27.072890 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300
08:21:27.083101 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300
08:21:28.091759 IP 10.20.10.66.67 > 10.20.10.200.68: BOOTP/DHCP, Reply, length 300

3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

pc2 took the real server's offer, 10.20.10.101 from 10.20.10.10. The capture shows that it was a
race. Two replies from 10.20.10.10, the offer and the ACK, and then **a third reply, from
10.20.10.66, offering 10.20.10.200**, a second later. The real server was faster this time, and
nothing guarantees that it always will be.

To see the other outcome, the real server is paused: `kill -STOP` freezes the process without ending
it, the way an overloaded server would sit and not answer. Then pc2 asks again:

```
root@srv:~# kill -STOP $(cat /run/lab/srv/dhcpd.pidfile)
ana@pc2:~$ sudo dhclient -r eth0; sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"
Killed old client process
DHCPOFFER of 10.20.10.200 from 10.20.10.66
DHCPACK of 10.20.10.200 from 10.20.10.66 (xid=0xae5dac3e)
bound to 10.20.10.200 -- renewal in 272 seconds.
ana@pc2:~$ ip route
default via 10.20.10.66 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.200 
ana@pc2:~$ ping -c 2 -W 1 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.

--- 10.20.20.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1040ms

```

(`Killed old client process` is `dhclient -r` ending the previous client.) The only offer came
from 10.20.10.66, and pc2 accepted it. Its default route now points at rogue, and a ping to
10.20.20.1, r1's address on the other floor, loses both packets. rogue is not a router, so **pc2 has
a working address and no way out**. A rogue that did forward the traffic would be worse, because
nothing would look broken while every packet passed through somebody else's machine. The real server
is then let go:

```
root@srv:~# kill -CONT $(cat /run/lab/srv/dhcpd.pidfile)
```

The defence lives on the switch, because only the switch knows which port each frame came in on.
**DHCP snooping marks the port towards the real server as trusted and every other port as untrusted,
and drops server messages that arrive on an untrusted port.** Offers and ACKs are recognisable by
their source, UDP port 67. A managed switch has snooping as a feature to switch on per VLAN; this
lab's switch is a Linux bridge, and one nftables rule does the same job. srv is plugged into port
p4:

```
root@sw1:~# nft add table bridge snoop
root@sw1:~# nft add chain bridge snoop forward "{ type filter hook forward priority 0; }"
root@sw1:~# nft add rule bridge snoop forward iifname != "p4" udp sport 67 counter drop
```

Read the rule from the left: in the bridge's forwarding path, a frame that came in on any port other
than `p4` and carries UDP from source port 67 is counted and dropped. pc2 asks again, with the same
`tcpdump` beside it:

```
ana@pc2:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"
DHCPOFFER of 10.20.10.101 from 10.20.10.10
DHCPACK of 10.20.10.101 from 10.20.10.10 (xid=0xa3cfec6e)
bound to 10.20.10.101 -- renewal in 298 seconds.
root@pc2:~# timeout 12 tcpdump -n -i eth0 udp src port 67
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:21:57.406295 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300
08:21:57.418782 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300

2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@pc2:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.101 
```

Two replies reach pc2 now, both from 10.20.10.10, and the default route is r1 again. The counter
says what happened to the rogue's offer:

```
root@sw1:~# nft list table bridge snoop
table bridge snoop {
	chain forward {
		type filter hook forward priority 0; policy accept;
		iifname != "p4" udp sport 67 counter packets 1 bytes 328 drop
	}
}
```

**`counter packets 1 bytes 328 drop`: one server message arrived on a port with no business sending
one, and the switch threw it away.** That counter is also the alarm. A number that keeps rising
means a server is answering from a port where none should be, and the port tells you which desk to
walk to. A switch's snooping feature also keeps a table of which address it saw lent to which MAC
address on which port, and other protections are built on that table; Cisco calls two of them
Dynamic ARP Inspection and IP Source Guard.

This lab's rule is blunter than a switch's feature. It drops everything from UDP port 67, and the
relay's forwarded requests leave r1 from port 67 as well — the capture in the relay section shows
`10.20.10.1.67`. With both the relay and this rule running, p8, the port towards r1, would have to
be trusted too, or the second floor would lose DHCP to its own protection.
