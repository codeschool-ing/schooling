---
title: The VPN, a private link through somebody else's network
version: 2
---

The head office wants to reach the branch: pc1 to pc2, private address to private address. It
cannot, and the provider says why:

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
From 203.0.113.1 icmp_seq=1 Destination Net Unreachable
From 203.0.113.1 icmp_seq=2 Destination Net Unreachable

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1003ms

```

`From 203.0.113.1 ... Destination Net Unreachable` is the provider's router answering. The WAN
section already read its table: two links and nothing else, **no route to `10.30.10.0/24`**, because
no provider routes private addresses. Renting a line between the two offices would fix it, at the
price of a leased line. The cheaper fix uses the internet connection each office already has.

A **VPN** (*virtual private network*) is **a private link carried inside packets that the public
network can deliver**. The head office's router takes a packet addressed to the branch, wraps it in
a new packet addressed from its own public address to the branch router's public address, and sends
that. The provider routes the outer packet, which it knows how to do. The branch router unwraps it
and delivers the original packet on its LAN. In most VPNs the inner packet is also **encrypted**, so
that the network carrying it can read neither its contents nor its private addresses — the last
section of this lesson looks at what remains visible.

## Building one

The lab uses **WireGuard**, a VPN built into the Linux kernel. Each router gets a `wg0` interface,
a private key that never leaves it, and a list of one peer: the other router's public key, where to
find it, and which addresses may come from it. Typed at the two routers' prompts:

```
root@rhq:~# ip link add wg0 type wireguard
root@rhq:~# wg set wg0 listen-port 51820 private-key /run/lab/rhq/wg.key peer +JFzEjDfzTBIMYnsaG9+qGoe12VEnNzYlLvJ6Ftnojo= endpoint 198.51.100.2:51820 allowed-ips 10.30.10.0/24,10.255.255.2/32
root@rhq:~# ip addr add 10.255.255.1/30 dev wg0 && ip link set wg0 up && ip route add 10.30.10.0/24 dev wg0
root@rbr:~# ip link add wg0 type wireguard
root@rbr:~# wg set wg0 listen-port 51820 private-key /run/lab/rbr/wg.key peer PLKSQ+aPlVn+/rt1DVIP+p5D0RVtQLLwMulg682GHiA= endpoint 203.0.113.2:51820 allowed-ips 10.20.10.0/24,10.255.255.1/32
root@rbr:~# ip addr add 10.255.255.2/30 dev wg0 && ip link set wg0 up && ip route add 10.20.10.0/24 dev wg0
```

Read the head office's three lines. `wg0` is created; then `wg set` gives it a **listening port**,
51820, a private key from a file, and one **peer**: the branch's public key (`+JFz…`), its
**endpoint** `198.51.100.2:51820` — the branch router's public address — and its **allowed IPs**,
`10.30.10.0/24,10.255.255.2/32`, the addresses that may arrive through this tunnel. The last line
gives `wg0` an address, brings it up, and adds the route that sends the branch's LAN into the tunnel.
The branch's lines are the mirror image.

**About those keys.** The two private keys are written into `sites.sh`, so that `wg show`
prints the same thing every time the network is built. That means anybody can read them, and they protect
nothing. A real tunnel uses keys made on the machine with `wg genkey`, and a private key that has
been printed, pasted or committed is a key to replace.

## Using it

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
64 bytes from 10.30.10.22: icmp_seq=1 ttl=62 time=27.7 ms
64 bytes from 10.30.10.22: icmp_seq=2 ttl=62 time=3.83 ms

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 3.826/15.747/27.668/11.921 ms
ana@pc1:~$ traceroute -n 10.30.10.22
traceroute to 10.30.10.22 (10.30.10.22), 30 hops max, 60 byte packets
 1  10.20.10.1  0.854 ms  0.232 ms  0.206 ms
 2  10.255.255.2  6.105 ms  5.594 ms  5.035 ms
 3  10.30.10.22  5.510 ms  4.284 ms  3.903 ms
root@rhq:~# wg show
interface: wg0
  public key: PLKSQ+aPlVn+/rt1DVIP+p5D0RVtQLLwMulg682GHiA=
  private key: (hidden)
  listening port: 51820

peer: +JFzEjDfzTBIMYnsaG9+qGoe12VEnNzYlLvJ6Ftnojo=
  endpoint: 198.51.100.2:51820
  allowed ips: 10.30.10.0/24, 10.255.255.2/32
  latest handshake: 2 seconds ago
  transfer: 1.46 KiB received, 1.61 KiB sent
```

The ping that failed now works. Three details say it went through the tunnel:

- **`ttl=62`.** pc2 sent its reply with a TTL of 64, and two routers each took one: `rbr` and `rhq`.
  The provider's router forwarded the *outer* packet, whose TTL is a different number, and never
  touched the inner one.
- **The traceroute has three hops, and none of them is the provider.** Hop 2 is `10.255.255.2`, the
  branch router's address inside the tunnel. From inside the VPN, the two offices are one router
  apart.
- **`wg show`** reports a `latest handshake: 2 seconds ago` with the peer, and traffic both ways:
  `1.46 KiB received, 1.61 KiB sent`. `private key: (hidden)` is WireGuard declining to print it, even
  to root.

This is a **site-to-site** VPN: two routers joining two LANs, and the PCs behind them need no
configuration at all. The other common kind is **remote access**: one laptop running a VPN client
that joins it to the office network from a hotel or a home. The mechanism is the same — a packet
inside a packet — with one end being a person's computer instead of a router. Neither changes the
underlying point: **a VPN does not make the internet private; it makes a private link out of it.**
