---
title: Which cable a frame takes
version: 1
---

The natural guess is that a LAG deals frames out in turn, one down each cable, like cards. **It does
not, and it must not**: two frames of one conversation sent down two cables can arrive in the wrong
order, and TCP treats frames out of order as a sign of loss and slows down. So a LAG picks the
cable per conversation, by computing a **hash** of some addresses in the frame and using the
result to choose a member. The same addresses always give the same result, so **every frame of one
conversation takes the same cable**, and different conversations land on different cables, more or
less evenly.

## Counting frames on each cable

Here are the transmit counters of `sw1`'s two members, then 50 pings from `pc1` to each of the three
PCs on `sw2`, then the counters again:

```
root@sw1:~# ip -s link show e1 | sed -n "5,6p"; ip -s link show e2 | sed -n "5,6p"
    TX:  bytes packets errors dropped carrier collsns           
          2768      25      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          3056      29      0       1       0       0 
ana@pc1:~$ for h in 22 23 24; do ping -c 50 -i 0.2 -q 10.20.10.$h | grep transmitted; done
50 packets transmitted, 50 received, 0% packet loss, time 9876ms
50 packets transmitted, 50 received, 0% packet loss, time 9897ms
50 packets transmitted, 50 received, 0% packet loss, time 9884ms
root@sw1:~# ip -s link show e1 | sed -n "5,6p"; ip -s link show e2 | sed -n "5,6p"
    TX:  bytes packets errors dropped carrier collsns           
         16496     158      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
         12136     116      0       1       0       0 
root@sw1:~# cat /sys/class/net/bond0/bonding/xmit_hash_policy
layer2+3 2
```

`e1` went from 25 frames sent to 158, and `e2` from 29 to 116. **Both cables carried traffic, and
neither carried all of it.** These counters are `sw1`'s transmit side, so they hold the echo
requests on their way from `pc1` to `sw2`; the replies come back over whichever cable `sw2`'s own
hash picks, and `sw2`'s counters would show those. Each end of a LAG chooses for the frames it sends.

The two increases, 133 and 87, add up to 220, more than the 150 echo requests. **The rest is not
the pings.** With `lacp_rate fast`, each member also carries a LACPDU every second, and the three
runs took about 30 seconds between them (`time 9876ms`, `9897ms`, `9884ms`). A handful of other
frames, such as `pc1` resolving the three PCs' MAC addresses, are in there too. What the counters
cannot tell you is which PC's pings went down which cable, so this capture does not show the split
per conversation; it shows that there was one. The single `dropped` on `e2` was there before the test
and did not move.

## The policy decides what goes into the hash

The bond was created with `xmit_hash_policy layer2+3`, and the last command reads it back. Linux
offers several policies, and a switch has the same choice under its own names:

| policy | hashed from | what it means for the spread |
| --- | --- | --- |
| `layer2` | source and destination MAC | all traffic between two machines on one cable, so traffic between two routers, whose MACs do not change, piles onto one member |
| `layer2+3` | MACs and IP addresses | different IP pairs spread out, even through a router |
| `layer3+4` | IP addresses and ports | two connections between the same two machines can take different cables |

**Whatever the policy, one conversation never goes faster than one cable.** A backup copying one
file over one TCP connection between two servers joined by a LAG of two 10 Gb/s members gets at
most 10 Gb/s, and `layer3+4` does not change that: it spreads *connections*, and there is only one.
What a LAG raises is the total for many conversations at once, which is exactly the traffic an uplink
between two switches carries.

And spread is a matter of luck with few conversations. Three destinations and two cables cannot
divide evenly; with three hundred, the hash divides them close to evenly. The more different
conversations cross a LAG, the closer it gets to using both cables fully.
