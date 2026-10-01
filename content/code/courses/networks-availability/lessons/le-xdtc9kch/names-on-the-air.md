---
title: An SSID is a name, not a lock
version: 1
---

This lesson and the two after it have no transcripts. **The lab is one Linux computer with no wireless
hardware at all**, so there is no beacon to capture and no handshake to decode. What stands in for them
is what the standards say, drawn, and a few numbers you can compute and check yourself.

An access point announces each of its networks in a **beacon**, a small management frame sent roughly
ten times a second. The 802.11 default interval is 100 time units of 1.024 ms each, so 102.4 ms. The
beacon carries two names that people mix up:

| | what it is | how many |
|---|---|---|
| **SSID** | the network's name, up to 32 bytes, chosen by a person | one per network, the same on every AP |
| **BSSID** | the MAC address of one radio serving that network | one per network, per radio, per AP |

A company with 20 dual-band APs and two networks, staff and guest, has 2 SSIDs and **80 BSSIDs**. A
phone chooses a network by its SSID and then attaches to one BSSID, the one it hears best. Moving from
one BSSID to another inside the same SSID is roaming, and lesson 9 is about how badly that can go.

## Hiding the name hides nothing

**A hidden SSID is not a security measure.** The AP leaves the name out of its beacons, but a client that
wants to join still has to name the network, in its probe requests and in its association request. Those frames are not encrypted. Anybody listening while one device joins has the name.

It also costs something. A device configured for a hidden network cannot wait to hear the name, so it
asks for it, by name, wherever it goes: in the airport, in the café, at home. **Hiding the office's SSID
makes every laptop announce it in public.**

Filtering by MAC address fails the same way. Every frame carries the sender's address in clear, so an
allowed address is easy to observe. And current phones and laptops use a **random MAC address per
network** by default, which breaks the list for the very users it was meant to admit.

What actually decides who gets on is authentication with a key, and what keeps a neighbour from reading
the traffic is encryption with a key. The next three sections are those keys.

## Every SSID costs airtime

Each network on a radio sends its own beacons, at the lowest data rate allowed, so that the weakest
client can read them. Ten SSIDs is ten beacons every 102.4 ms before anybody sends any data. **A common
rule of thumb is three or four SSIDs per radio at most**, a guideline from design practice rather than a
limit in the standard. So a guest network earns its own SSID, and "one per department" does not:
departments are separated by VLAN behind one SSID, as the section on enterprise shows.
