---
title: "The MAC table: learnt from the source, used for the destination"
version: 2
---

Lessons 1 and 2 showed a switch filling its table and called it learning. This lesson is about
that table and what follows from it. **A switch learns from the source address of each frame that
arrives, and uses what it learnt for the destination address of the frames that come after.** It
never learns from a destination, and that one fact explains most of what a switch does, including
the flooding in the next section.

This lesson runs on lesson 1's office, built with `sudo bash ~/netlab/netlab.sh up office`, and every
block of it starts from an empty table: `bridge fdb flush dev br0 dynamic` on sw1, and
`ip neigh flush all` on every other machine. Here is sw1 before and after a single ping from pc1 to the server:

```
root@sw1:~# bridge fdb show br br0 dynamic
ana@pc1:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 6.496/6.496/6.496/0.000 ms
root@sw1:~# bridge fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 master br0 
02:9e:43:3e:ca:ae dev p4 master br0 
```

**One ping, two entries.** pc1's echo request arrived on p1 with source `02:25:70:bc:29:c6`, so the
switch wrote that address against p1. The server's reply arrived on p4 with source
`02:9e:43:3e:ca:ae`, so that went against p4. The request's destination taught the switch nothing,
even though it named the server; only the reply, coming *from* the server, did. (Before either,
pc1's ARP question and the server's ARP answer had already carried both sources through the switch,
which is why both entries exist by the time the ping prints.)

The table is called by several names, and they all mean this list: the **MAC address table**, the
**CAM table** on many vendors' switches, after the memory it is kept in, and the **forwarding
database**, `fdb`, on Linux.

## Each entry has a clock

```
root@sw1:~# bridge -s fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 used 1/1 master br0 
02:9e:43:3e:ca:ae dev p4 used 1/1 master br0 
root@sw1:~# ip -d link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 30000
```

`bridge -s` adds two timers to each line: **`used 1/1`** is the number of seconds since the entry
was last used to forward a frame, and since it was last refreshed by a frame from that address.
Both say 1 because the ping had just happened.

The second timer is the one that matters. **`ageing_time 30000` is 300 seconds, in hundredths of a
second**: an entry that no frame from its address refreshes for five minutes is removed. Ageing is
what keeps the table true. A laptop moved from one desk to another appears on a new port, and its
first frame there rewrites its entry at once; a laptop that left the building stops refreshing its
entry and is gone five minutes later, freeing the line.

## What is not in the table

```
ana@pc1:~$ ip link show eth0 | grep ether
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
ana@pc3:~$ ip link show eth0 | grep ether
    link/ether 02:d9:6b:02:17:20 brd ff:ff:ff:ff:ff:ff link-netns sw1
```

pc3's card is `02:d9:6b:02:17:20`, and it is in none of the tables above. pc3 is cabled, its port
is up, and it has an address in the same network. **It is missing because it has sent nothing**,
and a switch only knows the machines that have spoken. That is ordinary and harmless: the first
frame pc3 sends, to anybody, puts it in the table. Until then, a frame addressed to pc3 is a frame
to an unknown destination, which is the next section.

Two more facts about the table, both of which lesson 19 and the port security section use:

- **It is finite.** A real switch keeps thousands of entries, sometimes tens of thousands, in fast
  memory, and a table that is full cannot learn the next address. What a switch does then is the
  subject of the port security section.
- **Entries can also be static.** `dynamic` in these commands filters for learnt entries; an entry
  typed by an administrator does not age and is not replaced by what the switch sees. The last
  section of this lesson relies on exactly that.
