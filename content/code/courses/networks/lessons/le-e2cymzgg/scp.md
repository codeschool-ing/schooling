---
title: scp: one file over SSH
version: 1
---

Between machines that run SSH, which is every Linux server, there is no need for an FTP server at all.
`scp` copies files over an SSH connection, with the same key, agent and `~/.ssh/config` as lesson 7:

```
ana@laptop:~$ ls -l licences.tar.gz
-rw-r--r-- 1 ana ana 67581 Sep 25 15:25 licences.tar.gz
ana@laptop:~$ scp licences.tar.gz office:
ana@laptop:~$ scp -r Documents office:
ana@laptop:~$ scp office:/etc/hostname from-server.txt && cat from-server.txt
server
ana@server:~$ ls -l licences.tar.gz Documents
-rw-r--r-- 1 ana ana 67581 Sep 25 15:26 licences.tar.gz

Documents:
total 80
-rw-r--r-- 1 ana ana 11358 Sep 25 15:26 Apache-2.0
-rw-r--r-- 1 ana ana  1499 Sep 25 15:26 BSD
-rw-r--r-- 1 ana ana 35149 Sep 25 15:26 GPL-3
-rw-r--r-- 1 ana ana  7652 Sep 25 15:26 LGPL-3
-rw-r--r-- 1 ana ana 16726 Sep 25 15:26 MPL-2.0
```

**The colon is what makes a path remote.** `office:` is ana's home folder on the server,
`office:/etc/hostname` is a full path there, and a path without a colon is on this machine. `-r` copies
a folder and everything in it. The side with the colon is the one read from or written to, so the same
command copies in either direction.

scp printed nothing, because nothing went wrong. The copy on the server has the same size, `67581`
bytes. Everything travelled inside SSH, on port 22: one connection, encrypted, with no passive range and
nothing for NAT to get wrong. Since OpenSSH 9.0, scp uses the SFTP protocol of section 09 underneath,
and only the command stayed the same.
