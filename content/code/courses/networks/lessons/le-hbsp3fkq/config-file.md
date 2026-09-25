---
title: Names for the machines you use
version: 1
---

Addresses, user names and ports are tedious to type and easy to get wrong. `~/.ssh/config` gives each
machine a short name and remembers the rest:

```
ana@laptop:~$ cat ~/.ssh/config
Host office
    HostName 192.168.10.10
    User ana

Host web
    HostName 192.0.2.80
    User ana
ana@laptop:~$ eval $(ssh-agent) >/dev/null
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh office uptime -p
up 31 minutes
```

`ssh office` now means user `ana` at `192.168.10.10`. Anything that can go on the command line can go in
a `Host` block: `Port`, `IdentityFile` for a particular key, `ProxyJump` for the hop in section 08.
Every tool built on SSH reads the same file, so `scp office:…`, `sftp office` and `git` all understand
the short name too; lesson 8 uses them.

The file is read from the top, and **for each setting the first value found wins**. Specific hosts go
first and a `Host *` block with the defaults goes last, or the defaults win everywhere.
