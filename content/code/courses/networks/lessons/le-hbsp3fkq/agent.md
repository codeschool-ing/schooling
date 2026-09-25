---
title: The agent, which remembers the passphrase
version: 1
---

With a passphrase on the key, every connection asks for it, which is safe and tiresome. The **agent**
is a small program that holds the unlocked key in memory, and ssh asks it instead:

```
ana@laptop:~$ ssh 192.168.10.10 hostname
Enter passphrase for key '/home/ana/.ssh/id_ed25519': 
server
ana@laptop:~$ eval $(ssh-agent)
Agent pid 37177
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh-add -l
256 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg ana@laptop (ED25519)
ana@laptop:~$ ssh 192.168.10.10 hostname
server
```

The first `ssh` asked for the passphrase. `eval $(ssh-agent)` started an agent and told the shell where
to find it; `ssh-add` unlocked the key once and handed it over; `ssh-add -l` lists what the agent holds,
by fingerprint, the same `SHA256:zfl5ZH…` `ssh-keygen` printed. The second `ssh` asked nothing.

The unlocked key lives only in the agent's memory, and ends with it: a logout, a reboot, or
`ssh-add -D` forgets it. The key file on disk is still encrypted. On a desktop, the agent usually
starts on its own with the session. GNOME and macOS can keep the passphrase in the login keychain, and
the Windows agent remembers keys across restarts, so a person types the passphrase once.

**Do not forward the agent to machines you do not trust.** `ssh -A` lets the remote server use your
agent while you are connected; anybody who is root on that server can then log in wherever your key
works. The jump host in section 08 does the same job without that risk.
