---
title: Reading the server's log
version: 1
---

Every login, and every failed one, is written down by sshd. Three wrong passwords from the laptop first,
then the log:

```
ana@laptop:~$ ssh -o PubkeyAuthentication=no office true
ana@192.168.10.10's password: 
Permission denied, please try again.
ana@192.168.10.10's password: 
Permission denied, please try again.
ana@192.168.10.10's password: 
ana@192.168.10.10: Permission denied (publickey,password).
ana@server:~$ sudo grep -E "Accepted|Failed" /var/log/ssh/sshd.log
Accepted password for ana from 192.168.10.20 port 34472 ssh2
Accepted password for ana from 192.168.10.20 port 40738 ssh2
Accepted publickey for ana from 192.168.10.20 port 40746 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 192.168.10.20 port 58742 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 192.168.10.20 port 35328 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 198.51.100.77 port 50958 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 198.51.100.77 port 52030 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 192.168.10.20 port 38096 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Failed password for ana from 192.168.10.20 port 44420 ssh2
Failed password for ana from 192.168.10.20 port 44420 ssh2
Failed password for ana from 192.168.10.20 port 44420 ssh2
```

**Each line is one attempt, and names the method it used.** Two `Accepted password`, the first connection and
`ssh-copy-id`. Six `Accepted publickey`, each with the fingerprint of the key that was used, which is
how to tell whose key it was when a server trusts several. Two of them came from `198.51.100.77`, home:
the login of section 07 and the first hop of section 08. Three `Failed password` share one source
port, because they were the three tries a single connection gets before ssh gives up.

The lab writes this log to a file of its own. **On a real Ubuntu the same lines are in
`/var/log/auth.log`**, and `journalctl -u ssh` shows them too. A server on the internet shows `Failed
password` for `root`, `admin` and `test` all day, from addresses nobody knows; with passwords off,
that noise is harmless, and a tool such as `fail2ban` can block addresses that keep trying.
