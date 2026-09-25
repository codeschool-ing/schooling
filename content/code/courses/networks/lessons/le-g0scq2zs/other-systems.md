---
title: The same ladder on Windows and macOS
version: 1
---

The method does not change with the system; the commands do:

```sh
ipconfig /all                              # Windows: addresses, gateway and DNS servers of every adapter
ping -n 2 www.example.com                  # Windows: -n counts, where Linux uses -c
tracert -d www.example.com                 # Windows' traceroute
pathping -n www.example.com                # Windows: a route, then loss per hop, like mtr
nslookup -type=mx example.net              # Windows: the same nslookup
Test-NetConnection www.example.com -Port 443   # Windows PowerShell: is the port reachable?
netstat -ano                               # Windows: connections and listening ports, with process ids
arp -a                                     # Windows: the neighbour table
ipconfig /flushdns                         # Windows: forget cached DNS answers
netstat -rn                                # macOS: the routing table
lsof -nP -iTCP -sTCP:LISTEN                # macOS: what is listening
```

**None of these were run for this lesson.** On Windows, `ipconfig /all` is step 1 and shows the
gateway and DNS servers in one screen. `tracert` and `pathping` are traceroute and a slower mtr, and
`Test-NetConnection` with `-Port` is step 5 in one line. `netstat -ano` is still Windows' `ss`, and its
last column, the process id, matches the *Details* tab of Task Manager. Windows keeps a DNS cache of its
own, and `ipconfig /flushdns` clears it after a DNS change.

A Mac has `ping`, `traceroute`, `dig`, `nslookup` and `tcpdump` in the Terminal. Wireshark exists for
all three, and opens the pcap files of section 10 wherever they were made.
