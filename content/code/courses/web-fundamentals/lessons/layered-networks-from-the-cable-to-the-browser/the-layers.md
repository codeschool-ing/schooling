---
title: The four that matter in practice
---

The OSI model has seven layers and is good for studying. Day to day, four explain almost everything:

- **Link** — the frame on the cable or in the air. MAC address, Ethernet, Wi-Fi.
- **Network** — the packet crossing different networks. IP address, routing.
- **Transport** — the conversation between two programs. Ports, TCP and UDP.
- **Application** — what the programs say to each other. HTTP, DNS, SMTP.

Each layer wraps the one above: the frame contains the packet, which contains the segment, which contains the HTTP request. It is literally a set of nesting dolls, and that is how Wireshark shows any capture.
