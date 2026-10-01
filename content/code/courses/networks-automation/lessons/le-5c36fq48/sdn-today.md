---
title: Where SDN went
version: 1
---

OpenFlow as this lesson used it, a controller programming every switch flow by flow, is rare in
production networks today. The ideas did not disappear; they moved, and most of them are already in
this course.

**Data-centre fabrics** are where controllers stayed. A fabric controller takes the intent, which
networks exist and which servers belong to them, and configures the switches, usually by pushing
configuration or BGP EVPN routes rather than individual flows. The switches keep a distributed
control plane underneath, so a controller outage stops changes rather than traffic.

**Overlays** put the programmable part at the edge. VXLAN tunnels between hypervisors carry the
virtual networks, and Open vSwitch, programmed by OpenFlow from a controller, is that edge in
platforms such as OpenStack; the physical network underneath only routes IP. Cloud providers' virtual
networks work the same way, with their own controllers.

**SD-WAN** applied the idea to branch offices: a controller decides which link each application's
traffic takes, and the branch boxes follow.

What all of them expose is the thing this course has been about. **A controller has an API,
usually REST, and a model of the network**; automating it is lesson 2's requests, lesson 6's data
formats, lesson 12's source of truth and lesson 14's pipeline, pointed at one system instead of a
hundred boxes. The routers and switches did not stop needing configuration; what changed is who
holds it, and how many places it has to be written.
