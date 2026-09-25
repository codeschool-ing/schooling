---
title: Testing the MTU on Windows and macOS
version: 1
---

The test in section 06 is the one to run when a fault looks like section 07, and every system can run
it:

```sh
ping -f -l 1472 192.0.2.80                     # Windows: -f forbids fragmenting, -l is the size
netsh interface ipv4 show subinterfaces        # Windows: the MTU of each interface
ping -D -s 1472 192.0.2.80                     # macOS: -D forbids fragmenting
networksetup -getMTU en0                       # macOS: the MTU of the Wi-Fi card
```

**None of these were run for this lesson.** The flags differ and the idea does not: forbid
fragmenting, and find the largest size that gets an answer. On Windows the don't-fragment flag is `-f`
and the size is `-l`; a packet too big for some link on the way answers `Packet needs to be fragmented
but DF set.` On macOS the flag is `-D` and the size is `-s`, as on Linux.

The number to remember is the difference: **the largest data size that works, plus 28, is the path
MTU**. 1472 means 1500 and a healthy Ethernet path; 1464 means 1492 and a PPPoE line somewhere on the
way.
