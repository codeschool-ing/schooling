---
title: Three machines, and their names
version: 1
---

The three guests were made with `lab.sh vm`, one command each, from the lab's base disk, lesson 10.
libvirt's DHCP gave each an address, and the host wrote them down:

```
ana@host:~$ virsh list; virsh net-dhcp-leases labnet | grep -c ipv4
 Id   Name     State
------------------------
 1    client   running
 2    server   running
 3    target   running

3
ana@host:~$ grep -E " (client|server|target)$" /etc/hosts
10.20.0.34 client
10.20.0.11 server
10.20.0.35 target
ana@host:~$ for m in client server target; do grep -E " (client|server|target)$" /etc/hosts | ssh $m "sudo tee -a /etc/hosts >/dev/null"; done
ana@client:~$ getent hosts server target
10.20.0.11      server
10.20.0.35      target
```

The guests also need to find **each other** by name, and an isolated network has no DNS server that
knows them. For three machines the plain answer is the one from the networks course: the same lines in
every machine's `/etc/hosts`. The loop copies the host's three lines into each guest, and `getent`
on the client shows `server` and `target` resolving to `10.20.0.11` and `10.20.0.35`.

Names matter more than they seem in a lab. A note that says *curl http://target/* still makes sense next
week; one that says *curl http://10.20.0.35/* depends on an address DHCP may hand to somebody else.
