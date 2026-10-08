---
title: Documentation, read off the network
version: 2
---

Every principle in this lesson depends on somebody knowing what the network actually is: which cable
goes where, which address belongs to what. That knowledge is **documentation**, and the common failure
is not its absence. It is a diagram drawn carefully once, two years ago, that has been wrong since the
third change nobody wrote down. **A document that is out of date is worse than none**, because people
trust it.

The habit that keeps documentation true is to **read it off the network** rather than remember it, and
to read it again after every change. Two sources do most of the work.

## Who is at the other end of each cable

**LLDP** (*Link Layer Discovery Protocol*, IEEE 802.1AB) has every device announce, on each of its ports,
its own name and the name of that port. Its neighbour hears the announcement and keeps it. Cisco devices
also speak their own older equivalent, CDP. Every device in the campus runs an LLDP agent, so d1 can say
who is on each of its cables:

```
root@d1:~# lldpcli show neighbors summary
-------------------------------------------------------------------------------
LLDP neighbors:
-------------------------------------------------------------------------------
Interface:    eth1, via: LLDP
  Chassis:     
    ChassisID:    mac 02:fb:a8:e8:50:e9
    SysName:      c1
  Port:        
    PortID:       mac 02:7e:9d:cf:48:0f
    PortDescr:    eth2
    TTL:          120
-------------------------------------------------------------------------------
Interface:    eth2, via: LLDP
  Chassis:     
    ChassisID:    mac 02:2d:f7:47:cf:aa
    SysName:      c2
  Port:        
    PortID:       mac 02:26:88:68:68:77
    PortDescr:    eth2
    TTL:          120
-------------------------------------------------------------------------------
Interface:    eth0, via: LLDP
  Chassis:     
    ChassisID:    mac 02:73:d3:57:7d:1c
    SysName:      a1
  Port:        
    PortID:       mac 02:73:d3:57:7d:1c
    PortDescr:    p24
    TTL:          120
-------------------------------------------------------------------------------
```

Read one block at a time. On d1's `eth1` is a device whose `SysName` is **c1**, and the port at c1's end
is described as **eth2**. On `eth2` is **c2**, on its port **eth2**. On `eth0` is **a1**, on its port
**p24**. `TTL: 120` is how many seconds d1 will keep each announcement without hearing it again; a
neighbour that goes quiet drops off the list after that. The access switch tells the story from below:

```
root@a1:~# lldpcli show neighbors summary
-------------------------------------------------------------------------------
LLDP neighbors:
-------------------------------------------------------------------------------
Interface:    p24, via: LLDP
  Chassis:     
    ChassisID:    mac 02:6f:a4:a3:1d:c4
    SysName:      d1
  Port:        
    PortID:       mac 02:33:b5:7f:7e:aa
    PortDescr:    eth0
    TTL:          120
-------------------------------------------------------------------------------
Interface:    p1, via: LLDP
  Chassis:     
    ChassisID:    mac 02:25:70:bc:29:c6
    SysName:      pc1
  Port:        
    PortID:       mac 02:25:70:bc:29:c6
    PortDescr:    eth0
    TTL:          120
-------------------------------------------------------------------------------
```

a1's `p24` goes up to d1's `eth0`, and its `p1` goes down to pc1's `eth0`. Those two outputs are a
**cable table**, and it is worth writing out as one:

| device | port | goes to | port there |
|---|---|---|---|
| d1 | eth1 | c1 | eth2 |
| d1 | eth2 | c2 | eth2 |
| d1 | eth0 | a1 | p24 |
| a1 | p1 | pc1 | eth0 |

## Which address is on which interface

```
root@d1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if318       UP             10.20.0.6/30 fe80::6f:a4ff:fea3:1dc4/64 
eth2@if322       UP             10.20.0.14/30 fe80::67:b3ff:fea2:23a6/64 
eth0@if325       UP             10.20.11.1/24 fe80::33:b5ff:fe7f:7eaa/64 
```

(The `@if318`-style suffix is the lab showing through: the number of the interface at the other end of
the virtual cable.) That gives the **address table** for d1:

| device | interface | address | network |
|---|---|---|---|
| d1 | eth1 | 10.20.0.6/30 | link to c1 |
| d1 | eth2 | 10.20.0.14/30 | link to c2 |
| d1 | eth0 | 10.20.11.1/24 | pc1's LAN, as its gateway |

Put the two tables side by side and they check each other: d1's `eth2` goes to c2 according to LLDP,
and holds `10.20.0.14/30` according to `ip`, which is the link the campus figure draws between d1 and
c2. When the two sources disagree with the drawing, **the drawing is the one that is wrong**.

## What makes documentation last

- **Generate it.** A script that runs `lldpcli` and `ip -br addr` on every device and writes the tables
  produces a document that is true on the day it runs. Rerun it after every change, and keep the
  output under version control so the differences show what changed and when.
- **Write down what the network cannot say.** LLDP knows the cable; it does not know the decisions. Why
  d1 has no twin, which single points of failure were accepted (the previous sections), which block of
  addresses is reserved for the next building: those exist only if somebody writes them.
- **Mind what you announce.** LLDP tells anybody plugged into a port what the device is and what it is
  called. On ports that face users or visitors, many networks switch it off or limit it; between network
  devices it is the cheapest documentation there is.

The test of a network's documentation is simple and unkind: could somebody who has never seen it rebuild
it from the documents alone? For the lab, the answer is yes, because `campus.sh` is the whole of it. For a
real network, the answer is the documentation.
