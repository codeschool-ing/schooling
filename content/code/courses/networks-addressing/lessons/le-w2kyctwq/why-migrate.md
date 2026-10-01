---
title: Why migration matters
version: 1
---

IPv4 has 4,294,967,296 addresses, as lesson 8 counted, and the world has more devices than that.
The pool did not run dry gradually, either. **IANA, which hands address blocks to the five
regional registries, gave out its last ones on 3 February 2011.** The registries then ran out one
after another over the following years, APNIC, for Asia and the Pacific, first, in April 2011. Since
then a new network gets IPv4 addresses by buying them from somebody who has spare ones, or does not
get them.

What kept IPv4 working is NAT, the subject of lesson 11: a whole office or a whole home behind one
public address. When even that was not enough, providers put their customers behind a second NAT of
their own, carrier-grade NAT, with the `100.64.0.0/10` addresses lesson 8 met. It works, and what it
costs is easiest to see from the far end. Both requests below went from pc1 to the same web server,
one over each protocol. Meanwhile `tcpdump` on the web server printed the first packet of each
connection and its reply, and its output came out after the two `curl` commands had finished:

```
ana@pc1:~$ curl -s -4 -o /dev/null http://web/
ana@pc1:~$ curl -s -6 -o /dev/null http://web/
root@web:~# timeout 8 tcpdump -n -c 4 -i eth0 "tcp[tcpflags] & tcp-syn != 0 or (ip6 and ip6[53] & 2 != 0)"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:48:41.138662 IP 203.0.113.2.41276 > 192.0.2.80.80: Flags [S], seq 1917333732, win 64240, options [mss 1460,sackOK,TS val 3433362736 ecr 0,nop,wscale 7], length 0
07:48:41.138902 IP 192.0.2.80.80 > 203.0.113.2.41276: Flags [S.], seq 382100392, ack 1917333733, win 65160, options [mss 1460,sackOK,TS val 965993147 ecr 3433362736,nop,wscale 7], length 0
07:48:42.279564 IP6 2001:db8:20:10:25:70ff:febc:29c6.35834 > 2001:db8:99::80.80: Flags [S], seq 1586092098, win 64800, options [mss 1440,sackOK,TS val 3988341105 ecr 0,nop,wscale 7], length 0
07:48:42.279904 IP6 2001:db8:99::80.80 > 2001:db8:20:10:25:70ff:febc:29c6.35834: Flags [S.], seq 1665686423, ack 1586092099, win 64260, options [mss 1440,sackOK,TS val 3136177618 ecr 3988341105,nop,wscale 7], length 0
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

The first two lines are the IPv4 connection. The web server saw it come from **`203.0.113.2`, r1's
outside address, not from pc1**: the router rewrote the source on the way out, as it does for every
machine in the office. To this server, pc1, pc2 and srv are all the same visitor. The last two lines
are the IPv6 connection, and it came from **`2001:db8:20:10:25:70ff:febc:29c6`, pc1's own address**,
untouched. Nobody translated anything.

(One more difference is visible in the options. The IPv4 handshake offered `mss 1460` and the IPv6
one `mss 1440`: the largest piece of data each packet carries, which is 1500 bytes minus the headers,
and the IPv6 header is 40 bytes against IPv4's 20.)

**Addresses that are not translated are what IPv6 buys back.** A server's log names the machine
that connected rather than the router in front of it. Two machines can reach each other directly
when the firewalls between them allow it, which is what calls, games and file transfers between
homes want and what NAT makes difficult. A router has no table of translations to keep, run out of or
lose when it restarts. And a provider needs no second layer of NAT for its customers, a layer it has
to buy, run and log.

What IPv6 does not buy is security by accident. NAT was never designed as a firewall, but it acted
like one: nothing from outside could start a connection to a machine inside, because there was no
address to start it to. **With IPv6 every machine has a reachable address, so the firewall has to
say what may come in**, and the previous section showed that r1 in this lab says nothing at all.

Migration is slow because nothing forces it on a given day: a network that works over IPv4 keeps
working. It happens in stages. Dual stack first, as in this office, so that everything reachable over
IPv6 is reached that way and the rest still works. Then, on some networks, IPv6 only, with a
translator at the edge for the sites that still have no IPv6 address. That last stage, NAT64, was
not run in this lab. **The practical position for anybody running a network today is dual stack
done properly**: both protocols addressed, routed, filtered and tested, with neither treated as the
real one and the other as an extra.
