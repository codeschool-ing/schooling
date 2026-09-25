---
title: The file that overrides DNS
version: 1
---

Before any DNS question, the system reads **`/etc/hosts`**, and `/etc/nsswitch.conf` says so:

```
ana@laptop:~$ grep hosts /etc/nsswitch.conf
hosts:          files dns
ana@laptop:~$ echo "192.0.2.99 www.example.com" | sudo tee -a /etc/hosts
192.0.2.99 www.example.com
ana@laptop:~$ getent hosts www.example.com
2001:db8:10::80 www.example.com
ana@laptop:~$ dig +short www.example.com
192.0.2.81
ana@laptop:~$ curl -sS -m 3 https://www.example.com/
curl: (28) Connection timed out after 3002 milliseconds
```

`hosts: files dns`: the file first, DNS only if the file has nothing. One line added to the laptop's
file, and the laptop disagrees with the whole internet. **`getent`, which asks the way programs do,
says `192.0.2.99`. `dig`, which asks DNS directly, says `192.0.2.81`.** And `curl` believed the file,
tried an address where nothing lives, and timed out.

That disagreement is the whole diagnostic. When `dig` gives the right answer and a program still goes
to the wrong place, **look in the hosts file**, where a line left behind by a developer testing a new
server, or by malware redirecting a bank's name, beats every DNS server in the world.

`dig` and `nslookup` ask DNS and ignore the file; `getent hosts` and `ping` go through the system's
resolver and read it. Comparing the two is a ten-second test that finds this every time. On Windows the
file is `C:\Windows\System32\drivers\etc\hosts`, and it works the same way.
