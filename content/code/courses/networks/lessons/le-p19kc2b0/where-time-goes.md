---
title: Where the time went
version: 1
---

When a page is slow, the first question is which layer is slow, and `curl -w` answers it. It prints
timers at the end of each stage:

```
ana@laptop:~$ curl -so /dev/null -w 'dns        %{time_namelookup}\ntcp        %{time_connect}\ntls        %{time_appconnect}\nfirst byte %{time_starttransfer}\ntotal      %{time_total}\n' https://www.example.com/prices.txt
dns        0.000920
tcp        0.001154
tls        0.018201
first byte 0.018616
total      0.019066
```

**Each number is the time since the start, not the length of the stage**, so the stages are the
differences:

| stage | from | to | took |
|---|---|---|---|
| DNS | 0 | 0.000920 | under a millisecond |
| TCP handshake | 0.000920 | 0.001154 | a fraction of a millisecond |
| TLS handshake | 0.001154 | 0.018201 | about 17 milliseconds |
| server's first byte | 0.018201 | 0.018616 | under a millisecond |
| the rest of the file | 0.018616 | 0.019066 | under a millisecond |

In the lab, where the network takes no time, the TLS handshake dominates: that is the cryptography
itself, running on one computer for both ends. On a real connection each stage has its own suspect.
**A slow `dns` is the resolver. A slow `tcp` is distance or loss. A slow `tls` is distance again**,
since the handshake needs a round trip, or an overloaded server. **A slow first byte, after everything
else was quick, is the application** thinking, and no amount of network work will change it.
