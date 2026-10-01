---
title: A connection is four numbers
version: 1
---

A TCP connection is not identified by an address, and not by a port. **It is identified by four
numbers together: the client's address and port, and the server's address and port.** Change any one
of them and it is a different connection. That set, with the protocol, is what the kernel looks up
for every segment that arrives, to decide which program it belongs to.

Here are the three connections srv listed in the previous section, written out:

| client address | client port | server address | server port |
|---|---|---|---|
| 10.20.10.23 | 52730 | 10.20.10.10 | 80 |
| 10.20.10.21 | 60504 | 10.20.10.10 | 80 |
| 10.20.10.22 | 59648 | 10.20.10.10 | 80 |

Two of the four columns are the same on every row, and they have to be: a client can only connect to
what it knows, and all three knew `srv` port 80. The other two make each row unique. Three PCs means
three different addresses, so here the client address alone would have been enough. Two browser tabs
on pc1 would open two connections from one address, though, and then only the port tells them apart.

**The server's port is fixed and known in advance; the client's port is ephemeral.** Nobody chose
`60504`. When the client connected without asking for a port, pc1's kernel picked a free one, used it
for this one connection, and will hand it to another connection once this one is gone. On Linux the
range it picks from is a setting, `net.ipv4.ip_local_port_range`, and its default is 32768 to 60999;
every client port in this lesson's captures falls inside it. The well-known ports below 1024 — 22 for
SSH, 80 for HTTP, 443 for HTTPS — are the other half of the convention: numbers a server listens on so
that clients do not have to be told.

Reading a line of `ss`, then, is reading four numbers and a state:

- `Local Address:Port` is this machine's side and `Peer Address:Port` is the other machine's, so the
  same connection listed on the client shows the two sides swapped — the next section shows exactly
  that, on two machines at once;
- `State` is TCP's: `LISTEN` for a socket that waits, `ESTAB` for a conversation in progress, and a
  few others for the moments of opening and closing;
- `Recv-Q` and `Send-Q` are bytes waiting to be read by the program or acknowledged by the other side,
  and on a quiet connection both are 0.

The idea worth dropping here is that a port belongs to one conversation, so that "port 80 is busy"
while a client is connected. Port 80 on srv is listened on once and shared by every connection that
arrives there. **What cannot exist is two connections with all four numbers equal**, because the
kernel would not know which program a segment belongs to. Lesson 11 meets that rule again from the
other side, when a router rewrites a client's address and port on the way out and has to keep every
connection unique while it does.
