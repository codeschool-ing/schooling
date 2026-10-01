---
title: Mininet: a network built from the kernel
version: 1
---

Mininet takes neither approach. **It builds the network out of the Linux kernel itself**: each host is
a process in its own network namespace, each cable is a pair of virtual Ethernet interfaces, and each
switch is a software switch in the kernel. It was made at Stanford for research on software-defined
networking, so by default its switches are Open vSwitch, steered by an OpenFlow controller. For this
lesson it ran in its simplest form, with ordinary Linux bridges as switches (`--switch lxbr`) and no
controller at all (`--controller none`), so that it needs nothing beyond the kernel. The version is
Mininet 2.3.0, from Ubuntu's own package.

One command builds a network, tests it and takes it down again. `--topo linear,3` asks for three
switches in a line with one host on each, and `--test pingall` makes every host ping every other host:

```
ana@lab:~$ sudo mn --switch lxbr --controller none --topo linear,3 --test pingall
*** Creating network
*** Adding controller
*** Adding hosts:
h1 h2 h3 
*** Adding switches:
s1 s2 s3 
*** Adding links:
(h1, s1) (h2, s2) (h3, s3) (s2, s1) (s3, s2) 
*** Configuring hosts
h1 h2 h3 
*** Starting controller

*** Starting 3 switches
s1 s2 s3 
*** Waiting for switches to connect
s1 s2 s3 
*** Ping: testing ping reachability
h1 -> h2 h3 
h2 -> h1 h3 
h3 -> h1 h2 
*** Results: 0% dropped (6/6 received)
*** Stopping 0 controllers

*** Stopping 5 links
.....
*** Stopping 3 switches
s1 s2 s3 
*** Stopping 3 hosts
h1 h2 h3 
*** Done
completed in 9.602 seconds
```

Read it from the top. Mininet created three hosts, three switches and five links: three joining each
host to its switch, and two joining the switches in a line. It printed `*** Adding controller` and,
at the end, `Stopping 0 controllers`, because the step runs whatever was asked for and here that was
nothing. Each host then pinged the other two — `h1 -> h2 h3` means h1 reached both — and the result
is `0% dropped (6/6 received)`: three hosts, two pings each. The network was built, tested and
removed in 9.602 seconds on this lab's virtual machine.

Without `--test`, Mininet opens a prompt of its own, `mininet>`, where a command typed after a host's
name runs inside that host. In a second run with the same topology, three commands were typed there:

- `net` listed every node and what each of its interfaces is joined to. The middle switch's line was
  `s2 lo:  s2-eth1:h2-eth0 s2-eth2:s1-eth2 s2-eth3:s3-eth2`: port 1 to h2, port 2 to s1, port 3 to
  s3. The drawing below is those lines, drawn;
- `h1 ip -br addr` showed h1's interface `h1-eth0` with `10.0.0.1/8`. Unless told otherwise, Mininet
  numbers its hosts from 10.0.0.1 inside 10.0.0.0/8;
- `h1 ping -c 2 h3` crossed all three switches: 2 packets transmitted, 2 received, the first reply in
  3.89 ms and the second in 0.824 ms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"Mininet's linear,3 topology, as its net command listed it. Three hosts, h1, h2 and h3, each joined to its own switch: h1-eth0 to s1-eth1, h2-eth0 to s2-eth1, h3-eth0 to s3-eth1. The switches form a line: s1-eth2 to s2-eth2, and s2-eth3 to s3-eth2. Five links in all.\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hosts</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">switches</text><rect x=\"125\" y=\"28\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h1</text><rect x=\"125\" y=\"138\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s1</text><path d=\"M170 64 L170 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"176\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h1-eth0</text><text x=\"176\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s1-eth1</text><rect x=\"335\" y=\"28\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h2</text><rect x=\"335\" y=\"138\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s2</text><path d=\"M380 64 L380 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"386\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h2-eth0</text><text x=\"386\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s2-eth1</text><rect x=\"545\" y=\"28\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h3</text><rect x=\"545\" y=\"138\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s3</text><path d=\"M590 64 L590 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"596\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h3-eth0</text><text x=\"596\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s3-eth1</text><path d=\"M215 156 L335 156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M425 156 L545 156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"219\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s1-eth2</text><text x=\"331\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s2-eth2</text><text x=\"429\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s2-eth3</text><text x=\"541\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s3-eth2</text></svg>", "caption": "What --topo linear,3 built: three switches in a line, one host on each, five links. A ping from h1 to h3 crosses all three switches."}
```

Two things make Mininet good to learn with. **It is real networking**: `ip`, `ping`, `tcpdump` and `ss`
run inside a Mininet host exactly as they run on a Linux server, because that is what the host is, a
corner of a Linux machine's network stack. And it is a Python library as well as a command, so a
topology can be written as a short program and rebuilt identically every time. What it does not give
you is any vendor's device: its hosts and switches are Linux, and a lab that needs IOS needs one of
the tools from the previous two sections.
