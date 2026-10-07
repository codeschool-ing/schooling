---
title: SLAAC, an address built from an advertisement
version: 2
---

The IPv4 habit says a PC gets its address from a DHCP server, which lesson 10 covers. IPv6 has
DHCP too, but **on most LANs the PCs build their own global addresses**. The router announces the
network's prefix, and each machine glues its own interface identifier to the end. That is
**SLAAC**, stateless address autoconfiguration: stateless because nobody keeps a list of who has
which address.

The announcement is a **Router Advertisement**, an ICMPv6 message. r1 runs a program called radvd
that sends one every 30 to 100 seconds in this lab's configuration, and also in answer to a
**Router Solicitation**, which a machine sends to ask. `rdisc6` sends that question, to `ff02::2`,
the address every router on a link listens on, and prints the answer:

```
ana@pc2:~$ rdisc6 eth0
Soliciting ff02::2 (ff02::2) on eth0...

Hop limit                 :           64 (      0x40)
Stateful address conf.    :           No
Stateful other conf.      :           No
Mobile home agent         :           No
Router preference         :       medium
Neighbor discovery proxy  :           No
Router lifetime           :          300 (0x0000012c) seconds
Reachable time            :  unspecified (0x00000000)
Retransmit time           :  unspecified (0x00000000)
 Prefix                   : 2001:db8:20:10::/64
  On-link                 :          Yes
  Autonomous address conf.:          Yes
  Valid time              :        86400 (0x00015180) seconds
  Pref. time              :        14400 (0x00003840) seconds
 Source link-layer address: 02:1F:23:E7:E9:D5
 from fe80::1f:23ff:fee7:e9d5
```

Read it from the top. `Hop limit: 64` is the starting hop limit the router suggests for packets,
IPv6's name for IPv4's TTL. `Stateful address conf.: No` is the router saying there is no DHCPv6
server handing out addresses here. `Router lifetime: 300` says r1 may be used as the default router
for the next 300 seconds; a fresh advertisement renews it. Then the part that matters most: **the
prefix `2001:db8:20:10::/64`, with `Autonomous address conf.: Yes`, which is the router telling every
machine to build its own address from it**. `On-link: Yes` says every address in the prefix is
reachable directly, without the router. The last line, `from fe80::1f:23ff:fee7:e9d5`, is r1's
link-local address from the previous section: routers advertise from their link-local address.

pc2 did what it was told:

```
ana@pc2:~$ ip -6 addr show eth0 scope global
30: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 2001:db8:20:10:fd:f2ff:fed2:63ba/64 scope global dynamic mngtmpaddr 
       valid_lft 86396sec preferred_lft 14396sec
ana@pc2:~$ ip -6 route
2001:db8:20:10::/64 dev eth0 proto kernel metric 256 expires 86394sec pref medium
fe80::/64 dev eth0 proto kernel metric 256 pref medium
default via fe80::1f:23ff:fee7:e9d5 dev eth0 proto ra metric 1024 expires 294sec hoplimit 64 pref medium
```

pc2's address is `2001:db8:20:10:fd:f2ff:fed2:63ba`: the advertised prefix, then an identifier with
`ff:fe` in the middle, built from pc2's MAC exactly as pc1's link-local address was. `dynamic` marks
an address that came from an advertisement and will expire unless it is renewed.

The two lifetimes come from the prefix lines of the advertisement. `Valid time: 86400` seconds is
one day, `Pref. time: 14400` seconds is four hours, and pc2 shows them counting down:
`valid_lft 86396sec preferred_lft 14396sec`, four seconds after it heard them. **While the
preferred lifetime lasts, the address is used for new connections.** After it, the address is
deprecated and kept only for connections already open, and when the valid lifetime ends it goes. Each new
advertisement starts both clocks again, so on a healthy network neither ever reaches zero. A
router that stops advertising is a network whose addresses fade out over a day.

The route table has the last surprise. **The default route is `via fe80::1f:23ff:fee7:e9d5`, r1's
link-local address, not its global one**, with `proto ra` saying it was learnt from the
advertisement and `expires 294sec` counting down the router lifetime of 300. That is normal in
IPv6: a gateway only has to be reachable on the link, and the link-local address is the one that
never changes when the network is renumbered. It is also why a gateway shown as `fe80::…` is
always paired with an interface, here `dev eth0`.

srv took no part in any of this. `dualstack.sh` turned autoconfiguration off on it and gave it
`2001:db8:20:10::10` by hand, as servers are usually given addresses: **a server's address should
not depend on which network card it happens to have today**. A replaced card under SLAAC with EUI-64
means a new address, and every client that had the old one written down stops working.
