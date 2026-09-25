---
title: The other version of IP
version: 1
---

Everything so far was **IPv4**: 32-bit addresses, written as four numbers. There are about four
billion of them, far fewer than the devices that want one, which is the real reason NAT exists. **IPv6**
is the replacement: 128-bit addresses, written as eight groups of four hexadecimal digits with the
longest run of zero groups shortened to `::`. `2001:db8::80` is one, from the range set aside for
documentation.

What changes for support is less than the addresses suggest:

- The layers are the same. IPv6 is the internet layer; TCP, UDP and every application protocol run
  on it unchanged.
- There is no ARP. IPv6 finds its neighbours with ICMPv6 messages instead, and `ip -6 neigh` shows
  the table.
- There is no need for NAT. Every device can have a public address of its own, so a firewall, not
  address translation, is what keeps connections from coming in uninvited.
- Most networks today run **both at once**, *dual stack*, and a program tries IPv6 first when a name
  has an IPv6 address. A fault that affects only IPv6 looks like a site that is slow to start, when a
  program that does not race the two waits for IPv6 to fail before it tries IPv4.

**The lab has no IPv6 at all**: the machine it runs on was built without it, and section 03's `strace`
showed a program finding that out. Lesson 4 shows the `AAAA` record that holds an IPv6 address in DNS,
and the addressing itself belongs to the networks-addressing course.
