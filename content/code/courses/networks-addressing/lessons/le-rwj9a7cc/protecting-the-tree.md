---
title: Protecting the tree from what gets plugged in
version: 1
---

Spanning tree believes every BPDU it receives. That is what lets it work with no configuration, and
it is also its weak side: **any device that sends BPDUs takes part in the election**, whether it is
the core switch or a cheap switch somebody brought from home and plugged in under a desk.

Two things can go wrong. If the new device has a lower bridge ID, it **becomes the root**, and the
whole network reshapes itself around it: traffic between two floors may now cross a desk switch on a
cable nobody planned for. And a person who connects two wall sockets to the same small switch, or
plugs both ends of one cable into it, builds the loop from the first section of this lesson in a
place nobody is watching. The defences below are all settings on the ports where those devices
appear: the edge.

## BPDU guard: a port that faces a computer should never hear a BPDU

A port with a PC, a printer or a phone on it has no reason to receive spanning-tree traffic, so
receiving any is evidence that a switch has appeared there. **BPDU guard shuts the port down the
moment a BPDU arrives.** It was switched on for `p10` on `sw1`, the port `pc1` is on:

```
root@sw1:~# bridge link set dev p10 guard on
root@sw1:~# bridge link show dev p10
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@pc1:~# ip link add br9 type bridge stp_state 1 && ip link set eth0 master br9 && ip link set br9 up
root@sw1:~# bridge link show dev p10
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state disabled priority 32 cost 2 
```

The command on `pc1` makes it behave like a small switch running spanning tree: it creates a bridge
with STP on and puts its network card in it, so its card starts sending BPDUs. Six seconds later
`sw1`'s `p10` was **`state disabled`**, though the cable was still in and the link still
`LOWER_UP`. A guarded port does not argue about the election; it leaves it. `pc1` has lost its
network, which is the point: whoever plugged in the switch notices, and the rest of the network
does not.

The capture stops there. How a port comes back is a decision for whoever runs the switch: on most
equipment somebody re-enables it by hand after finding the device, and some can be set to retry by
themselves after a while.

## Root guard: the root must never be on this side

BPDU guard suits ports that should hear no BPDUs at all. **Root guard** is for ports that face other
switches legitimately, such as the cables from a distribution switch down to the access switches.
BPDUs are fine there, but one that claims a better root than the current one is not. A root-guarded
port that receives such a BPDU stops forwarding until those BPDUs stop, and the root stays where it
was placed.

## BPDU filter, and why it is dangerous

**BPDU filter** stops a port sending BPDUs and makes it ignore those it receives. It is sometimes
used on ports facing another organisation's network, where the two trees must not merge. On an
ordinary access port it is the opposite of protection: **a port that ignores BPDUs cannot find out
that it is part of a loop**, so a cable between two filtered ports is the storm from the first
section with spanning tree switched on everywhere else. If a port is meant to face computers only,
BPDU guard is the setting that says so and acts on it.

## The last line: storm control

Everything above prevents a loop. **Storm control** limits the damage of one that happens anyway: a
port is given a ceiling on how much broadcast and multicast traffic it accepts, and above it the
excess is dropped or the port is shut. It does not find the loop. It keeps one loop from taking the
whole segment down, and buys someone the time to find the cable.
