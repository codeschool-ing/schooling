---
title: Why write it down
version: 1
---

Most incidents are never written up, and the reason given is always time: the fault is fixed, the users
are working again, and there is other work waiting. That reasoning treats the record as a report on this
incident. **The record is for the next one**, which will look different on the surface, be the same
underneath, and arrive when the person who fixed this one is away.

Lesson 21's black hole is exactly the kind of fault that comes back. Nothing in it is exotic: a rule
written to harden a router, a tunnel whose MTU is smaller than the office network's, and TCP connections
that assume 1500 bytes. **Every tunnel added to that router later meets the same rule**, whether it is a
second branch or a VPN for people working from home. Whoever is on call then hears "the page opens, the
download hangs" and, with nothing written down, starts again from the cable.

With a record, the second search is a text search. "Download hangs", "small page works" and "tunnel"
find the write-up, and the write-up says what to run: a Don't Fragment ping at the tunnel's MTU, a look
for a rule dropping destination unreachable, and MSS clamping as the fix. **The second person starts from
the answer**, and the only thing they have to establish is whether this is the same fault.

The record has other readers too, and each needs something different from it:

| reader | what they need from the record |
|---|---|
| whoever is on call next time | the symptom in words they will search for, and the test that settled it |
| whoever changes the firewall | why the rule matters, and what else depends on the message it drops |
| whoever reviews changes | the argument for a test that would have caught this before it shipped |
| the people who were affected | that the cause was understood, and not only that the fault went away |

**A record written a week later is fiction with good intentions.** Memory puts events in a tidier order
than they happened, drops the tests that went nowhere, and gives the one that worked more credit than it
earned. So the record starts during the incident, as notes with the time beside each one, and is tidied
afterwards. The notes are the evidence and the write-up is the argument built on them.

Writing also improves the diagnosis while it is happening. A hypothesis you have to write down has to be
specific enough to test, and "something is wrong with the VPN" does not survive being written next to a
column headed "test". Lesson 21's method, one hypothesis at a time, and this lesson's record are the
same discipline seen from two sides.
