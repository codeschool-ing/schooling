---
title: Cutting the way out, in the lab
version: 1
---

The file server has one legitimate destination outside the company: the backup provider. Everything else it
sends to the internet is, for now, suspect. So the first move is a firewall rule on `fw` that lets `files`
reach the backup and nothing else on the internet side, and leaves the inside of the company alone.

The lab needs two things for that to be visible. The backup provider gets an address on `outside`,
`203.0.113.150`, and `outside` runs a small web server, Python's own, so there is something to reach:

```
root@soc:~# ip -n outside addr add 203.0.113.150/24 dev eth0
root@soc:~# ip netns exec outside python3 -m http.server 8080 >/dev/null 2>&1 &
```

The `&` leaves the server running in the background. Before the rule, `files` reaches both addresses, and
`curl` prints the HTTP status it got back, `200` for both:

```
root@soc:~# ip netns exec files curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/
200
root@soc:~# ip netns exec files curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/
200
```

Now the rule. `nft add rule` appends it to the end of `fw`'s `forward` chain, the one every packet crossing
the firewall goes through. Read it from left to right: packets **from** `192.168.20.10`, **leaving** by
`eth0`, the internet side, **to anything but** `203.0.113.150`, are counted and dropped. The comment carries
the incident's identifier, so that anybody who finds the rule in a year knows why it is there:

```
root@soc:~# ip netns exec fw nft add rule ip fw forward ip saddr 192.168.20.10 oifname eth0 ip daddr != 203.0.113.150 counter drop comment '"INC-2026-014 files egress"'
root@soc:~# ip netns exec fw nft -a list chain ip fw forward
table ip fw {
	chain forward { # handle 1
		type filter hook forward priority filter; policy accept;
		ct state new log prefix "fw-new " group 1 # handle 2
		ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter packets 0 bytes 0 drop comment "INC-2026-014 files egress" # handle 3
	}
}
```

`nft -a` shows each rule's **handle**, the number that names it for deleting later. The logging rule from
lesson 1 is still first, so a blocked attempt is still written to `fw.log`: the rule stops the traffic
without hiding it. Now the same checks, and a few more:

```
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/; echo "exit $?"
000
exit 28
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/
200
root@soc:~# ip netns exec files nc -z -w 3 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
root@soc:~# ip netns exec fw nft list chain ip fw forward | grep files
		ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter packets 5 bytes 300 drop comment "INC-2026-014 files egress"
root@soc:~# grep 'DST=203.0.113.200' /var/log/soclab/fw.log | tail -1
Oct  7 20:39:29 fw fw-new  IN=eth2 OUT=eth0 MAC=fe:8e:86:0d:bc:51:5e:1b:63:92:fa:05:08:00 SRC=192.168.20.10 DST=203.0.113.200 LEN=60 TOS=00 PREC=0x00 TTL=63 ID=824 DF PROTO=TCP SPT=55372 DPT=8080 SEQ=160397314 ACK=0 WINDOW=64240 SYN URGP=0 MARK=0x0 
```

Read them in order. To `203.0.113.200`, `curl` gave up after five seconds (`-m 5`) with status `000` and
exit code `28`, which is curl's code for a timeout: nothing came back. To the backup, `200`, as before. To
`gw`, inside the company, `nc -z` still connects, because that traffic leaves by `eth1` and the rule only
looks at `eth0`. (`nc` is part of a standard Ubuntu install; if it is missing, `sudo apt install
netcat-openbsd`.) The counter says the rule dropped **5 packets, 300 bytes**: the first try and the
retransmissions of a connection that never got an answer. And the log line shows the attempt was recorded
on its way to being dropped.

**Checking is part of the action, not an extra.** A rule written on the wrong interface or with a typo in
an address is accepted by `nft` without a complaint and does nothing, and a containment that was never
verified is a claim in the incident record that nobody can back up. Each of the four checks here answers a
different question: is the bad path closed, is the good path open, is the inside unaffected, and is it
still being recorded.
