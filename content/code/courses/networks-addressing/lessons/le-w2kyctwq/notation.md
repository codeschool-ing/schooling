---
title: Eight groups of sixteen bits
version: 2
---

An IPv6 address is 128 bits long, four times the length of an IPv4 address. Written out in decimal
with dots, it would be sixteen numbers, so it is written in **hexadecimal instead: eight groups of
four hex digits, separated by colons**. Each hex digit is four bits, so each group is 16 bits, and
eight groups make 128.

This lesson's office speaks IPv4 and IPv6 at once. Save it as `~/netlab/dualstack.sh`:

```bash
# ~/netlab/dualstack.sh: an office LAN that speaks IPv4 and IPv6 at once. r1
# announces the office's IPv6 prefix with radvd and the PCs build their own
# addresses from it; srv is given its IPv6 address by hand.
#
#   pc1 pc2 srv --- sw1 --- r1 === isp --- web
#   10.20.10.0/24           203.0.113.0/30        192.0.2.0/24
#   2001:db8:20:10::/64     2001:db8:ffff::/64    2001:db8:99::/64
local n
for n in pc1 pc2 srv sw1 web; do node $n; done
node r1 router; node isp router
link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link srv eth0 sw1 p4; link r1 eth0 sw1 p8
switch sw1 "p1 p2 p4 p8"
addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr srv eth0 10.20.10.10/24
addr r1 eth0 10.20.10.1/24; addr r1 eth0 2001:db8:20:10::1/64
addr srv eth0 2001:db8:20:10::10/64
ip netns exec srv sysctl -qw net.ipv6.conf.eth0.autoconf=0   # its one address is the one it was given
for n in pc1 pc2 srv; do gw $n 10.20.10.1; done
ip -n srv -6 route add default via 2001:db8:20:10::1
link r1 eth1 isp eth0
addr r1 eth1 203.0.113.2/30; addr isp eth0 203.0.113.1/30; gw r1 203.0.113.1
addr r1 eth1 2001:db8:ffff::2/64; addr isp eth0 2001:db8:ffff::1/64
ip -n r1 -6 route add default via 2001:db8:ffff::1
ip -n isp -6 route add 2001:db8:20::/48 via 2001:db8:ffff::2
link isp eth1 web eth0
addr isp eth1 192.0.2.1/24; addr web eth0 192.0.2.80/24; gw web 192.0.2.1
addr isp eth1 2001:db8:99::1/64; addr web eth0 2001:db8:99::80/64
ip -n web -6 route add default via 2001:db8:99::1
ip netns exec r1 nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
cat > "$LAB/r1/radvd.conf" <<'RA'
interface eth0 {
  AdvSendAdvert on;
  MinRtrAdvInterval 30;
  MaxRtrAdvInterval 100;
  prefix 2001:db8:20:10::/64 {
    AdvOnLink on;
    AdvAutonomous on;
  };
};
RA
daemon r1 radvd radvd -n -C "$LAB/r1/radvd.conf" -p "$LAB/r1/radvd.pidfile" -m stderr
web web '::'
for n in pc1 pc2 srv r1; do
  host $n 10.20.10.10 srv; host $n 2001:db8:20:10::10 srv
  host $n 192.0.2.80 web; host $n 2001:db8:99::80 web
done
```

r1 runs radvd, the program the section on SLAAC reads, from the configuration written into its
directory, and the PCs build their IPv6 addresses from what it announces. Build it with
`sudo bash ~/netlab/netlab.sh up dualstack` and give it ten seconds, so the first announcement has
reached every PC.

That form is long, and two rules shorten it. The server of this lesson's office was given its
address by hand, and the short form is what Linux prints:

```
ana@srv:~$ ip -6 addr show eth0
32: eth0@if31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 2001:db8:20:10::10/64 scope global 
       valid_lft forever preferred_lft forever
    inet6 fe80::9e:43ff:fe3e:caae/64 scope link 
       valid_lft forever preferred_lft forever
```

`2001:db8:20:10::10` is srv's address and `/64` its prefix. (The `fe80::` line is a second address
every interface has, and the next section is about it.) `sipcalc` expands the short form:

```
ana@pc1:~$ sipcalc 2001:db8:20:10::10
-[ipv6 : 2001:db8:20:10::10] - 0

[IPV6 INFO]
Expanded Address	- 2001:0db8:0020:0010:0000:0000:0000:0010
Compressed address	- 2001:db8:20:10::10
Subnet prefix (masked)	- 2001:db8:20:10:0:0:0:10/128
Address ID (masked)	- 0:0:0:0:0:0:0:0/128
Prefix address		- ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
Prefix length		- 128
Address type		- Aggregatable Global Unicast Addresses
Network range		- 2001:0db8:0020:0010:0000:0000:0000:0010 -
			  2001:0db8:0020:0010:0000:0000:0000:0010

-
ana@pc1:~$ ping -c 1 2001:0db8:0020:0010:0000:0000:0000:0010
PING 2001:0db8:0020:0010:0000:0000:0000:0010 (2001:db8:20:10::10) 56 data bytes
64 bytes from 2001:db8:20:10::10: icmp_seq=1 ttl=64 time=8.02 ms

--- 2001:0db8:0020:0010:0000:0000:0000:0010 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 8.019/8.019/8.019/0.000 ms
```

The `Expanded Address` line is the address with nothing left out:
`2001:0db8:0020:0010:0000:0000:0000:0010`. Two rules turn it into the short form.

**Rule one: leading zeros in a group may be dropped.** `0db8` becomes `db8`, `0020` becomes `20`, and
`0000` becomes `0`. Only leading zeros: the trailing zero in `0010` is part of the number, and
dropping it would make it `1`, a different value.

**Rule two: one run of consecutive all-zero groups may be replaced by `::`, once per address.** The
three groups of `0000` in the middle become `::`. Once, because two of them would be ambiguous: in
`2001::5::1`, nobody can tell how many zero groups each `::` hides. To expand an address, count the
groups that are written and let `::` stand for the rest. In `2001:db8:20:10::10` five groups are
written, so `::` stands for 8 − 5 = 3 groups of zeros.

The ping above shows the two forms are the same address. It was given the long form, it printed the
short one in brackets, and srv answered: **the machine compares 128 bits, not text**. People and
programs do compare text, though. A log search for `2001:0db8:0020:0010` finds nothing in a log that
wrote `2001:db8:20:10::10`. RFC 5952 settled one way to write each address: lowercase, leading zeros
dropped, and `::` on the longest run of zeros. Linux follows it, so search for that form.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"srv's IPv6 address written out in full as eight groups of four hexadecimal digits, each group 16 bits: 2001, 0db8, 0020, 0010, 0000, 0000, 0000, 0010. The first four groups are the prefix, 64 bits, the network 2001:db8:20:10::/64. The last four are the interface identifier, 64 bits, here ::10, written by hand. Groups five to seven, all zeros, are highlighted. Written short, the address is 2001:db8:20:10::10: leading zeros are dropped in each group, and the double colon stands for the three groups of zeros.\"><rect x=\"18\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"59\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">2001</text><text x=\"59\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"102\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"104\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"145\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0db8</text><text x=\"145\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"188\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"190\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"231\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0020</text><text x=\"231\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"274\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"276\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"317\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0010</text><text x=\"317\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"362\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"403\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0000</text><text x=\"403\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"446\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"448\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"489\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0000</text><text x=\"489\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"532\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"534\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"575\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0000</text><text x=\"575\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"618\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"620\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0010</text><text x=\"661\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><path d=\"M18 104 L358 104\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"188\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prefix, 64 bits: the network</text><text x=\"188\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2001:db8:20:10::/64</text><path d=\"M362 104 L702 104\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"532\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">interface identifier, 64 bits</text><text x=\"532\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">here ::10, written by hand</text><text x=\"18\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">written short</text><text x=\"140\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">2001:db8:20:10::10</text><text x=\"18\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leading zeros dropped in each group; \"::\" stands for the three highlighted groups of zeros</text></svg>", "caption": "One address, 128 bits, in the form sipcalc expands it to. The /64 prefix names the network and the other half names the interface on it."}
```

The prefix is written the IPv4 way, with a slash. **`/64` means the first 64 bits name the network,
`2001:db8:20:10::/64`, and the last 64 bits name the interface on it.** In IPv4 the host part was
whatever the mask left; in IPv6 a LAN is a `/64` almost always, so the host part is 64 bits: room for
as many interfaces as the whole IPv4 internet squared. srv's interface identifier, `::10`, was chosen by hand to be
easy to remember. The PCs choose their own, which is the subject of the next two sections.

Two more readings of the output. `2001:db8::/32` is the block RFC 3849 reserves for documentation,
the IPv6 counterpart of the `203.0.113.0/24` lesson 8 showed, so the lab can print it safely.
`Aggregatable Global Unicast Addresses` is sipcalc's name for the global addresses, the ones that
are routed on the internet; without a prefix, sipcalc treated the address as a `/128`, a single
interface, the way ipcalc assumed a `/24`.
