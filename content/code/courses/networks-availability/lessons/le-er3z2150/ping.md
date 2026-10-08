---
title: What ping measures
version: 1
---

ping is the first tool anybody reaches for and the one most often read for more than it says. **It
measures one thing: whether an ICMP echo went to an address and came back, and how long the round trip
took**. It says nothing about a port, a program or bandwidth, and a machine whose firewall drops ICMP
answers nothing while serving web pages perfectly well. From the laptop to web1:

```
ana@laptop:~$ ping -c 4 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.679 ms
64 bytes from 192.0.2.21: icmp_seq=2 ttl=62 time=0.080 ms
64 bytes from 192.0.2.21: icmp_seq=3 ttl=62 time=0.105 ms
64 bytes from 192.0.2.21: icmp_seq=4 ttl=62 time=0.086 ms

--- 192.0.2.21 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3077ms
rtt min/avg/max/mdev = 0.080/0.237/0.679/0.255 ms
```

Four echoes, four replies. The first is the slowest, 0.679 ms against 0.080 to 0.105 for the other
three. The first packet of a conversation often waits while a machine on the way looks up a hardware
address, so read the rest and not the first. **None of these times belongs to a network.** The lab's
links have no delay, and every time printed here is one computer talking to itself. On a real line the
same output carries the distance and the queues, and `mdev`, the spread, is the number that says how
much the delay jumps about.

## How far away the answer came from

```
ana@laptop:~$ ping -c 1 192.168.10.1 | grep ttl; ping -c 1 192.0.2.21 | grep ttl
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.660 ms
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.381 ms
```

The TTL of a reply says how many routers it crossed. Linux starts it at 64, and each router that
forwards the packet takes one off. `hq` answers from next door with `ttl=64`; web1's reply arrives with
**`ttl=62`, two routers**, the ISP's and `hq`. Other systems start elsewhere, Windows at 128 and many
routers at 255, so TTL is a distance only when you know where it started.

## How big

```
ana@laptop:~$ ping -c 3 -q -i 0.2 -s 1400 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 1400(1428) bytes of data.

--- 192.0.2.21 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 407ms
rtt min/avg/max/mdev = 0.074/0.147/0.283/0.096 ms
```

`-s 1400` asks for 1400 bytes of data, and ping reports **1428 on the wire**: 8 bytes of ICMP header
and 20 of IP. Size is the test lesson 21 used to find its black hole. This path has no tunnel, and 1428
bytes cross. `-q` prints only the summary and `-i 0.2` sends five a second instead of one.

## How much is lost

The next run was staged. A rule on the ISP router drops **two packets in ten, at random**, of those it
forwards towards web2, `192.0.2.22`. On `isp`:

```sh
sudo nft add table ip faults
sudo nft add chain ip faults loss '{ type filter hook forward priority 0; }'
sudo nft add rule ip faults loss 'ip daddr 192.0.2.22 numgen random mod 10 < 2 drop'
```

Fifty pings, ten a second:

```
ana@laptop:~$ ping -c 50 -i 0.1 -q 192.0.2.22
PING 192.0.2.22 (192.0.2.22) 56(84) bytes of data.

--- 192.0.2.22 ping statistics ---
50 packets transmitted, 44 received, 12% packet loss, time 5095ms
rtt min/avg/max/mdev = 0.065/0.094/0.615/0.080 ms
```

Twelve per cent, not twenty. Nothing is wrong with ping; **a loss figure from a short run is a sample,
and fifty is short**. A few lines of Python say how far a run of pings can stray from the true rate,
using the binomial distribution: each ping is lost or not, with the same chance, independently.

```schooling-example
{"language": "python", "file": "spread.py", "parts": [{"code": "from math import comb"}, {"code": "def chance(n, p, k):\n    \"\"\"Probability that exactly k of n pings are lost, each with probability p.\"\"\"\n    return comb(n, k) * p**k * (1 - p) ** (n - k)", "note": "The chance of exactly k losses in n pings, when each is lost with probability p. `comb(n, k)` counts the ways of choosing which k were lost."}, {"code": "def spread(n, p):\n    \"\"\"The loss a run of n pings reports, from its 2.5th to its 97.5th percentile.\"\"\"\n    total, low, high = 0.0, None, None\n    for k in range(n + 1):\n        total += chance(n, p, k)\n        if low is None and total >= 0.025:\n            low = k\n        if high is None and total >= 0.975:\n            high = k\n    return low / n, high / n", "note": "Adds those chances up from zero losses upwards, and notes where the running total passes 2.5% and 97.5%. Between the two lie ninety-five runs in a hundred."}, {"code": "p = 0.2\nfor n in (20, 50, 1000):\n    low, high = spread(n, p)\n    print(f\"{n:5} pings, true loss {p:.0%}: reports {low:.0%} to {high:.0%}\")", "note": "The rate the ISP's rule drops, 20%, and three lengths of run: the 20 probes of the first mtr report, the 50 pings of the loss test, and a thousand."}, {"code": "print(f\"6 or fewer lost of 50: {sum(chance(50, p, k) for k in range(7)):.1%} of runs\")", "note": "And the question the capture raises: how often do 50 pings lose 6 or fewer, which is what 12% means, when the true rate is 20%?"}], "output": "   20 pings, true loss 20%: reports 5% to 40%\n   50 pings, true loss 20%: reports 10% to 32%\n 1000 pings, true loss 20%: reports 18% to 22%\n6 or fewer lost of 50: 10.3% of runs"}
```

With twenty per cent lost for real, fifty pings report anything from 10% to 32% in ninety-five runs out
of a hundred, and a result of 12% or less turns up in about one run in ten. **The 12% measured is inside
that range, and so is the 10% mtr reports for the same rule two sections on.** A thousand pings pin the
same rate between 18% and 22%. Before calling a link lossy, or calling it fixed, send enough packets for
the number to mean something.
