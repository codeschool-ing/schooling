---
title: Seeing two machines claim one address
version: 1
---

The symptom of ARP spoofing also has an innocent cause, and the innocent one is far more common: two
machines configured with the same address. The lab has one now. A printer was plugged into the staff
LAN and, by mistake, given `desk`'s address, `192.168.10.21`. On your own computer, `plug` puts it
there:

```sh
sudo bash nslab.sh plug printer lan 192.168.10.21/24 52:54:00:0a:77:21
```

`arping` asks for that address by hand and prints every answer:

```
ana@laptop:~$ arping -c 3 -I eth0 192.168.10.21
ARPING 192.168.10.21 from 192.168.10.20 eth0
Unicast reply from 192.168.10.21 [52:54:00:0A:77:21]  0.548ms
Unicast reply from 192.168.10.21 [52:54:00:A8:0A:15]  0.562ms
Unicast reply from 192.168.10.21 [52:54:00:A8:0A:15]  0.551ms
Unicast reply from 192.168.10.21 [52:54:00:A8:0A:15]  0.558ms
Sent 3 probes (1 broadcast(s))
Received 4 response(s)
```

**Two different MACs answered for one address.** `52:54:00:0A:77:21` answered once, the printer;
`52:54:00:A8:0A:15`, `desk`, answered every probe. Whether this is a printer set up in a hurry or a
machine lying about the gateway, the defender's response starts the same way: find both MACs in the
switch's address table, go to the ports, and find out which one should not be saying that.

## Asking before taking an address

`arping -D` is **duplicate address detection**: it asks for an address from the source `0.0.0.0`, the
way a machine should before configuring one, and reports whether anybody already has it. From the
sensor, for an address in use and one that is free:

```
root@sensor:~# arping -D -c 2 -I eth0 192.0.2.80; echo "exit $?"
ARPING 192.0.2.80 from 0.0.0.0 eth0
Unicast reply from 192.0.2.80 [52:54:00:00:02:50]  0.540ms
Sent 1 probes (1 broadcast(s))
Received 1 response(s)
exit 1
root@sensor:~# arping -D -c 2 -I eth0 192.0.2.81; echo "exit $?"
ARPING 192.0.2.81 from 0.0.0.0 eth0
Sent 2 probes (2 broadcast(s))
Received 0 response(s)
exit 0
```

For `192.0.2.80`, `www` answered and `arping` exits with 1: taken. For `.81`, nobody answered and it
exits with 0: free. A script that assigns addresses by hand should ask this first.

## Watching for changes

The question worth monitoring is continuous: **has the MAC behind an important address changed?** The
gateway's MAC should not change unless the gateway was replaced. Tools that watch ARP traffic on a
segment, the classic one being `arpwatch`, record every address-to-MAC pairing they see and report a
new pairing, a changed one, and one that flips back and forth. An intrusion detection sensor on the
segment can do the same; the alert that matters is *the gateway's MAC changed*, and it should be
rare enough that every occurrence is read.
