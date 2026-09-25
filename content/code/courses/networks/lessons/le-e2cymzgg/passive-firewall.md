---
title: Logs in, then hangs
version: 1
---

Passive mode moves the problem to the server's side. Every data connection goes to a port between
40000 and 40009 on `www`, the range its FTP server was set up with. The firewall in front of it has to
let that range in as well as port 21. Here is the firewall that forgot:

```
ana@www:~$ sudo nft add table inet ftp-guard
ana@www:~$ sudo nft add chain inet ftp-guard input '{ type filter hook input priority 0; }'
ana@www:~$ sudo nft add rule inet ftp-guard input tcp dport 40000-40009 drop
ana@laptop:~$ time curl -sS --connect-timeout 10 -u example:Sunflower-77 ftp://www.example.com/
curl: (28) Connection time-out

real    0m10.010s
user    0m0.003s
sys     0m0.006s
ana@www:~$ sudo nft delete table inet ftp-guard
```

**The login worked; the listing never came.** Port 21 was open, so the password was accepted, and
then the data connection to the passive port was dropped without an answer. curl gave up after the ten
seconds `--connect-timeout 10` allowed. A client with no timeout of its own sits there for minutes, and
the person on the phone says "it connects, but it freezes".

That exact symptom is almost always this. The fix is on the server's side: open the passive range in
its firewall, the one written in its configuration (`pasv_min_port` and `pasv_max_port` in vsftpd).
