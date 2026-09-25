---
title: sftp: a session, over SSH
version: 1
---

For browsing and moving several files, `sftp` opens a session with commands much like FTP's. The
protocol underneath has nothing to do with FTP: **it is a subsystem of SSH**.

```
ana@laptop:~$ sftp office
Connected to office.
sftp> pwd
Remote working directory: /home/ana
sftp> ls
Documents
licences.tar.gz
sftp> cd Documents
sftp> ls -l
-rw-r--r--    ? ana      ana         11358 Sep 25 15:26 Apache-2.0
-rw-r--r--    ? ana      ana          1499 Sep 25 15:26 BSD
-rw-r--r--    ? ana      ana         35149 Sep 25 15:26 GPL-3
-rw-r--r--    ? ana      ana          7652 Sep 25 15:26 LGPL-3
-rw-r--r--    ? ana      ana         16726 Sep 25 15:26 MPL-2.0
sftp> get MPL-2.0
Fetching /home/ana/Documents/MPL-2.0 to MPL-2.0
MPL-2.0                                       100%   16KB  20.0MB/s   00:00    
sftp> put index.html
Uploading index.html to /home/ana/Documents/index.html
index.html                                    100%  109   273.5KB/s   00:00    
sftp> bye
ana@laptop:~$ ls -l MPL-2.0
-rw-r--r-- 1 ana ana 16726 Sep 25 15:26 MPL-2.0
ana@server:~$ ls -l Documents/index.html
-rw-r--r-- 1 ana ana 109 Sep 25 15:26 Documents/index.html
ana@laptop:~$ printf "cd Documents\nls\n" | sftp -b - office
sftp> cd Documents
sftp> ls
Apache-2.0   BSD          GPL-3        LGPL-3       MPL-2.0      index.html   
```

`cd`, `ls` and `pwd` act on the server; the same commands with an `l` in front, `lcd`, `lls` and `lpwd`,
act on the laptop. `get` downloads and `put` uploads, each with a progress line. The `?` in the listing
is a detail of the protocol: it does not carry the link count that `ls -l` normally shows.

`-b -` reads the commands from its input instead of a keyboard, which is how sftp goes into a script.
The graphical clients most people use, such as FileZilla and WinSCP, speak the same SFTP, and in them
this is a window with two panes.
