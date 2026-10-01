---
title: "Port security: who may plug in"
version: 1
---

A switch, as the previous sections built it, trusts every frame. It learns any source address that
arrives, on any port, and forwards for anybody. That is what makes it work without configuration,
and it is also two problems. **Anybody who finds a free socket is on the network**, the moment a
cable goes in. And **the table can be filled on purpose**: a device that sends frames from a great
many made-up source addresses fills the switch's finite table. The real machines' entries age out
or never get in, and the switch floods their traffic to every port, including the one the device
is on. A switch that has lost its table behaves like the hub of lesson 1, with every conversation
on every cable.

**Port security** is the general name for the defence: limiting, per port, which source addresses
the switch accepts. Vendors implement it with their own commands; the idea is the same everywhere.

## A locked port in the lab

Linux bridges can lock a port. A **locked** port forwards only frames whose source address is
already in the table as an entry for that port, and with **learning off** the switch adds nothing
to the table by itself, so only what an administrator enters gets through. Here p3, pc3's port, is
locked and the table has nothing for it:

```
root@sw1:~# bridge link set dev p3 locked on learning off
root@sw1:~# bridge fdb show br br0 dynamic | grep "dev p3 "
ana@pc3:~$ ping -c 2 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1060ms

```

**pc3 is refused: 2 transmitted, 0 received.** Its cable is fine and its address is right, but
its frames come from a source the switch was not told about, so they go no further than p3. Now the
administrator enters pc3's address as a static entry on that port, and pc3 tries again:

```
root@sw1:~# bridge fdb add 02:d9:6b:02:17:20 dev p3 master static
ana@pc3:~$ ping -c 2 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.826/1.454/2.083/0.628 ms
```

**2 received.** The entry says that `02:d9:6b:02:17:20` belongs on p3, and frames from it are let
through. A static entry does not age, so it stays until somebody removes it.

## What a MAC address proves

The next command is what makes the limit of this defence plain. pc3 changes its own MAC address, as
any machine whose owner controls it can, and tries a third time:

```
root@pc3:~# ip link set eth0 address 02:00:00:00:00:66
ana@pc3:~$ ping -c 2 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1037ms

root@sw1:~# bridge -d link show dev p3 | grep -oE "(learning|locked) [a-z]*"
learning off
locked on
```

**Refused again**, because the new source, `02:00:00:00:00:66`, is not the one entered for p3. The
last command confirms the port's state: `learning off`, `locked on`.

That run shows both sides of it. **A locked port stops a device nobody registered**, a visitor's
laptop in a meeting room or a switch somebody brought from home, and it stops a flood of made-up
addresses, because none of them is ever learnt. It does **not** prove who is plugged in: lesson 2
showed that a MAC address is set by software, and a device that presented the registered address
would be let through. It also refuses honest changes. A phone that picks a new random address per
network, lesson 2 again, is refused exactly like the stranger.

## Stronger, and more usual

Real switches offer variations of the same idea: a maximum number of addresses per port, addresses
learnt once and then held, and a choice of what to do on a violation, from dropping the frames to
shutting the port down and raising an alarm. Alongside them:

- **Ports with nothing behind them are disabled**, so a free socket is not an open one.
- **IEEE 802.1X** replaces "which address are you?" with "prove who you are": the port carries no
  traffic except the authentication exchange until the device presents credentials, which the
  switch checks with an authentication server, and then it opens. It is the stronger version of
  everything in this section, and it is what large networks use where anybody can reach a socket.
- **Watching the table.** A port on which hundreds of new addresses appear in a minute is either a
  misconfigured device or an attack, and either way it is worth an alarm.
