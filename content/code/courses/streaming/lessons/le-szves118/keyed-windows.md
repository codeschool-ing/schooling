---
title: Windows per key
version: 1
---

**In practice a window is almost never over the whole stream: it is per key, so every shop, or
customer, or book, has its own set of windows.** "Sales per five minutes" is a dashboard nobody
reads; "sales per five minutes per shop" is the one the area manager opens.

Keyed windows are the same rule applied separately inside each key. A tumbling window per shop
has the same edges for every shop, because the edges come from the clock:

```
ubuntu@stream:~/work$ python windows.py tumbling 5 --by-shop
```

The ten sales are now spread across nine rows. Recife has a sale in four different windows and
Caruaru in one. Natal's 09:05 to 09:10 window holds two sales, 5 and 8, and is the only one with
more than one; the late sale 8 landed in Natal's window and nobody else's. **The total over all
the keys is still ten**, because tumbling windows do not overlap whether keyed or not.

For sessions the key changes the answer more, because a session per shop is made only of that
shop's sales:

```
ubuntu@stream:~/work$ python windows.py session 5 --by-shop
```

Seven sessions instead of two, and no merge. Sale 8 joined two sessions of the whole stream, but
within Natal it is simply the third of three sales less than five minutes apart. Recife's first
two sales, 09:00:40 and 09:05:00, are 4 minutes 20 seconds apart and share a session; its 09:13:05
sale is eight minutes later and starts another. A session per key is what "a visit" really means,
since one customer's visit says nothing about another's.

## Where the key comes from

Kafka already has the answer. The sales are keyed by shop when they are produced, which lesson 3
showed sends every sale of one shop to the same partition. That is what makes keyed windows cheap
to run in parallel: **all the events of one key are in one partition, so one worker holds all of
that key's windows**, and no other worker ever needs to see them. A window keyed by something
that is not the message key, books for instance when the sales are keyed by shop, needs the
stream re-sorted by the new key first. Kafka Streams does it with a repartition topic, which
lesson 13 lists among the topics an application creates for itself.

## The state it keeps

Every open window per key is state that the engine keeps until the window is finished. Five shops
and five-minute windows is a handful of counters. A million customers with thirty-minute sessions
is a million entries, which is why engines put window state in an embedded store on disk rather
than in memory, and why lesson 13 spends a section on where that state lives when a worker dies.
The number to estimate before choosing a window is **keys × windows open per key**, and both
factors come from the choices in this lesson.
