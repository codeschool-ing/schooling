---
title: Cisco Packet Tracer: a simulation
version: 1
---

Packet Tracer is Cisco's own network simulator, made for teaching. It is free to download from Cisco
Networking Academy once you create an account there, and it runs on Windows, Linux and macOS. **It
was not run for this lesson**: it needs a graphical desktop and a login, and nothing on this page is
its output.

You build a network by dragging devices onto a canvas and joining them with cables — Cisco routers and
switches, generic PCs and servers, wireless devices — and then you configure them. Clicking a router
opens a command line that looks like IOS, the operating system of Cisco's routers, and accepts IOS
commands such as `enable`, `configure terminal` and `show ip route`.

That look is the thing to understand about it. **The command line is an imitation of IOS, written for
the courses, and not IOS itself.** Packet Tracer implements the commands and protocols that Cisco's
courses teach and stops there. A command a real router accepts may be missing, a default may differ,
and a protocol may be modelled in less detail than the real one. For somebody learning what a VLAN or
a static route is, that costs nothing. For somebody checking how a particular router, on a particular
software version, will behave, the answer is not in it.

Its best feature is one that real equipment cannot offer. Next to the normal real-time mode there is a
**simulation mode**, in which time stops: you step through the events one by one, watch each packet
travel as an envelope from device to device, and open it to see its headers layer by layer. An ARP
request flooding through a switch, a frame being tagged on a trunk, a TTL running out at a router:
each becomes a picture you can pause and inspect. It is close to the drawings in these lessons, made
interactive.

Where it fits:

- a first course in networking, especially one that follows Cisco's material, such as the CCNA;
- practising the shape of the IOS command line before you have a real device to type at;
- seeing the order of events in a protocol slowly enough to follow it.

Where it does not: any device that is not Cisco's, any feature the courses do not cover, and any
question about what a real device does exactly. For those, the next section's emulators run the real
software.
