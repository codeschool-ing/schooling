---
title: Through the jump server, not onto it
version: 1
---

**An administrator passes through a jump server; they do not work on it.** The old way was to log
in to the bastion and open a second SSH session from there, which leaves a shell on the most
sensitive machine of the network and, worse, needs the administrator's key to be on it. OpenSSH has
a better way: `ProxyJump`, written `-J`, asks the jump server to open a TCP connection to the target
and carries the real SSH session through it. The session is encrypted end to end between your
workstation and the server, and your key never leaves your workstation.

That makes it possible to give the bastion no shell at all. Write its SSH policy as root on `jump`:

```
root@jump:~# cat > /etc/ssh/sshd_config.d/10-bastion.conf <<'EOF'
PermitTTY no
ForceCommand /usr/sbin/nologin
AllowAgentForwarding no
X11Forwarding no
PermitOpen web:22
EOF
root@jump:~# sshd -t && systemctl reload ssh; echo "exit $?"
exit 0
```

| line | what it does |
|---|---|
| `PermitTTY no` | no interactive terminal for anybody |
| `ForceCommand /usr/sbin/nologin` | any command asked for runs `nologin` instead, which refuses |
| `AllowAgentForwarding no` | the workstation's SSH agent is not offered to the bastion |
| `X11Forwarding no` | no graphical forwarding, as in lesson 1 |
| `PermitOpen web:22` | the only place the bastion will connect to on a client's behalf |

`sshd -t` checks it before the reload, the habit from lesson 1. Now try to use `jump` as a machine:

```
ana@admin:~$ ssh jump; echo "exit $?"
This account is currently not available.
exit 1
```

Refused, with the message `nologin` always prints. And try to use it as a way through:

```
ana@admin:~$ ssh -J jump web hostname
web
ana@admin:~$ ssh -J jump desk hostname; echo "exit $?"
stdio forwarding failed
exit 255
```

`web` answers. `desk` does not, because `PermitOpen` names only `web:22`: the bastion refuses to
open the connection, and the client reports it as `stdio forwarding failed`. **The bastion's own
configuration is a list of what may be administered through it**, and a server not on the list is
not reachable that way, even by somebody who holds a valid key.

## Writing it down once

Typing `-J jump` every time is how people stop doing it. One entry in your SSH configuration on
`admin` makes it the default way to `web`:

```
ana@admin:~$ cat >> ~/.ssh/config <<'EOF'
Host web
    ProxyJump jump
EOF
ana@admin:~$ ssh web "hostname; echo \$SSH_CONNECTION"
web
192.168.60.40 51316 192.168.60.10 22
```

The second command prints `SSH_CONNECTION`, which the server fills in with where the connection came
from: `192.168.60.40` is `jump`. As far as `web` is concerned, nobody connected from `admin` at all.
That is what the next section relies on.
