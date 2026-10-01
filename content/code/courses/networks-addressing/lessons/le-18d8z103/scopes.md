---
title: The scope: what the server may lend
version: 1
---

The server's side of DHCP is one file. **A scope is the set of addresses a server may lend on one
subnet, together with the options that go with them.** The word is Microsoft's; ISC's server, the
one in this lab, writes a scope as a `subnet` block with a `range` inside. This is srv's whole
configuration:

```
root@srv:~# cat /run/lab/srv/dhcpd.conf
# the office's DHCP server
authoritative;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers 10.20.10.10;

subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.100 10.20.10.199;
  option routers 10.20.10.1;
}

subnet 10.20.20.0 netmask 255.255.255.0 {
  range 10.20.20.100 10.20.20.199;
  option routers 10.20.20.1;
}

host prn {
  hardware ethernet 02:32:ed:ce:04:12;
  fixed-address 10.20.10.50;
}
```

Read it from the top. `authoritative` declares this server the official one for its subnets, so
it answers with a refusal, a DHCPNAK, when a client asks to keep an address that does not belong here. That is a laptop arriving from another network with its old lease still
in mind. `default-lease-time
600` lends addresses for 600 seconds, ten minutes, when the client does not ask for a length, and
`max-lease-time 7200` caps what a client may ask for at two hours. `option domain-name-servers` sits
outside every block, so every scope sends it, and that is how pc1 got its name server.

Then the scopes themselves. In the first, `range 10.20.10.100 10.20.10.199` is the **pool**, and
`option routers 10.20.10.1` is the default gateway every client of that pool is told about. **How
many addresses is that? Count both ends: 199 − 100 + 1 = 100.** The subnet has 254 usable
addresses, so the pool leaves .1 to .99 and .200 to .254 for static use. That is where r1 (.1),
srv (.10) and the printer's reservation (.50) live.

The second scope, `subnet 10.20.20.0`, is the floor behind r1, a network srv is not even on. It
only means something once a relay carries that floor's requests across the router, which is the
relay section's subject.

The pool lends addresses from the bottom here: pc1 took .100, and pc2, asking next, got the one
after it. The second command only prints the result, because `dhclient` without `-v` says nothing:

```
ana@pc2:~$ sudo dhclient eth0 && ip -br addr show eth0
eth0@if125       UP             10.20.10.101/24 fe80::fd:f2ff:fed2:63ba/64 
```

Sizing a pool is arithmetic plus a margin. Count the devices that will hold an address at the same
time, phones included, and remember that **an address stays lent until its lease runs out**, even
after its owner has walked out of the door. A meeting room where forty visitors come and go every
hour, with a lease of one day, needs far more than forty addresses by the end of the week; with a
lease of one hour it needs about forty. Short leases on a busy guest network and long ones on a
floor where the same desks are used every day is the usual trade.

**Running out is quiet.** A client that receives no offer keeps sending DISCOVERs. Windows, and many
other systems, then give themselves an address from 169.254.0.0/16, the IPv4 link-local range, which
reaches nothing beyond the cable. That address on a user's screen is the symptom to recognise: no
DHCP server answered. The lab never runs out, so there is no capture of it here; the relay section
shows a client that gets no answer at all.
