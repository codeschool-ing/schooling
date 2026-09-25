---
title: traceroute: the hops on the way
version: 1
---

`ping` says whether the far end answers. `traceroute` says which routers the packets pass on the way,
by sending probes with a TTL of 1, then 2, then 3, and listening for the routers that discard them:

```
ana@laptop:~$ traceroute -n www.example.com
traceroute to www.example.com (192.0.2.80), 30 hops max, 60 byte packets
 1  192.168.10.1  0.039 ms  0.012 ms  0.011 ms
 2  203.0.113.1  0.349 ms  0.017 ms  0.277 ms
 3  198.51.100.254  0.482 ms  0.090 ms  0.099 ms
 4  192.0.2.80  0.098 ms  0.012 ms  0.114 ms
```

Four hops: the office router, the ISP, the core router, and `www` itself. That is lesson 2's journey
seen from the command line, and each line has three times because traceroute sends three probes per
hop. **Where a path stops matters more than the times.** A traceroute that ends in lines of `* * *` at
the same hop every time says one of two things. Either the packets go no further than the router before
it, or everything past it declines to answer, and the next section tells the two apart.

`-n` skips looking up names for each address, which is quicker, and the only choice when DNS is the
thing that is broken.
