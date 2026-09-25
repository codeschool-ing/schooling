---
title: When the server key changes
version: 1
---

The office server was reinstalled, and a reinstallation makes a new host key. The next connection:

```
ana@laptop:~$ ssh -o BatchMode=yes office true
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:q2DsZDFL+zKzCidnXG2dZNjvraaltILaeMZyqrkLhKU.
Please contact your system administrator.
Add correct host key in /home/ana/.ssh/known_hosts to get rid of this message.
Offending ED25519 key in /home/ana/.ssh/known_hosts:1
  remove with:
  ssh-keygen -f '/home/ana/.ssh/known_hosts' -R '192.168.10.10'
Host key for 192.168.10.10 has changed and you have requested strict checking.
Host key verification failed.
ana@server:~$ ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
256 SHA256:q2DsZDFL+zKzCidnXG2dZNjvraaltILaeMZyqrkLhKU root@server (ED25519)
ana@laptop:~$ ssh-keygen -R 192.168.10.10
# Host 192.168.10.10 found: line 1
/home/ana/.ssh/known_hosts updated.
Original contents retained as /home/ana/.ssh/known_hosts.old
ana@laptop:~$ eval $(ssh-agent) >/dev/null
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh office hostname
The authenticity of host '192.168.10.10 (192.168.10.10)' can't be established.
ED25519 key fingerprint is SHA256:q2DsZDFL+zKzCidnXG2dZNjvraaltILaeMZyqrkLhKU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.10.10' (ED25519) to the list of known hosts.
server
```

ssh refuses outright. **The key it was sent, `SHA256:q2DsZD…`, is not the one in `known_hosts`**, and
from where ssh stands a reinstalled server and somebody in the middle pretending to be it look exactly
the same. The warning says both, and there is no `yes` to type.

Which one it is has to be found out somewhere else. The fingerprint on the server, read from the
console or by whoever reinstalled it, is `SHA256:q2DsZD…`, the one ssh was sent. Only then
`ssh-keygen -R` removes the old line (and keeps the file as it was in `known_hosts.old`), and the next
connection is a first connection again, asking about the new key.

**Never make this warning go away without knowing why it appeared.** A server that was not reinstalled,
not rebuilt and not moved to a new address should not have a new key, and a warning nobody can explain
is one to report rather than to work around.
