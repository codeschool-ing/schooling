---
title: Changing a setting so it can be undone
version: 1
---

The office printer should be reachable by name, `printer.office`, before there is a DNS server that
knows it. That is one line in `/etc/hosts`, and it is changed the careful way:

```
ana@server:~$ sudo cp /etc/hosts /etc/hosts.bak
ana@server:~$ echo '192.168.1.50  printer.office' | sudo tee -a /etc/hosts
192.168.1.50  printer.office
ana@server:~$ diff /etc/hosts.bak /etc/hosts
2a3
> 192.168.1.50  printer.office
ana@server:~$ getent hosts printer.office
192.168.1.50    printer.office
ana@server:~$ sudo mv /etc/hosts.bak /etc/hosts
ana@server:~$ cat /etc/hosts
127.0.0.1 localhost
127.0.1.1 server
```

1. **Copy first.** `/etc/hosts.bak` is the way back, made before anything changed.
2. **Change one thing.** `tee -a` appended one line; `sudo` was needed because `/etc` belongs to root.
   (`sudo echo … >> /etc/hosts` fails, because the `>>` is done by your shell, as you, before sudo runs.
   That is why `tee` is used.)
3. **See exactly what changed.** `diff` compared the copy with the file: after line 2, one line added.
4. **Test it.** `getent hosts` asked the system to resolve the name, and it did.
5. **Know how to undo it.** Moving the copy back restored the original, and `cat` shows it.

Most configuration mistakes are not wrong settings. They are changes nobody can undo because nobody
kept the original, and changes nobody can explain because nobody wrote down what was different. Steps 1
and 3 are the whole cure.

After changing a service's configuration, lesson 14's **`systemctl restart`** makes it read the file
again. `/etc/hosts` needs no restart: it is read at each lookup.
