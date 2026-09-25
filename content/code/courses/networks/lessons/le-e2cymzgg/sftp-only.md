---
title: An account that can only drop files
version: 1
---

The office scanner saves scans to the server by SFTP, as many scanners and copiers can. Its account,
`scans`, needs to put files in one folder and nothing else: no shell, and no view of the rest of the
server. Four lines at the end of the server's `sshd_config` do it:

```
ana@server:~$ tail -4 /etc/ssh/sshd_config
Match User scans
    ForceCommand internal-sftp
    ChrootDirectory /srv/scans
    AllowTcpForwarding no
ana@server:~$ ls -ld /srv/scans /srv/scans/inbox
drwxr-xr-x 3 root  root  4096 Sep 25 15:20 /srv/scans
drwxr-xr-x 2 scans scans 4096 Sep 25 15:24 /srv/scans/inbox
ana@laptop:~$ ssh scans@192.168.10.10
scans@192.168.10.10's password: 
Connection from user scans 192.168.10.20 port 47716: refusing non-sftp session
This service allows sftp connections only.
Connection to 192.168.10.10 closed.
ana@laptop:~$ sftp scans@192.168.10.10
scans@192.168.10.10's password: 
Connected to 192.168.10.10.
sftp> pwd
Remote working directory: /
sftp> ls
inbox
sftp> cd /etc
stat remote: No such file or directory
sftp> cd inbox
sftp> put scan-0001.pdf
Uploading scan-0001.pdf to /inbox/scan-0001.pdf
scan-0001.pdf                                 100%   16KB  22.0MB/s   00:00    
sftp> bye
ana@server:~$ ls -l /srv/scans/inbox
total 20
-rw-r--r-- 1 scans scans 16726 Sep 25 15:27 scan-0001.pdf
```

`Match User scans` applies what follows to that account only. `ForceCommand internal-sftp` gives the
account SFTP whatever the client asks for, so `ssh` was turned away with `This service allows sftp
connections only`. `ChrootDirectory /srv/scans` makes that folder the account's `/`: `pwd` said `/`,
`ls` showed only `inbox`, and `/etc` does not exist from where it stands.

**The chroot folder must belong to root and be writable by nobody else**, or sshd refuses the login.
That is why `/srv/scans` is `root root drwxr-xr-x` and the writable place is `inbox` inside it. The scan
arrived owned by `scans`, where the people who file them can pick it up.
