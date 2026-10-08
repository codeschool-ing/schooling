---
title: One login, four records
version: 1
---

Time to make some evidence. `ana` needs a key to log in with; she makes one on `soc` and authorises it
for her own account:

```
ana@soc:~$ ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
ana@soc:~$ cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
```

The lab's machines share this computer's disk and its accounts, which a real network would not do, so
that one key works on `gw` too. Then she logs in to `gw` as somebody on the internet would: the command
runs inside `outside`, as `ana`, and asks `gw` for its name. While it ran, `tcpdump` was recording the
internet side of `fw` into `one.pcap`; the lab's root started it beforehand with
`ip netns exec fw tcpdump -U -i eth0 -w one.pcap tcp port 22 &` and stopped it afterwards.

```
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o StrictHostKeyChecking=accept-new ana@198.51.100.22 hostname
Warning: Permanently added '198.51.100.22' (ED25519) to the list of known hosts.
gw
```

That one login is now in four places. First, the **host's own log**, written by `sshd` on `gw`:

```
root@soc:~# cat /var/log/soclab/gw-auth.log
2026-10-07T04:42:14-0300 gw sshd: Server listening on 198.51.100.22 port 22.
2026-10-07T04:42:17-0300 gw sshd: Accepted publickey for ana from 203.0.113.66 port 32888 ssh2: ED25519 SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo
2026-10-07T04:42:17-0300 gw sshd: Received disconnect from 203.0.113.66 port 32888:11: disconnected by user
2026-10-07T04:42:17-0300 gw sshd: Disconnected from user ana 203.0.113.66 port 32888
```

It names the account, the method (`publickey`), the key's fingerprint and the address and port the
connection came from. Second, the **firewall**, which logged the first packet of the new connection as it
forwarded it:

```
root@soc:~# cat /var/log/soclab/fw.log
Oct  7 04:42:16 fw fw-new  IN=eth0 OUT=eth1 MAC=aa:5c:27:7d:a1:33:f6:71:10:e6:3b:46:08:00 SRC=203.0.113.66 DST=198.51.100.22 LEN=60 TOS=10 PREC=0x00 TTL=63 ID=60875 DF PROTO=TCP SPT=32888 DPT=22 SEQ=2902218005 ACK=0 WINDOW=64240 SYN URGP=0 MARK=0x0 
```

No account, no outcome; but the interfaces it came in and went out of, and the same source port, `32888`.
Notice also that this line has **no year**: it is the old syslog time format, and lesson 2 comes back to
why that matters. Third, the **flow records**, one per direction, that `nfpcapd` wrote once the
conversation had been quiet for fifteen seconds:

```
root@soc:~# nfdump -R /var/log/soclab/flows -o line 'port 22'
Date first seen             Duration     Proto      Src IP Addr:Port          Dst IP Addr:Port   Packets    Bytes Flows
2026-10-07 04:42:16.864     00:00:00.235 TCP      198.51.100.22:22    ->     203.0.113.66:32888       19     5335     1
2026-10-07 04:42:16.864     00:00:00.236 TCP       203.0.113.66:32888 ->    198.51.100.22:22          23     4983     1
Summary: total flows: 2, total bytes: 10318, total packets: 42, avg bps: 349762, avg pps: 177, avg bpp: 245
Time window: 2026-10-07 04:42:00 - 2026-10-07 04:43:00
Total flows processed: 2, passed: 2, Blocks skipped: 0, Bytes read: 152
Sys: 0.0032s User: 0.0032s Wall: 0.0008s flows/second: 2567.7 Runtime: 0.0008s
```

They add what neither log knew: it lasted about a quarter of a second and moved 42 packets, 10,318 bytes
in both directions together. Fourth, the **packets** themselves:

```
root@soc:~# tcpdump -nr one.pcap | head -4
reading from file one.pcap, link-type EN10MB (Ethernet), snapshot length 262144
04:42:16.864001 IP 203.0.113.66.32888 > 198.51.100.22.22: Flags [S], seq 2902218005, win 64240, options [mss 1460,sackOK,TS val 1740162962 ecr 0,nop,wscale 10], length 0
04:42:16.864271 IP 198.51.100.22.22 > 203.0.113.66.32888: Flags [S.], seq 21022093, ack 2902218006, win 65160, options [mss 1460,sackOK,TS val 2755791624 ecr 1740162962,nop,wscale 10], length 0
04:42:16.864285 IP 203.0.113.66.32888 > 198.51.100.22.22: Flags [.], ack 1, win 63, options [nop,nop,TS val 1740162963 ecr 2755791624], length 0
04:42:16.864519 IP 203.0.113.66.32888 > 198.51.100.22.22: Flags [P.], seq 1:44, ack 1, win 63, options [nop,nop,TS val 1740162963 ecr 2755791624], length 43: SSH: SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.19
root@soc:~# tcpdump -nr one.pcap | wc -l
reading from file one.pcap, link-type EN10MB (Ethernet), snapshot length 262144
42
```

The same 42 packets, the same port, and, in the fourth, something no other record holds: the version of
the SSH client, which `outside` announced in clear text before encryption started. Everything after that
packet is encrypted and the capture shows only its size.

**The source port is what ties the four together.** The time stamps do not even agree on the second:
`sshd`'s line says `04:42:17`, stamped by `ts` when the line was written, while the first packet arrived
at `04:42:16.864001`, stamped to the microsecond. Two clocks, two precisions; joining on time alone is how an analyst attaches the
wrong login to the wrong connection.

And the cost, measured on this one login:

```
root@soc:~# wc -c /var/log/soclab/gw-auth.log /var/log/soclab/fw.log one.pcap
  425 /var/log/soclab/gw-auth.log
  250 /var/log/soclab/fw.log
11602 one.pcap
12277 total
```

The firewall needed **250 bytes** to say that the connection happened, and the capture **11,602** to
replay it. Keep a year of the first on a small disk; a year of the second for a busy network is a storage
project. That ratio is the reason lesson 3 talks about retention before anything else.
