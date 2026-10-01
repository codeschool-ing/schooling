---
title: "Leases: a loan with a date on it"
version: 1
---

**An address from DHCP is lent, never given.** Every lease has a start and an end, and the client
has to come back before the end to keep it. Both sides write the loan down, and the server's record
is a plain text file:

```
root@srv:~# cat /var/lib/dhcp/dhcpd.leases
# The format of this file is documented in the dhcpd.leases(5) manual page.
# This lease file was written by isc-dhcp-4.4.3-P1

# authoring-byte-order entry is generated, DO NOT DELETE
authoring-byte-order little-endian;

server-duid "\000\001\000\0012N[z\002\236C>\312\256";

lease 10.20.10.100 {
  starts 2 2026/09/29 11:20:32;
  ends 2 2026/09/29 11:30:32;
  cltt 2 2026/09/29 11:20:32;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 02:25:70:bc:29:c6;
  client-hostname "pc1";
}
lease 10.20.10.101 {
  starts 2 2026/09/29 11:20:40;
  ends 2 2026/09/29 11:30:40;
  cltt 2 2026/09/29 11:20:40;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 02:fd:f2:d2:63:ba;
  client-hostname "pc2";
}
```

One block per address lent. pc1's lease of 10.20.10.100 `starts 2 2026/09/29 11:20:32` and `ends 2
2026/09/29 11:30:32`: ten minutes, the `default-lease-time 600` of the configuration. The `2` is
the day of the week, Tuesday. **The times in this file are in UTC**, while the `tcpdump` in the
section on DORA printed the lab's local time, `08:20` in São Paulo: the same moment, three hours
apart on the page, which is worth knowing before you match a lease against a log. `binding state
active` is a lease in use, `next binding state free` is what it becomes at the end, and
`client-hostname "pc1"` is the name the client sent, which is the quickest way to find out whose a
lease is.

pc1 keeps its own copy:

```
ana@pc1:~$ cat /var/lib/dhcp/dhclient.leases
lease {
  interface "eth0";
  fixed-address 10.20.10.100;
  option subnet-mask 255.255.255.0;
  option routers 10.20.10.1;
  option dhcp-lease-time 600;
  option dhcp-message-type 5;
  option domain-name-servers 10.20.10.10;
  option dhcp-server-identifier 10.20.10.10;
  renew 2 2026/09/29 11:25:24;
  rebind 2 2026/09/29 11:29:17;
  expire 2 2026/09/29 11:30:32;
}
```

The `option` lines are what the ACK carried; `dhcp-message-type 5` is the number of the ACK itself.
The last three lines are the client's timetable, measured from the lease's start at 11:20:32:

| | at | after the start |
|---|---|---|
| renew | 11:25:24 | 292 s, a little under half of 600 |
| rebind | 11:29:17 | 525 s, seven eighths of 600 |
| expire | 11:30:32 | 600 s |

**At renew, the client asks the server that gave it the address, directly and by unicast**, and an
ACK starts the clock again. That moment is the `renewal in 291 seconds` that `dhclient` printed when
it bound the address. If that server has not answered by **rebind**, the client broadcasts its
request to any server that will listen. If nobody has answered by **expire**, the client stops using
the address. Half and seven eighths are the protocol's defaults, from RFC 2131. This client brings the first one forward by a random amount, which is why every `renewal in` in this lesson is a
different number below 300 — 291 for pc1, 283 for the printer.

A client that is finished with an address can give it back early:

```
ana@pc2:~$ sudo dhclient -r -v eth0 2>&1 | grep -E "DHCP"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPRELEASE of 10.20.10.101 on eth0 to 10.20.10.10 port 67 (xid=0x64c27dc0)
ana@pc2:~$ ip -br addr show eth0
eth0@if125       UP             fe80::fd:f2ff:fed2:63ba/64 
```

`dhclient -r` sends a **DHCPRELEASE**, by unicast to the server, `to 10.20.10.10`, and drops the
address: pc2 is back to its IPv6 link-local address alone. A released address returns to the pool
at once. A laptop that is simply unplugged sends nothing, and its address stays lent until the lease
expires, which is why the section on scopes sized a pool by the lease time.

So the length of a lease is a trade. A short lease returns abandoned addresses quickly, and a
change in the scope, such as a new name server, reaches every client within one lease. It costs a
renewal every few minutes from every client, and a client depends more closely on the server being
up: with srv stopped, pc1 would lose its address within ten minutes. A long lease rides out a server
that is down for an afternoon. Ten minutes suits a lab where you want to see the renewal happen; an
office lends for hours or days.
