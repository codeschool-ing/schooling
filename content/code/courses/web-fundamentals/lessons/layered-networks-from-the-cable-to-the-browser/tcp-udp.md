---
title: TCP and UDP: guarantee, or do not wait
---

The transport layer has two choices, and the difference is what each one promises.

**TCP** guarantees delivery, order and integrity: it acknowledges every piece, resends what was lost and reassembles in the right sequence. It costs a connection to establish and it waits for whatever is missing. It is what HTTP uses — half an HTML document is no use to anyone.

**UDP** promises nothing: it sends and moves on. It costs almost nothing and waits for no one. It is what video calls and games use, because in a live video a late frame is already useless — better to lose it than to freeze the picture waiting for it.

The rule of thumb: if incomplete data is useless, TCP. If late data is useless, UDP.
