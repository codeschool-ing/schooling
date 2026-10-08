---
title: The cable and the gateway
version: 1
---

## No carrier

The laptop cannot reach its own gateway, the first address anybody tries. The ping says nothing useful,
so the next two commands ask the interface instead. Each fault in this lesson can be staged on your own
network, and each section says how before the transcript; reading the transcript first and guessing is
the better exercise. This one is staged on the virtual machine with
`sudo ip -n wire link set hq-laptop down`:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1004ms

ana@laptop:~$ ip -br link show eth0
eth0@if1464      DOWN           52:54:00:a8:0a:14 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
ana@laptop:~$ sudo ethtool eth0 | grep "Link detected"
	Link detected: no
```

Two pings out, none back, and **no error message at all**: ping cannot tell a dead cable from a machine
that chooses not to answer. The interface can. `DOWN` is the state of the link and `NO-CARRIER` is the
reason: the network card hears nothing from the other end. The `UP` inside the brackets is not a
contradiction. It says the interface is switched on in software, which it is; **what is missing is the
signal**, which `LOWER_UP` would report and does not. `ethtool` says the same in plain words, `Link
detected: no`.

On real hardware that is a cable pulled out or broken, a switch port disabled, or a switch with no
power. This network has no copper. The laptop's cable is a pair of virtual interfaces, and the fault was
staged by setting the switch's end of the pair down, which the laptop sees as a cable that carries
nothing. With that end set up again, `sudo ip -n wire link set hq-laptop up`, the same two commands:

```
ana@laptop:~$ ip -br link show eth0; sudo ethtool eth0 | grep "Link detected"
eth0@if1464      UP             52:54:00:a8:0a:14 <BROADCAST,MULTICAST,UP,LOWER_UP> 
	Link detected: yes
```

`LOWER_UP` is back and the link is detected. **Layer 1 is checked by looking, not by pinging**: `ip link`
answers at once, and a ping that fails could be failing at any layer from the cable up.

## A gateway nobody has

The next fault starts from a report that the web servers are down. It is staged on `laptop` with
`sudo ip route replace default via 192.168.10.99`. From the laptop, to web1's address:

```
ana@laptop:~$ curl -sS -m 5 http://192.0.2.21/
curl: (7) Failed to connect to 192.0.2.21 port 80 after 3057 ms: Couldn't connect to server
ana@laptop:~$ ip route
default via 192.168.10.99 dev eth0 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
```

`Couldn't connect to server` after **3057 ms**. The routing table shows why, to anybody who knows the
office: the default route points at `192.168.10.99`, and the office router is `192.168.10.1`. Everything
outside `192.168.10.0/24` is being sent to an address where nothing lives.

The three seconds are a clue in their own right. To hand a packet to a gateway, the laptop first needs
the gateway's hardware address, so it asks for it with ARP. Linux asks three times, a second apart, and
then tells the program that the destination cannot be reached. The neighbour table keeps the question
that was never answered:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.10.99
PING 192.168.10.99 (192.168.10.99) 56(84) bytes of data.

--- 192.168.10.99 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1007ms

ana@laptop:~$ ip neigh show 192.168.10.99
192.168.10.99 dev eth0 INCOMPLETE 
ana@laptop:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=64 time=0.272 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.272/0.272/0.272/0.000 ms
```

`INCOMPLETE` means an ARP request went out and no reply came back. **The last ping is the test that
clears the rest of the laptop.** `files`, on the same network, answers in 0.272 ms, so the cable, the
card and the laptop's own address are all fine. Only what has to go through the gateway fails, and the
gateway is the one thing wrong. With the route put back to `192.168.10.1`, `sudo ip route replace default via 192.168.10.1`, web1
answers:

```
ana@laptop:~$ ping -c 1 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.360 ms

--- 192.0.2.21 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.360/0.360/0.360/0.000 ms
```

`ttl=62` means two routers between the laptop and the data centre, `hq` and the ISP's, which lesson 22
reads more closely. **A wrong gateway is rarely typed by hand**. It arrives from a DHCP server with a
wrong option, or with a router replaced by one on a different address, and from the laptop it looks
exactly like this: the local network works and nothing beyond it does.
