---
title: Which one to open
version: 2
---

The tools differ less in quality than in what they answer. **Pick by the question you are asking, not
by the tool you know.**

| tool | what runs inside | cost and licence | good for |
|---|---|---|---|
| Packet Tracer | Cisco's imitation of its own devices | free, with a Networking Academy account | first steps, the shape of IOS, packets step by step |
| GNS3 | real device software, in virtual machines and containers | free and open source; images licensed by their vendors | labs mixing vendors, rehearsing a change on real software |
| EVE-NG | the same, served to a browser | Community free, Professional paid; images licensed by vendors | shared labs, larger topologies |
| Mininet | the Linux kernel's network stack | free and open source | software-defined networking, topologies written as programs |
| namespaces, as `netlab.sh` | the Linux kernel's network stack | free; one shell script | the protocols themselves, captured exactly |
| real equipment | the real device | the device, the space and the power | cabling, power, radio, the final check |

Four questions show how the choice falls:

- **"What does a switch do with a frame for an unknown MAC?"** Any of them. Packet Tracer's
  simulation mode shows it as an animation; the lab shows it as a `tcpdump` capture, which is what
  lesson 18 does.
- **"Does this configuration work on our firewall?"** Only that firewall's own software can say: an
  emulator running the vendor's image, under the company's licence, and then a maintenance window on
  the real one.
- **"How long does OSPF take to find another path after a cable is cut?"** The kernel tools, with FRR
  and a capture, which is how lesson 3's ring measured it. The number they give is that lab's number;
  a real network's timers and hardware give its own.
- **"Is this cable faulty?"** No lab. A virtual cable has no copper to break, and neither does a
  simulated one. Physical-layer questions — a bad crimp, a port's power budget for a phone, a Wi-Fi
  channel — need the physical thing.

This course uses the namespace lab for a reason that is about honesty as much as cost: every
transcript in it is something a real kernel printed, and anyone with a Linux machine can build
the same networks from the files these lessons show and get the same lines, timings apart. Where a lesson needs a device the lab cannot be — a modem, an access
point, a vendor's command line — it says so and shows nothing.
