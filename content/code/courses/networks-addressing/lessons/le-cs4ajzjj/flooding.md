---
title: An unknown destination goes everywhere
version: 1
---

A switch receives a frame for an address that is not in its table. It cannot drop the frame,
because the destination may well exist and simply not have spoken yet, and it cannot pick a port,
because it does not know one. **So it sends the frame out of every port except the one it arrived
on.** That is called **flooding**, and it is the switch behaving, for one frame, exactly like the
hub of lesson 1.

The capture below shows both cases side by side. The table was emptied, then pc1 pinged the server
once so that both were learnt. pc3 then started tcpdump, filtered to ICMP, and left it running for
eight seconds while pc1 did two things: pinged the server twice more, a destination the switch
knows; and pinged 10.20.10.99, after being told by hand (`ip neigh add`) that this address lives at
`02:00:00:00:00:99`, a MAC address no card in the lab has. tcpdump printed when it stopped, so its
output follows the pings:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 12.026/12.026/12.026/0.000 ms
ana@pc1:~$ ping -c 2 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.784/5.258/9.733/4.474 ms
root@pc1:~# ip neigh add 10.20.10.99 lladdr 02:00:00:00:00:99 dev eth0
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.99
PING 10.20.10.99 (10.20.10.99) 56(84) bytes of data.

--- 10.20.10.99 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1066ms

root@pc3:~# timeout 8 tcpdump -n -e -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:58:22.560076 02:25:70:bc:29:c6 > 02:00:00:00:00:99, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.99: ICMP echo request, id 79, seq 1, length 64
08:58:23.625757 02:25:70:bc:29:c6 > 02:00:00:00:00:99, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.99: ICMP echo request, id 79, seq 2, length 64

2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**pc3 saw two frames, and both are for `02:00:00:00:00:99`.** The two pings to the server, whose
port the switch knew, never reached pc3's cable at all, exactly as in lesson 1. The two pings to
the made-up address did, because the switch had no entry for it and flooded each frame out of every
port: to pc3, to pc2, to the server and to the router. Nobody answered, so the ping reports `100%
packet loss`.

Now the table:

```
root@sw1:~# bridge fdb show br br0 dynamic | grep -c .
2
root@sw1:~# bridge fdb show br br0 | grep 02:00:00:00:00:99
```

**Still two entries, and the made-up address is not one of them.** The switch saw two frames *to*
`02:00:00:00:00:99` and learnt nothing from them, because it learns from sources and no frame has
ever come *from* that address. So it will flood every frame to it for as long as somebody keeps
sending them.

## When flooding is normal, and when it is a symptom

Most flooding is brief and harmless. The first frame to a machine that has not spoken is flooded,
the machine answers, its answer teaches the switch its port, and every later frame goes to one
port. On a network where everybody talks regularly, an unknown destination lasts one frame.

Two things make it last longer, and both are worth recognising:

- **A destination that stays silent.** A device that receives traffic and sends nothing for longer
  than the ageing time drops out of the table, and whatever is sent to it is flooded to every port
  until it speaks again.
- **A full table.** A switch that has no room for a new address floods every frame to it. That is
  the threat the port security section defends against.

**Broadcasts are flooded by design**, not by ignorance: a frame to `ff:ff:ff:ff:ff:ff` is meant for
everybody, and the switch sends it everywhere because that is what it says. How far "everywhere"
reaches is the broadcast domain, two sections on.
