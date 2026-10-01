---
title: GNS3 and EVE-NG: running the real software
version: 1
---

GNS3 and EVE-NG take the opposite approach to Packet Tracer. Instead of imitating a router, **they run
the router's real operating system** inside a virtual machine or an emulator, and join the machines
with virtual cables. When a router in one of them answers `show ip route`, it is the vendor's own code
answering. **Neither was run for this lesson**: the device images they need are licensed software,
and nothing on this page is their output.

GNS3 is free and open source, and it comes in two parts: a graphical client where you draw the
topology, and a server that runs the devices. The server can run on the same computer, but it usually
runs in a virtual machine of its own (the GNS3 VM) or on another computer, because the devices are
heavy. It runs several kinds of device side by side:

- old Cisco router images, through an emulator called Dynamips;
- anything that boots in QEMU, the virtual machine software: a modern router or firewall image, a
  Linux server, a Windows client;
- Docker containers, for light hosts.

A **cloud** node joins the emulated network to a real interface of your computer, so a lab can reach
the real network or the internet when you want it to.

EVE-NG (Emulated Virtual Environment – Next Generation) does the same job as a server you use from a
web browser. It is installed as a virtual machine or on a dedicated server, and the topology, the
devices and their consoles all open in the browser, which suits a lab that several people share. It
comes as a free Community edition and a paid Professional edition.

What both give you is fidelity: a firewall from one vendor and a router from another, each running
its real software and configured through its real command line. What that costs:

- **images**: neither tool ships with vendor software. The router and firewall images come from their
  vendors, under their licences, often tied to a support contract or a training account; an image
  copied from somewhere else is software you are not licensed to run;
- **memory and processor**: each device is a virtual machine with its own memory reserved, and a
  current vendor image may want gigabytes, so a lab of ten such routers needs a server rather than a
  laptop;
- **setup**: an image has to be imported and matched to the settings that boot it, which takes longer
  than drawing the network.

Use them when the brand and the version matter: rehearsing a change on the exact firewall software the
company runs, preparing for a vendor's certification on its own operating system, or reproducing a
problem that a real device shows and a model would not.
