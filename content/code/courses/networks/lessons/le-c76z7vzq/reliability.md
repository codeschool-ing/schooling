---
title: Losing packets and delivering anyway
version: 1
---

Acknowledgements are what let TCP promise delivery. When a segment is not acknowledged in time, the
sender sends it again. The kernel counts every retransmission, and `nstat` prints the counter. First
the price list from lesson 2, 186893 bytes, over a healthy network:

```
ana@www:~$ nstat -az TcpRetransSegs
#kernel
TcpRetransSegs                  0                  0.0
ana@laptop:~$ curl -sS -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://www.example.com/prices.txt
200 186893 bytes in 0.023639 s
ana@www:~$ nstat -az TcpRetransSegs
#kernel
TcpRetransSegs                  0                  0.0
```

No retransmissions, and 0.024 seconds. Then the office router is made to lose one in five of the
packets the web server sends, and the same file is fetched again:

```
ana@laptop:~$ curl -sS -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://www.example.com/prices.txt
200 186893 bytes in 1.048856 s
ana@www:~$ nstat -az TcpRetransSegs
#kernel
TcpRetransSegs                  46                 0.0
```

**All 186893 bytes arrived, and the program never knew anything went wrong.** The server had to send
46 segments a second time, and the download took 1.05 seconds instead of 0.024, more than forty
times as long. That is the trade TCP makes: it turns loss into delay.

That trade is the diagnostic lesson. **A network that loses packets looks slow, not broken**: pages
that load, eventually; a video call that stutters; a file copy far below the line's speed. When
something is slow and nothing is down, the loss counters are worth reading. `nstat` on Linux, and on
any system, `ping -c 100` to the far end: a few percent of lost pings is enough to make every TCP
connection over that path crawl.
