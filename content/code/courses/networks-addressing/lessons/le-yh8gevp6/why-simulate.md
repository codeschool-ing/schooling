---
title: Practising on a network that is not there
version: 1
---

Learning networks from a book alone fails in the same place every time: the moment something does not
work, and you have never seen what not working looks like. **A practice network exists so that you
can break things on purpose and watch what happens.** Three reasons make one worth setting up:

- **hardware**: a switch, two routers and a firewall cost money and a shelf, while a lab of twenty
  devices costs some of a laptop's memory;
- **safety**: a wrong route on a practice network takes down nothing, and on the office router it takes
  down the office;
- **rehearsal**: a change you are about to make in production — a new VLAN, a route, a firewall rule —
  can be tried first on a copy of the network, and the copy is cheap to throw away.

The tools that build these networks are all called "simulators" in conversation, and the word hides
the difference that matters most, which is **what is actually running inside each box**:

| kind | what runs inside a device | examples |
|---|---|---|
| simulation | a program that imitates the device's behaviour | Cisco Packet Tracer |
| emulation | the device's real operating system, in a virtual machine | GNS3, EVE-NG |
| kernel virtualisation | the real Linux network stack, divided into isolated pieces | Mininet, this course's lab |

That column decides what a result means. In a simulation, a router does what the authors of the
imitation programmed it to do: a command the imitation does not know does not exist, and a behaviour
it models may differ in detail from the real router's. In an emulation, the router runs the vendor's
actual software, so its behaviour is the real one, at the price of a licensed image and a virtual
machine's memory for every device. In kernel virtualisation, every packet is a real packet handled by
the real Linux kernel, but every device is Linux: you configure a Linux bridge and FRR, not a Cisco
switch's command line.

**None of the three proves what a particular real network will do.** Each proves something narrower,
and the next four sections say what. Two wrong conclusions are common, one in each direction: taking
a lab result as proof that a change is safe on the real equipment, and dismissing a lab because its
devices are not the brand in the rack. The protocols themselves follow the same standards everywhere
— OSPF on a Cisco router, a Juniper router or FRR speaks the protocol its RFC describes — and the
protocols are what a lab teaches best.
