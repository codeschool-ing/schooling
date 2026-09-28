---
title: The active balancer dies
version: 1
---

To see what the site's users see, the laptop asks for the page thirty times in a row, printing the time
to the millisecond before each request. `curl -m 1` gives each request one second at most, and a request
that fails prints `(no answer)`. A little over two seconds in, HAProxy on `lb1` was killed outright, the way a crash
or an out-of-memory kill would end it:

```
ana@laptop:~$ for i in $(seq 1 30); do printf "%s " $(date +%T.%N | cut -c1-12); curl -s -m 1 http://www.example.com/ || echo "(no answer)"; sleep 0.2; done
18:11:44.583 served by web1
18:11:44.795 served by web2
18:11:45.007 served by web3
18:11:45.219 served by web1
18:11:45.430 served by web2
18:11:45.643 served by web3
18:11:45.855 served by web1
18:11:46.067 served by web2
18:11:46.279 served by web3
18:11:46.491 served by web1
18:11:46.703 served by web2
18:11:46.916 served by web3
18:11:47.128 (no answer)
18:11:47.341 (no answer)
18:11:47.552 (no answer)
18:11:47.764 (no answer)
18:11:47.975 (no answer)
18:11:48.186 (no answer)
18:11:48.397 (no answer)
18:11:49.610 served by web1
18:11:49.825 served by web2
18:11:50.037 served by web3
18:11:50.250 served by web1
18:11:50.463 served by web2
18:11:50.677 served by web3
18:11:50.889 served by web1
18:11:51.101 served by web2
18:11:51.314 served by web3
18:11:51.526 served by web1
18:11:51.739 served by web2
ana@lb1:~$ grep -E "haproxy_alive|Entering" /run/keepalived.log | tail -n 3
Mon Sep 28 18:11:47 2026: Script `haproxy_alive` now returning 7
Mon Sep 28 18:11:48 2026: VRRP_Script(haproxy_alive) failed (exited with status 7)
Mon Sep 28 18:11:48 2026: (www_a) Entering FAULT STATE
ana@lb2:~$ ip -br addr show eth0
eth0@if1316      UP             192.0.2.12/24 192.0.2.80/24 
```

The last answer before the failure left at **18:11:46.916**, and the first one after it at
**18:11:49.610**. **The site gave no answer for 2.694 seconds**, seven requests in a row. The timestamps
say more than the count does, because they show two different kinds of failure.

The first six failures are 0.21 seconds apart, the loop's own `sleep 0.2` and almost nothing else: each
request failed at once. `lb1` still held `192.0.2.80`, and with HAProxy dead nothing listened on port
80, so each connection was refused on the spot. The seventh started at 18:11:48.397, and the next line
is 1.213 seconds later: **that request waited out its whole one-second limit**, because it was sent while
the address was moving and nobody answered it at all.

keepalived's log on `lb1` shows its half. At 18:11:47 the check started failing with exit status 7, which
is `curl`'s code for "could not connect". At 18:11:48 it had failed twice in a row, `fall 2`, and the
instance went to `FAULT`. And `lb2` now holds `192.0.2.80`.

## Faster than lesson 15, and why

The gateway failover of lesson 15 left a gap of 3.264 seconds; this one is 2.694, with the same
one-second advertisements. The difference is who noticed. In lesson 15 the master's cable was pulled, so
it went silent, and the backup had to wait out its master down interval of silence. Here the master
itself found out first, through its own script, and **a master that gives up the address says so**: VRRP
defines an advertisement with priority 0 as "I am leaving, take over now", and a backup that hears one
waits only its short skew instead of three seconds of silence. That last packet is not in the capture,
but the times leave no room for anything else: `lb1` went to `FAULT` at 18:11:48, and `lb2` was serving
by 18:11:49.610, well before 3.61 seconds of silence could have run out.

So the 2.694 seconds are made of detection, not of the switch. **Two failed checks at one a second is
about two seconds of the gap**, and the rest is the move. Checking every 200 milliseconds would shrink
it, and lesson 14 said what that costs on a busy machine: a check that times out because the machine is
loaded looks exactly like one that failed because it is dead.

Nothing a user had in progress on `lb1` survived. A download half finished, a request sent a millisecond
before the kill: those connections belonged to a process that no longer exists, and `lb2` has never heard
of them. **The address moves; the connections through it do not.** The last section of this lesson
comes back to that.
