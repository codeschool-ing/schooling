---
title: Installing the key on the server
version: 1
---

`ssh-copy-id` logs in once with the password and appends the public key to the server's
`~/.ssh/authorized_keys`:

```
ana@laptop:~$ ssh-copy-id -i ~/.ssh/id_ed25519.pub 192.168.10.10
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ana/.ssh/id_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
ana@192.168.10.10's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.10.10'"
and check to make sure that only the key(s) you wanted were added.

ana@server:~$ cat ~/.ssh/authorized_keys | cut -c1-50; ls -ld ~/.ssh ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOba7uYPf3qw8X
drwx------ 2 ana ana 4096 Sep 25 15:11 /home/ana/.ssh
-rw------- 1 ana ana   92 Sep 25 15:11 /home/ana/.ssh/authorized_keys
```

That was the last password this connection needed. The file on the server is one line per key, the
same line as the laptop's `.pub`. **The permissions matter**: `~/.ssh` is `drwx------` and
`authorized_keys` is `-rw-------`. If either can be written by other users, sshd ignores the key, on
the reasoning that somebody else could have put it there, and falls back to asking for the password.
When a key "stops working" after somebody tidied up a home directory, check these first.

Removing access is deleting that line. A person who leaves the company loses their account; a key is
removed from each server it was copied to, which is a good reason to keep a list of where they went.
