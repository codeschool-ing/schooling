---
title: When packets, and not logs
version: 1
---

Lesson 1 laid out the sources from the least detailed to the most: a log line says a connection happened, a
flow record says between whom and how many bytes, and a **packet capture** holds the packets themselves, every
byte that crossed the wire. Lesson 12's flow said 612 MB left `files` for `203.0.113.200`. It could not say what
those bytes were. A capture of that night could have, if the traffic was not encrypted.

Packets are the most detailed source and the most expensive one, which is why nobody keeps all of them for long:

| | flow records | full packet capture |
|---|---|---|
| **says** | who, to whom, when, how many bytes | all of that, plus every byte of content |
| **size** | a few dozen bytes per conversation | the whole conversation, and a little more |
| **kept for** | months | hours or days, on a busy network |
| **answers** | "did `files` talk to this address?" | "what did `files` send to this address?" |

So in practice a SOC does two things. It keeps flows for a long time, and it captures packets **on purpose**: a
rolling buffer of the last few hours at the internet edge, or a capture started on one host or one address during
an incident, the way lesson 13's containment would have been a good moment to start one on `fw`'s `eth0`.

This lesson captures one ordinary download in the lab and takes it apart, from the packets to the file.
