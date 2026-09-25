---
title: Ticket: "websites do not open"
version: 1
---

This time the laptop reaches addresses and not names:

```
ana@laptop:~$ curl -sS -m 30 https://www.example.com/ -o /dev/null
curl: (6) Could not resolve host: www.example.com
ana@laptop:~$ ping -c 2 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.091 ms
64 bytes from 192.0.2.80: icmp_seq=2 ttl=61 time=0.102 ms

--- 192.0.2.80 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1025ms
rtt min/avg/max/mdev = 0.091/0.096/0.102/0.005 ms
ana@laptop:~$ cat /etc/resolv.conf
nameserver 192.168.10.53
ana@laptop:~$ dig +tries=1 +time=3 www.example.com
;; communications error to 192.168.10.53#53: timed out

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> +tries=1 +time=3 www.example.com
;; global options: +cmd
;; no servers could be reached
ana@laptop:~$ sudo timeout 6 tcpdump -i eth0 -n -l arp or port 53 2>/dev/null
15:58:41.158416 ARP, Request who-has 192.168.10.53 tell 192.168.10.20, length 28
15:58:42.173841 ARP, Request who-has 192.168.10.53 tell 192.168.10.20, length 28
15:58:43.197869 ARP, Request who-has 192.168.10.53 tell 192.168.10.20, length 28

ana@laptop:~$ dig +short @198.51.100.53 www.example.com
192.0.2.80
ana@laptop:~$ echo "nameserver 198.51.100.53" | sudo tee /etc/resolv.conf
nameserver 198.51.100.53
ana@laptop:~$ dig +short www.example.com
192.0.2.80
```

The `ping` to `192.0.2.80` works, so steps 1 to 3 pass, and step 4 fails: `dig` got no answer from
`192.168.10.53`, the only server in `/etc/resolv.conf`. tcpdump shows why, and it is not a DNS packet at
all. `192.168.10.53` is on the office network, so before sending a query the laptop has to find that
machine with ARP, and it asked three times, `who-has 192.168.10.53`, with nobody answering.
There is no DNS server at that address.

`dig @198.51.100.53` asks the real resolver directly, bypassing the setting, and gets `192.0.2.80`,
which proves the problem is the setting and not DNS itself. **`@server` is the quickest test there is
for a DNS complaint**: the same question to two servers, and the two answers compared. The fix here was
the file; on an office PC it is the DNS server that DHCP hands out, or one typed into the adapter's
settings years ago.
