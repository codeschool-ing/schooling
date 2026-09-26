---
title: Where they meet
version: 1
---

Host and guest are joined by devices that have one end on each side. The two ends can be matched:

```
ana@host:~$ virsh domblklist vm1
 Target   Source
---------------------------------------------
 vda      /var/lib/libvirt/images/vm1.qcow2

ana@host:~$ virsh domiflist vm1
 Interface   Type      Source    Model    MAC
-------------------------------------------------------------
 vnet2       network   default   virtio   52:54:00:ce:da:4e

ana@vm1:~$ ip -br link show enp1s0
enp1s0           UP             52:54:00:ce:da:4e <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

**The disk** is `vda` inside and `/var/lib/libvirt/images/vm1.qcow2` outside. **The network card** is
`enp1s0` inside and `vnet2` outside, and both show the same MAC, `52:54:00:ce:da:4e`. That is one virtual cable:
`vnet2` is its host end, a port plugged into the switch of the network called `default`, and `enp1s0`
is the guest's end. When a guest has no network, this is the pair to check, and lesson 11 builds other
networks out of the same parts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Host and guest side by side, joined in three places. On the left, host, with kernel 6.18.44-fc-v37, libvirt holding the guest&#x27;s description, the qemu-system-x86 process, and the switch virbr0 at 192.168.122.1. On the right, vm1, with its own kernel 6.8.0-139-generic. The file vm1.qcow2 on host is the disk vda in vm1. The port vnet2 on virbr0 and the card enp1s0 in vm1 are two ends of one virtual cable with one MAC, 52:54:00:ce:da:4e. And the qemu-guest-agent service in vm1 answers libvirt through the agent&#x27;s channel.\"><defs><marker id=\"sd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"270\" height=\"236\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">host</text><rect x=\"430\" y=\"14\" width=\"270\" height=\"236\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">vm1</text><text x=\"34\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel 6.18.44-fc-v37</text><text x=\"444\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel 6.8.0-139-generic</text><rect x=\"34\" y=\"72\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">libvirt: the description, virsh</text><rect x=\"34\" y=\"116\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the qemu-system-x86 process</text><rect x=\"444\" y=\"116\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">qemu-guest-agent</text><path d=\"M278 131 L442 131\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sd-ah)\" marker-start=\"url(#sd-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the agent’s channel</text><rect x=\"34\" y=\"160\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vm1.qcow2: a file</text><rect x=\"444\" y=\"160\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vda: a disk</text><path d=\"M278 175 L442 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sd-ah)\" marker-start=\"url(#sd-ah)\"></path><rect x=\"34\" y=\"204\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" xml:space=\"preserve\">virbr0  192.168.122.1</text><text x=\"264\" y=\"223\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet2</text><rect x=\"444\" y=\"204\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enp1s0</text><text x=\"674\" y=\"223\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">52:54:00:ce:da:4e</text><path d=\"M278 219 L442 219\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sd-ah)\" marker-start=\"url(#sd-ah)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one virtual cable, one MAC</text></svg>", "caption": "Two systems, each with its own kernel, joined by devices that have one end on each side. The host sees a file, a port and a channel; the guest sees a disk, a network card and the port its agent answers on."}
```

Matching MACs is also how you find which guest is which, when a switch's list or a DHCP log shows an
address you do not recognise. Every guest libvirt makes gets a MAC beginning `52:54:00`, the prefix
QEMU uses, so a `52:54:00` address on a network is a QEMU guest somewhere.
