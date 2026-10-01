---
title: The lab this course runs on
version: 1
---

This course's lab is the same idea as Mininet, without Mininet. **`lab.sh`, beside the course's
`course.json`, is one shell script that builds each scenario out of three pieces of the Linux
kernel:**

- a **network namespace** for each device: its own interfaces, addresses, routing table and firewall,
  isolated from the others although all of them run on one computer;
- a **virtual Ethernet pair** for each cable: two interfaces joined back to back, one end moved into
  each device, so that what goes in at one end comes out of the other;
- a **Linux bridge** for each switch, inside the switch's own namespace, which learns MAC addresses and
  floods the way lesson 18 describes.

Routers are namespaces with forwarding switched on, and the routing protocols of lessons 16 and 17 are
FRR, one copy of its daemons per router. The function that lays a cable is short enough to read whole:

```bash
link() {  # link NODE1 IF1 NODE2 IF2 : one cable
  local tmp1="t$RANDOM$RANDOM" tmp2="u$RANDOM$RANDOM"
  ip link add "$tmp1" type veth peer "$tmp2"
  ip link set "$tmp1" netns "$1"; ip -n "$1" link set "$tmp1" name "$2"
  ip link set "$tmp2" netns "$3"; ip -n "$3" link set "$tmp2" name "$4"
  ip -n "$1" link set "$2" address "$(mac "$1" "$2")"
  ip -n "$3" link set "$4" address "$(mac "$3" "$4")"
  ip -n "$1" link set "$2" up
  ip -n "$3" link set "$4" up
}
```

It creates the pair under temporary names, moves one end into each device, renames them (`eth0` on a
PC, `p1` on a switch), gives each end a fixed MAC address and switches both on. With the office
scenario built, the computer itself can list its devices:

```
ana@lab:~$ ip netns list
isp (id: 8)
r1 (id: 7)
web2 (id: 11)
web1 (id: 10)
lb (id: 9)
sw1 (id: 3)
srv (id: 6)
pc3 (id: 5)
pc2 (id: 4)
pc1 (id: 1)
```

Ten namespaces, ten devices: three PCs and srv, the switch, the router r1, the provider's isp, the load
balancer and its two web servers. The order and the `id` numbers are the kernel's bookkeeping and say
nothing about the network. Looking inside the switch:

```
ana@lab:~$ sudo ip -n sw1 -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
br0              UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
p1@if413         UP             02:b7:0a:5d:30:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
p2@if415         UP             02:af:4f:ef:d8:f9 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p3@if417         UP             02:ae:7e:a8:31:05 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p4@if419         UP             02:11:c9:91:f3:9f <BROADCAST,MULTICAST,UP,LOWER_UP> 
p8@if421         UP             02:a0:79:0c:dd:24 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

`br0` is the bridge, the switch itself. `p1` to `p4` and `p8` are its ports, each one end of a cable,
and `@if413` says that the other end of p1 is interface number 413, which lives in another namespace.
Inside pc1:

```
ana@lab:~$ sudo ip netns exec pc1 ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if412       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
```

pc1's `eth0` is that other end, and its own `@if412` points back across the cable to p1. It holds
`10.20.10.21/24`, the address the office scenario gives it. The `02:` at the start of every MAC on the
switch marks an address the lab chose rather than a manufacturer, which lesson 2 explains.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"The office scenario of this course's lab. Inside the office, 10.20.10.0/24: pc1 at 10.20.10.21, pc2 at 10.20.10.22, pc3 at 10.20.10.23 and srv at 10.20.10.10, on ports p1 to p4 of the switch sw1. Port p8 goes to the router r1, which is 10.20.10.1 inside and 203.0.113.2 outside. r1 joins isp, at 203.0.113.1 and 192.0.2.1. Below isp is lb, the load balancer at 192.0.2.80, with two web servers behind it: web1 at 10.99.0.11 and web2 at 10.99.0.18.\"><rect x=\"10\" y=\"12\" width=\"300\" height=\"236\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the office</text><text x=\"298\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><rect x=\"200\" y=\"96\" width=\"96\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"20\" y=\"42\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><path d=\"M140 62 L200 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><rect x=\"20\" y=\"92\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"30\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.22</text><path d=\"M140 112 L200 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p2</text><rect x=\"20\" y=\"142\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"30\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.23</text><path d=\"M140 162 L200 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p3</text><rect x=\"20\" y=\"192\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"30\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.10</text><path d=\"M140 212 L200 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p4</text><text x=\"248\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><text x=\"288\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p8</text><path d=\"M296 131 L330 131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"330\" y=\"98\" width=\"120\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"340\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.1</text><text x=\"340\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><path d=\"M450 131 L478 131 L478 70 L490 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"490\" y=\"40\" width=\"112\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><text x=\"500\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.1</text><text x=\"500\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.1</text><path d=\"M546 100 L546 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"490\" y=\"140\" width=\"112\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">lb</text><text x=\"500\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><text x=\"500\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">load balancer</text><path d=\"M602 160 L622 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"622\" y=\"128\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"631\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web1</text><text x=\"631\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.99.0.11</text><path d=\"M602 188 L622 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"622\" y=\"180\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"631\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web2</text><text x=\"631\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.99.0.18</text></svg>", "caption": "The ten namespaces of the office scenario. Every box is a device with its own interfaces and routes; every line is a virtual Ethernet pair."}
```

To run it yourself you need a Linux machine you do not mind breaking, ideally a virtual machine, with
the packages the script lists in its `need()` function and a user called `ana`, which the script asks
you to create. Then:

```sh
sudo bash lab.sh list
sudo bash lab.sh up office
sudo bash lab.sh exec pc1 ana 'ping -c 2 srv'
sudo bash lab.sh down
```

`up` tears down whatever was there and builds the scenario from nothing, so every lesson starts from
the same state rather than from what the last one left behind. `exec` runs one command on one device
as one user, which is how the transcripts in these lessons were recorded. **It is the same kind of lab
as Mininet, so it has the same limit**: everything in it is Linux, and where a lesson talks about a
vendor's command line, it says so and shows no output for it.
