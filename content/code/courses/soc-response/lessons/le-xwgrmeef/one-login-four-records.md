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
2026-10-07T04:24:40-0300 gw sshd: Server listening on 198.51.100.22 port 22.
2026-10-07T04:24:43-0300 gw sshd: Accepted publickey for ana from 203.0.113.66 port 33586 ssh2: ED25519 SHA256:wH5OyvHWekSstXkiQV4wCGLaBYWHvDNfxKaFcEdIdKs
2026-10-07T04:24:43-0300 gw sshd: Received disconnect from 203.0.113.66 port 33586:11: disconnected by user
2026-10-07T04:24:43-0300 gw sshd: Disconnected from user ana 203.0.113.66 port 33586
```

It names the account, the method (`publickey`), the key's fingerprint and the address and port the
connection came from. Second, the **firewall**, which logged the first packet of the new connection as it
forwarded it:

```
root@soc:~# cat /var/log/soclab/fw.log
Oct  7 04:24:43 fw fw-new  IN=eth0 OUT=eth1 MAC=d6:32:9e:91:b7:8a:4e:52:5a:70:5f:25:08:00 SRC=203.0.113.66 DST=198.51.100.22 LEN=60 TOS=10 PREC=0x00 TTL=63 ID=32724 DF PROTO=TCP SPT=33586 DPT=22 SEQ=1796475749 ACK=0 WINDOW=64240 SYN URGP=0 MARK=0x0 
```

No account, no outcome; but the interfaces it came in and went out of, and the same source port, `33586`.
Notice also that this line has **no year**: it is the old syslog time format, and lesson 2 comes back to
why that matters. Third, the **flow records**, one per direction, that `nfpcapd` wrote once the
conversation had been quiet for fifteen seconds:

```
root@soc:~# nfdump -R /var/log/soclab/flows -o line 'port 22'
Date first seen             Duration     Proto      Src IP Addr:Port          Dst IP Addr:Port   Packets    Bytes Flows
2026-10-07 04:24:43.017     00:00:00.238 TCP      198.51.100.22:22    ->     203.0.113.66:33586       19     5387     1
2026-10-07 04:24:43.017     00:00:00.238 TCP       203.0.113.66:33586 ->    198.51.100.22:22          22     4895     1
Summary: total flows: 2, total bytes: 10282, total packets: 41, avg bps: 345613, avg pps: 172, avg bpp: 250
Time window: 2026-10-07 04:24:00 - 2026-10-07 04:25:00
Total flows processed: 2, passed: 2, Blocks skipped: 0, Bytes read: 152
Sys: 0.0000s User: 0.0054s Wall: 0.0006s flows/second: 3159.6 Runtime: 0.0006s
```

They add what neither log knew: it lasted 0.238 seconds and moved 41 packets, 10,282 bytes in both
directions together. Fourth, the **packets** themselves:

```
root@soc:~# tcpdump -nr one.pcap | head -4
reading from file one.pcap, link-type EN10MB (Ethernet), snapshot length 262144
04:24:43.017414 IP 203.0.113.66.33586 > 198.51.100.22.22: Flags [S], seq 1796475749, win 64240, options [mss 1460,sackOK,TS val 336062012 ecr 0,nop,wscale 10], length 0
04:24:43.017652 IP 198.51.100.22.22 > 203.0.113.66.33586: Flags [S.], seq 3384481466, ack 1796475750, win 65160, options [mss 1460,sackOK,TS val 2225653318 ecr 336062012,nop,wscale 10], length 0
04:24:43.017662 IP 203.0.113.66.33586 > 198.51.100.22.22: Flags [.], ack 1, win 63, options [nop,nop,TS val 336062012 ecr 2225653318], length 0
04:24:43.017896 IP 203.0.113.66.33586 > 198.51.100.22.22: Flags [P.], seq 1:44, ack 1, win 63, options [nop,nop,TS val 336062012 ecr 2225653318], length 43: SSH: SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.19
root@soc:~# tcpdump -nr one.pcap | wc -l
reading from file one.pcap, link-type EN10MB (Ethernet), snapshot length 262144
41
```

The same 41 packets, the same port, and, in the fourth, something no other record holds: the version of
the SSH client, which `outside` announced in clear text before encryption started. Everything after that
packet is encrypted and the capture shows only its size.

**The source port is what ties the four together.** The time stamps nearly agree, but `sshd`'s line is
stamped to the second by `ts` when it was written, while the capture is stamped to the microsecond when
the packet arrived. Two clocks, two precisions; joining on time alone is how an analyst attaches the
wrong login to the wrong connection.

And the cost, measured on this one login:

```
root@soc:~# wc -c /var/log/soclab/gw-auth.log /var/log/soclab/fw.log one.pcap
  429 /var/log/soclab/gw-auth.log
  250 /var/log/soclab/fw.log
11536 one.pcap
12215 total
```

The firewall needed **250 bytes** to say that the connection happened, and the capture **11,536** to
replay it. Keep a year of the first on a small disk; a year of the second for a busy network is a storage
project. That ratio is the reason lesson 3 talks about retention before anything else.
