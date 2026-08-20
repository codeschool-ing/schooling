---
title: ARP: the bridge between the two
---

To deliver a frame on the local network the machine needs the MAC of whoever holds that IP — and that is what **ARP** finds out. It shouts on the network "who has `192.168.0.1`?", and the owner answers with its own MAC.

The answer sits in a cache for a few minutes, otherwise every packet would cost a question. You can see yours with `arp -a`.

It is worth knowing that ARP checks nothing: whoever answers first is believed. That is the basis of the *ARP spoofing* attack, in which a machine answers in the router's place and starts receiving the network's traffic — the reason using HTTPS on a public network stops being a recommendation and becomes a necessity.
