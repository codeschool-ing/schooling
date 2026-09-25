---
title: The first connection
version: 1
---

Ana is on the office laptop and wants a shell on the office server. `ssh` takes an address, or a
name, and logs in as the same user unless told otherwise:

```
ana@laptop:~$ ssh 192.168.10.10
The authenticity of host '192.168.10.10 (192.168.10.10)' can't be established.
ED25519 key fingerprint is SHA256:lnt8eQvQ3cgVbp6gskjE+zbhlBcPdROpmRKsk6xZHN8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.10.10' (ED25519) to the list of known hosts.
ana@192.168.10.10's password: 
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@server:~$ hostname
server
ana@server:~$ exit
logout
Connection to 192.168.10.10 closed.
```

Before asking for a password, ssh stopped. **It had never seen this server, and could not tell it from
an impostor.** Every SSH server has a **host key**, a key pair made when it was installed, and it
proves itself with it on every connection. ssh printed that key's fingerprint, `SHA256:lnt8eQ…`,
and asked whether to trust it. Typing `yes` stored the key in `~/.ssh/known_hosts`; from then on, ssh
checks the key against that file, on every connection, without asking.

The fingerprint is only worth checking if there is something to compare it with. On the server, or
from whoever set it up:

```
ana@server:~$ ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
256 SHA256:lnt8eQvQ3cgVbp6gskjE+zbhlBcPdROpmRKsk6xZHN8 root@server (ED25519)
ana@laptop:~$ cat ~/.ssh/known_hosts | cut -c1-60
|1|Z4o3ko8n8gxDudnQpco+eMRBD7A=|Qi+oN+fkW6rG6mcqFTeRHaOXGBQ=
```

The same `SHA256:lnt8eQ…`. A different one, on a first connection, would mean Ana was not talking to
the server at all. The `known_hosts` line itself is unreadable, starting with `|1|`, because Ubuntu
stores the server's name as a hash, so a stolen file does not list the machines Ana connects to.
`ssh-keygen -F 192.168.10.10` still finds the entry.

The password went to the server over the encrypted connection, never in the clear, and ssh echoed
nothing while she typed it. After `exit`, the session ended and the prompt was the laptop's again.
