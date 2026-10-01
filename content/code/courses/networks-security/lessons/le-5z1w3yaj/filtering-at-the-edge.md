---
title: Refusing sources that cannot be true
version: 1
---

Two checks, placed in a `prerouting` chain so they run before routing and before any rule in `forward`
can be fooled:

```
root@fw:~# cat antispoof.nft
table ip filter {
  chain prerouting {
    type filter hook prerouting priority filter; policy accept;
    iifname "eth0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter drop comment "private sources never arrive from the internet"
    fib saddr . iif oif missing counter drop comment "the source must be reachable back through the interface it came in on"
  }
}
root@fw:~# nft -f antispoof.nft
```

The first is a list: **private ranges never arrive from the internet**, because nobody on the internet
can be reached at them. The same list, called *bogons*, usually also holds the documentation ranges,
the loopback range and addresses not yet allocated to anybody; the lab uses documentation ranges for
its own internet, so they cannot be in its list.

The second is general and needs no list. `fib saddr . iif oif missing` asks the routing table: **to
reach this packet's source, which interface would I use?** If no route leads back out through the
interface the packet came in on, the source is not where it claims to be, and the packet is dropped.
This is **reverse path filtering**.

The same forged request, and then an honest one:

```
ana@remote:~$ curl -s -m2 --interface 192.168.20.99 https://www.example.com/; echo "exit $?"
exit 28
ana@remote:~$ curl -s -m2 https://www.example.com/
orders service: ok
root@fw:~# nft list chain ip filter prerouting | grep counter
		iifname "eth0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter packets 2 bytes 120 drop comment "private sources never arrive from the internet"
		fib saddr . iif oif missing counter packets 0 bytes 0 drop comment "the source must be reachable back through the interface it came in on"
```

The forged `SYN` and its retransmission, 2 packets, were dropped by the first rule before anything
behind `fw` saw them. The honest request, from `remote`'s own address, was served as usual.

## The kernel's own switch

Linux has reverse path filtering built in, per interface, as a `sysctl`:

```
root@fw:~# sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.eth0.rp_filter
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.eth0.rp_filter = 0
```

`0` is off, which is what `fw` has. `1` is **strict**, the same check as the `fib` rule: the reply must
leave by the interface the packet arrived on. `2` is **loose**: any route back will do, which only
catches sources with no route at all. Strict is correct for a firewall like this one, where each
network lives behind exactly one interface. It is wrong where traffic legitimately comes in by one
path and leaves by another, as with two internet providers, and a strict filter there drops real
customers. The `nft` rule has the advantage of being written down, counted and commented where the
rest of the policy is.
