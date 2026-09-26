---
title: Test: one change, one result
version: 1
---

A name that a computer resolves on its own, without asking a DNS server, comes from `/etc/hosts`, the
networks course's lesson on names. So the hypothesis is specific: **`pc1`'s `/etc/hosts` has the wrong
address for `intranet`**. Look first, then change one thing:

```
ana@pc1:~$ grep -n intranet /etc/hosts
10:10.30.0.200 intranet
ana@pc1:~$ sudo sed -i 's/^10.30.0.200 intranet$/10.30.0.31 intranet/' /etc/hosts && grep -n intranet /etc/hosts
10:10.30.0.31 intranet
```

Line 10 says `10.30.0.200`, an address where nothing answers: the intranet lived there once, and
this line was never updated when it moved. The change replaces that one address with `10.30.0.31`, and
touches nothing else.

**One change** is the rule that makes a test worth running. Had the same step also restarted the
network and cleared the browser's cache, a working page afterwards would not say which of the three
fixed it, and the next time this happens nobody would know which one to do.
