---
title: Between strong and eventual
version: 1
---

**"Consistent" is not one setting with two positions; it is a ladder of promises, and most real
systems stand on a rung between the top and the bottom.** The wrong picture is a switch marked
*strong* and *eventual*. It hides the rungs that matter most to a person using an app, which are
promises about what **one** reader sees rather than about the whole system.

## Four rungs worth recognising

From the strongest promise at the top to the weakest at the bottom. The two in the middle are not
above one another; each rules out a different surprise.

| model | the promise | at Roda Livre, it rules out |
|---|---|---|
| **strong** (linearisable) | every read sees the latest completed write, as though there were one copy | any reader seeing 7 at Rua XV after another reader was told 5 |
| **read-your-writes** | after you write, your own reads see that write; other people may not yet | ana returning a bicycle and the app still showing her ride as open |
| **monotonic reads** | once you have seen a value, you never afterwards see an older one | the map showing 5, then 6, then 5 again as each refresh lands on a different copy |
| **eventual** | if writes stop, every copy ends up with the same value | nothing about what anybody reads in the meantime, or how long it lasts |

The middle two are called **session guarantees**, because they are promises to one session — one
phone, one connection — and not to everybody. They are much cheaper than strong consistency. A
system can give read-your-writes by sending a person's reads to the copy that took their write, or
by making a read wait until its copy has caught up with that write. Nobody else has to wait.

## Eventual is a weaker promise than it sounds

"Eventually consistent" is often heard as "consistent, a moment later". It says less. It promises
that the copies **converge if writes stop**; it does not say when, and it says nothing about what a
reader sees on the way. Lesson 9's stale read, from a follower that had not caught up yet, was
eventual consistency working as specified.

What makes an eventually consistent system pleasant to use is usually the session guarantees laid
on top of it. **A customer does not notice that two copies disagree; she notices when her own
action seems to have been undone.** That is the failure read-your-writes prevents, and the reason
it is the first rung a product team asks for.

## Where this goes next

These four are enough to recognise the words in a database's documentation and to ask which one an
operation gives. There are more rungs — *causal* consistency, where an effect is never seen before
its cause, is the next one people meet — and choosing among them for a real system is the ground
of `nosql-operations` and `architecture`.
