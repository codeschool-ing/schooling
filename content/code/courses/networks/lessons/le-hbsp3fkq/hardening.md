---
title: Closing the door to passwords
version: 1
---

Once every person who needs the server has a key installed, passwords can be switched off:

```
ana@server:~$ echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
PasswordAuthentication no
ana@server:~$ sudo sshd -t -f /etc/ssh/sshd_config && echo config ok
config ok
ana@server:~$ sudo kill -HUP $(cat /run/sshd-server.pid)
ana@server:~$ sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|pubkeyauthentication) "
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication no
ana@laptop:~$ ssh -o PubkeyAuthentication=no -o BatchMode=yes office true
ana@192.168.10.10: Permission denied (publickey).
```

`sshd -t` checks the configuration before it is used; a mistake in `sshd_config` found by restarting
the server can lock everybody out of a machine nobody can walk to. `kill -HUP` makes the lab's sshd
reread its file, which on a real Ubuntu is `sudo systemctl reload ssh`. The laptop, told not to offer
its key, is refused at once, and the refusal names what is still allowed: `(publickey)`.

`sshd -T` prints the settings sshd is really using, after every file it reads. **That is the check that
matters, because sshd, like the client, keeps the first value it finds.** Ubuntu reads
`/etc/ssh/sshd_config.d/*.conf` before the rest of the main file, and on some cloud images one of those
already says `PasswordAuthentication yes`; a `no` appended at the end then changes nothing, and the file
looks right.

`permitrootlogin without-password` is Ubuntu's default: root may log in with a key and never with a
password. Many servers set it to `no`, so people log in as themselves and use `sudo`, and the log says
who did what. **Keep one session open while changing any of this**, and test from a second one. An
open session survives a reload, and it is the way back in if the new setting is wrong.
