---
title: Static or dynamic: who writes the address down
version: 2
---

Lesson 8 gave every machine an IPv4 address, and lesson 12 gives it a mask, but neither says where
those numbers come from. There are two answers. **A static address is typed into the device itself;
a dynamic one is lent by a server that keeps the list.** The protocol that lends them is DHCP
(*Dynamic Host Configuration Protocol*), and it delivers more than an address: the mask, the default
gateway and the name servers arrive in the same reply.

The common picture is that a dynamic address keeps changing and a static one does not. Neither half
holds up. A DHCP server remembers who had which address: in this lesson pc2 gives 10.20.10.101 back,
and the next time it asks it is handed 10.20.10.101 again. And a static address changes the moment
somebody retypes it. **The difference is where the address is written down: on the machine, or in
one server's configuration.**

This is the lab the lesson runs on:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"The lab for this lesson. On the office LAN, 10.20.10.0/24, five machines are cabled to the switch sw1: pc1 on port p1 and pc2 on port p2, both clients; the printer prn on p3, MAC 02:32:ed:ce:04:12, with a reservation for .50; rogue on p5, a PC that later becomes a rogue DHCP server; and srv, 10.20.10.10, the DHCP server, on p4. Port p8 goes to the router r1, which is 10.20.10.1 on eth0 and 10.20.20.1 on eth2, and relays DHCP. Behind eth2 is the second floor, 10.20.20.0/24, with the client pc4.\"><rect x=\"10\" y=\"10\" width=\"404\" height=\"272\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"604\" y=\"10\" width=\"106\" height=\"272\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><line x1=\"262\" y1=\"40\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"20\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client: asks for an address</text><text x=\"270\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><line x1=\"262\" y1=\"86\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"66\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"32\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client</text><text x=\"270\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p2</text><line x1=\"262\" y1=\"132\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"112\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">prn  02:32:ed:ce:04:12</text><text x=\"32\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">printer, reserved .50</text><text x=\"270\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p3</text><line x1=\"262\" y1=\"178\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"158\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rogue</text><text x=\"32\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a PC; later, a rogue server</text><text x=\"270\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p5</text><line x1=\"262\" y1=\"224\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"204\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv  10.20.10.10</text><text x=\"32\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">DHCP server</text><text x=\"270\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p4</text><rect x=\"322\" y=\"108\" width=\"76\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">switch</text><line x1=\"398\" y1=\"140\" x2=\"452\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"422\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p8</text><rect x=\"452\" y=\"96\" width=\"136\" height=\"88\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"462\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">router and relay</text><text x=\"462\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth0 10.20.10.1</text><text x=\"462\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth2 10.20.20.1</text><line x1=\"588\" y1=\"140\" x2=\"614\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"614\" y=\"116\" width=\"88\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"624\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client</text><text x=\"22\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">office LAN</text><text x=\"22\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><text x=\"614\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">second floor</text><text x=\"614\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.20.0/24</text></svg>", "caption": "The lab for this lesson: five machines on one switch, a router that relays DHCP, and a second floor behind it."}
```

Save it as `~/netlab/dhcp.sh` and build it with `sudo bash ~/netlab/netlab.sh up dhcp`:

```bash
# ~/netlab/dhcp.sh: an office whose PCs get their addresses from a DHCP
# server. srv serves the office LAN and, through a relay on r1, a second floor
# on its own subnet. prn is a printer with a reservation; rogue is an
# ordinary PC, the one lesson 10 reads about.
#
#   pc1 pc2 prn rogue srv --- sw1 --- r1 --- pc4
#   10.20.10.0/24 (srv .10, r1 .1)       10.20.20.0/24 (r1 .1)
local n
for n in pc1 pc2 prn rogue srv sw1 pc4; do node $n; done
node r1 router
link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link prn eth0 sw1 p3; link rogue eth0 sw1 p5
link srv eth0 sw1 p4; link r1 eth0 sw1 p8
switch sw1 "p1 p2 p3 p4 p5 p8"
link r1 eth2 pc4 eth0
addr srv eth0 10.20.10.10/24; addr r1 eth0 10.20.10.1/24; addr r1 eth2 10.20.20.1/24
gw srv 10.20.10.1
cat > "$LAB/srv/dhcpd.conf" <<CONF
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
  hardware ethernet $(mac prn eth0);
  fixed-address 10.20.10.50;
}
CONF
dhcpd_on srv eth0 "$LAB/srv/dhcpd.conf"
```

The block between `<<CONF` and `CONF` is the DHCP server's configuration, written to a file on srv
and read in the section on scopes; `dhcpd_on` starts the server with it. No PC is given an IPv4
address: each asks for one in this lesson.

The PCs start with nothing. This is pc1 before it has asked anybody:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if123       UP             fe80::25:70ff:febc:29c6/64 
ana@pc1:~$ ip route
```

Its only address is `fe80::25:70ff:febc:29c6/64`, the IPv6 link-local address every interface gives
itself (lesson 9). There is no IPv4 address, and `ip route` printed nothing at all: no route to its
own subnet, no default gateway. **Without an address, pc1 can reach nothing over IPv4, not even the
PC beside it**, and that is the state every laptop is in at the moment it is plugged in.

What gets a static address is anything other machines must find by its number, and anything that
has to keep working when the DHCP server does not. In this lab that is r1 at 10.20.10.1, the gateway
every PC is told about, and srv at 10.20.10.10, the DHCP server itself — a server cannot lease an
address to itself before it is running. Name servers belong in the same group. Each of those
addresses is written in `dhcp.sh`, below, by an `addr` line.

Everything that comes and goes is dynamic: laptops, phones, desktops, a visitor's tablet. Typing
their addresses by hand costs more than the minutes it takes. Somebody mistypes and two machines
share an address; a mask is wrong and half the subnet is unreachable, which lesson 12 shows
happening; and the spreadsheet that records who has what is out of date by Friday. With DHCP the
record is the server's own file, and moving two hundred PCs to a new name server is one line in it.

Printers are the classic third case: a device everybody reaches by its address, which nobody wants
to configure by hand. **A reservation is the middle road: the device asks by DHCP like any other,
and the server always gives it the same address.** The section on reservations does that for the
printer, prn.

One rule keeps the two worlds apart. **Static addresses must sit outside the range the server lends**,
or sooner or later the server offers somebody the router's address. This lab keeps 10.20.10.1 to
10.20.10.99 for static use and lends .100 to .199, and the section on scopes reads the file that
says so.
