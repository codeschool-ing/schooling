---
title: Capturing with tcpdump
version: 1
---

Something to download first: a price list of 3,000 lines, made by a shell loop, served by the same small Python web
server lesson 13 used, this time from a folder of its own:

```
root@soc:~# mkdir www; for i in $(seq 1 3000); do echo "item-$i,$((i * 37 % 900)).90"; done > www/price-list.csv
root@soc:~# ls -l www
total 52
-rw-r--r-- 1 root root 49524 Oct  7 21:10 price-list.csv
root@soc:~# ip netns exec outside python3 -m http.server 8080 --directory www >/dev/null 2>&1 &
```

Now the capture. `tcpdump` runs on `fw`, on `eth0`, its internet side; `-w` writes the raw packets to a file
instead of printing them; and the last words are a **capture filter**, `host 192.168.20.10`, so only packets to or
from `files` are kept. While it runs, `files` downloads the list:

```
root@soc:~# ip netns exec fw tcpdump -i eth0 -w web.pcap host 192.168.20.10 2>tcpdump.err &
root@soc:~# ip netns exec files curl -s -o /dev/null -w "%{http_code} %{size_download}\n" http://203.0.113.200:8080/price-list.csv
200 49524
root@soc:~# pkill -x tcpdump; sleep 1; cat tcpdump.err
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20 packets captured
20 packets received by filter
0 packets dropped by kernel
root@soc:~# install -o ana -m 600 web.pcap /home/ana/
```

`curl` reports a `200` and 49,524 bytes, the size of the file. `pkill -x tcpdump` stops the capture; `-x` matches
the process name exactly, so nothing else with "tcpdump" in its command line is touched. tcpdump's own summary
says **20 packets captured** and **0 dropped by the kernel**: that last number is worth reading every time, because
a capture that dropped packets is missing part of the conversation, and the gap is invisible later.

The capture filter is written in **BPF** (Berkeley Packet Filter) syntax, the same one used by every tool built on
`libpcap`: `host`, `net 192.168.20.0/24`, `port 443`, `tcp`, combined with `and`, `or` and `not`. It decides what
is **kept**. Anything it leaves out was never recorded, so on a real incident the filter is kept wide.

The last line copies the file to ana. Capturing needs root, because it reads the network card directly; reading
a capture file does not, and analysis is better done without root, so that a mistake in a command cannot damage
the system.
