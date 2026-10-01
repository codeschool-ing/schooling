---
title: "Overlaps: two subnets claiming one address"
version: 1
---

Two subnets **overlap** when some address belongs to both. With one mask for everything it is hard
to do by accident, because equal pieces either coincide or do not touch. With VLSM, one mistyped
digit in a mask does it, and nothing complains.

Two blocks of this kind cannot overlap halfway. A CIDR block starts at a multiple of its own size,
so **two blocks either share nothing, or one of them contains the other entirely**. That makes an
overlap easy to describe and easy to check for: a longer prefix sitting inside a shorter one on a
different cable.

Here is one being made. Somebody adding a second address to r1's operations interface types /25
where they meant something else. The command prints nothing, which on Linux means it worked:

```
root@r1:~# ip addr add 10.20.32.130/25 dev eth3
root@r1:~# ip route
default via 10.20.32.226 dev eth0 
10.20.32.0/25 dev eth1 proto kernel scope link src 10.20.32.1 
unreachable 10.20.32.0/24 
10.20.32.128/26 dev eth2 proto kernel scope link src 10.20.32.129 
10.20.32.128/25 dev eth3 proto kernel scope link src 10.20.32.130 
10.20.32.192/27 dev eth3 proto kernel scope link src 10.20.32.193 
10.20.32.224/30 dev eth0 proto kernel scope link src 10.20.32.225 
```

r1 now has `10.20.32.128/25 dev eth3` in its table, beside the subnets of the plan. Then comes the
test that would be run on the day, and it passes:

```
root@r1:~# ip route get 10.20.32.140
10.20.32.140 dev eth2 src 10.20.32.129 uid 0 
    cache 
root@r1:~# ip route get 10.20.32.180
10.20.32.180 dev eth2 src 10.20.32.129 uid 0 
    cache 
ana@hq1:~$ ping -c 1 -W 1 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.
64 bytes from 10.20.32.140: icmp_seq=1 ttl=62 time=1.42 ms

--- 10.20.32.140 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 1.424/1.424/1.424/0.000 ms
```

Both 10.20.32.140 and 10.20.32.180 still leave by eth2, engineering's cable, and eng1 answers its
ping. The reason is the rule the previous section leaned on: **when several routes contain an
address, the one with the longest prefix wins**, and engineering's /26 is longer than the new /25.
Every address the plan's subnets cover still goes where the plan says.

ipcalc says how much the new prefix covers:

```
ana@hq1:~$ ipcalc -b 10.20.32.130/25
Address:   10.20.32.130         
Netmask:   255.255.255.128 = 25 
Wildcard:  0.0.0.127            
=>
Network:   10.20.32.128/25      
HostMin:   10.20.32.129         
HostMax:   10.20.32.254         
Broadcast: 10.20.32.255         
Hosts/Net: 126                   Class A, Private Internet

```

**10.20.32.128 to 10.20.32.255**: the whole upper half of the block. It contains engineering's /26,
which is on a different cable; operations' /27, on the same one; the link to r2; and the unused
space. And r1's new address, 10.20.32.130, sits inside engineering's range of .129 to .190.

That is exactly why an overlap is dangerous. **It does not fail when it is made; it fails later**,
and somewhere else. The capture stops here, but the table above is enough to read what it has set
up. An address in the unused space, such as 10.20.32.250, used to match only the `unreachable` /24
and be refused; it now matches the /25, which is longer, so r1 would look for it on operations'
cable. If engineering's /26 were ever removed or mistyped, the /25 would quietly take all of
engineering's traffic to the wrong cable. And .130 is r1's own address now, so an engineering PC
given .130 by a person or a pool would find its traffic ending at r1.

Some router systems refuse an address that overlaps a subnet already on another interface; Linux, as
the empty output shows, does not. **The protection is the plan**: every subnet written down, and
every new one checked against the list before it is typed. Undoing this one is the same command with
`del` in place of `add`.
