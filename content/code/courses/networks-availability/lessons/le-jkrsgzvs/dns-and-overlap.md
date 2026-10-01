---
title: Names that go astray and numbers that collide
version: 1
---

Two problems belong to remote access alone, because the laptop sits inside a network the company does
not run.

## DNS, which the routes do not decide

Routes decide where packets go; they say nothing about names. **The company's DNS server answers internal
names, and a laptop at home asks whatever resolver the home router handed it.** That resolver has never
heard of the company's internal names, so they fail. An internal name that also exists in public DNS
quietly resolves to the public address instead.

The fix is split DNS: queries for the company's own domains go to its resolver, through the tunnel, and
everything else to the local one. On Linux, `systemd-resolved` does it per interface, and `wg-quick`
takes a `DNS =` line that hands a resolver to the system when the tunnel comes up. Ana's file had no
such line, and nothing about DNS was captured in this lesson.

A full tunnel does not settle it either, and the reason is in the rules captured in the section on
split and full tunnels. If the laptop's resolver is the home router, `192.168.1.1`, that address is on
the home LAN, which `suppress_prefixlength 0` deliberately keeps reachable outside the tunnel. **Every
query then goes to the home router in clear, while everything else is encrypted**, and the home ISP
sees each name she looks up. It is called a DNS leak, and a full-tunnel configuration names a resolver
on the company's side for exactly that reason.

## Two networks with the same numbers

The home LAN here is `192.168.1.0/24`, a very common default on home routers. Suppose the head office
had kept the same default, as many small offices do. To stage it, a third range, `192.168.1.0/24`, was
added to Ana's `AllowedIPs` to stand for that office network, with the tunnel down first, as root and
not shown:

```
ana@remote:~$ ip route | grep 192.168.1.0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.50 
ana@remote:~$ sudo wg-quick up wg0
[#] ip link add wg0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wg0
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/           │
│                                                      │
└──────────────────────────────────────────────────────┘
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.20.0.3/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 192.168.10.0/24 dev wg0
[#] ip -4 route add 192.168.1.0/24 dev wg0
RTNETLINK answers: File exists
[#] ip link delete dev wg0
```

The laptop already has a route for `192.168.1.0/24`, on `eth0`: its own home LAN. `wg-quick` tries to
add the same prefix through `wg0`, and the kernel refuses, `RTNETLINK answers: File exists`. **`wg-quick`
treats any failed step as fatal and deletes `wg0`**, so the whole tunnel is gone, not just the one range.

Here the failure is loud, which is the good case. A client that installs its routes differently can let
one of the two win without a word, and then either the home printer or the office server stops
answering. Even when the prefixes differ, an address such as `192.168.1.10` can exist on both sides, and
the laptop can reach only one of them.

| fix | what it costs |
|---|---|
| number company networks away from home-router defaults | a renumbering, cheap only before the network grows |
| translate the office range, on the concentrator, into one nothing uses (NAT, lesson 11 of `networks-addressing`) | internal names have to point at the translated addresses |
| route only the few hosts the user needs, as `/32` | fine for three servers, not for a network |
| give access per application instead of per network | a different product, in the section on choosing |

The same collision happens between two sites when two companies merge and both used `192.168.1.0/24`.
And lesson 4's rule that a range belongs to one peer at a time means one concentrator could not even
list both.
