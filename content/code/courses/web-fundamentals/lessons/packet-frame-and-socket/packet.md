---
title: Packet: why data travels in pieces
---

Nothing crosses the network whole. A 2 GB video is cut into thousands of **packets**, each carrying a piece of the content and a header saying where it came from and where it is going.

The first reason is coexistence: if a large file travelled in one block, it would occupy the path until it finished and everything else would wait. Chopped up, the packets of several conversations interleave, and a long transfer does not stop a short one from getting through.

The other reason is failure. A lost packet costs a few kilobytes to resend; a lost file costs the file. And because each packet knows its destination, each can take a different route — if a stretch of the network goes down mid-transmission, the following ones detour without the conversation starting over.
