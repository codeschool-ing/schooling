---
title: "Reservations: the same address, still by DHCP"
version: 1
---

The printer, prn, needs an address people can type into a print dialog, and the address must not
move. A static address typed into the printer's own menu would do it, and then the address would
live on the printer, where nobody looks. **A reservation keeps the address in the server's file and
ties it to the printer's hardware address.** It is the last block of srv's configuration, printed
in the section on scopes: `host prn`, with `hardware ethernet 02:32:ed:ce:04:12` and `fixed-address
10.20.10.50`.

The MAC address in the file has to be the printer's own, and this is where it comes from:

```
ana@prn:~$ ip link show eth0 | grep ether
    link/ether 02:32:ed:ce:04:12 brd ff:ff:ff:ff:ff:ff link-netns sw1
```

When the printer asks, the same four messages come back, with the reserved address in them:

```
ana@prn:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCP|bound"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0xa06b9207)
DHCPOFFER of 10.20.10.50 from 10.20.10.10
DHCPREQUEST for 10.20.10.50 on eth0 to 255.255.255.255 port 67 (xid=0x7926ba0)
DHCPACK of 10.20.10.50 from 10.20.10.10 (xid=0xa06b9207)
bound to 10.20.10.50 -- renewal in 283 seconds.
ana@prn:~$ ip -br addr show eth0
eth0@if127       UP             10.20.10.50/24 fe80::32:edff:fece:412/64 
```

Nothing in the exchange says it was a reservation. From the printer's side it is the same DORA as
pc1's; the difference is on the server, which looked the MAC address up before choosing what to
offer. **10.20.10.50 sits outside the pool, .100 to .199, on purpose**: kept out of the pool, it can
never be lent to a PC that happens to ask before the printer does.

Reservations suit anything other machines reach by address but nobody wants to configure by hand.
A printer, a network storage box, an access point or a camera that a management system polls, a
small office's file server. A firewall rule that names a device by address is another reason: the
rule only means something if the address stays put.

Two costs come with it.

- **The reservation follows the network card, not the device.** Replace the printer, or only its
  card, and the new MAC address gets an ordinary pool address until somebody edits the file. The
  print dialogs still point at .50, where nothing answers.
- Phones and laptops now present a different, random MAC address on each Wi-Fi network so that they
  cannot be followed from one network to the next. A reservation by MAC address does not hold for a
  device that changes it.

And one thing a reservation does not change: the printer still depends on the server. **If srv is
down, the printer keeps 10.20.10.50 until its lease runs out, and then has nothing.** A device that
must work with the DHCP server gone, such as the router or the DHCP server itself, keeps a static
address. How long "until its lease runs out" is, and what the client does before then, is the next
section.
