---
title: Removing without leaving debris
version: 1
---

Removing is three commands, and each does less than you might expect:

```
ana@server:~$ sudo apt remove -y man-db
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  groff-base libgdbm6t64 libpipeline1 libuchardet0
Use 'sudo apt autoremove' to remove them.
The following packages will be REMOVED:
  man-db
0 upgraded, 0 newly installed, 1 to remove and 0 not upgraded.
After this operation, 2998 kB disk space will be freed.
(Reading database ... 13821 files and directories currently installed.)
Removing man-db (2.12.0-4build2) ...
ana@server:~$ dpkg -l man-db | tail -1
rc  man-db         2.12.0-4build2 amd64        tools for reading manual pages
ana@server:~$ sudo apt autoremove -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  groff-base libgdbm6t64 libpipeline1 libuchardet0
0 upgraded, 0 newly installed, 4 to remove and 0 not upgraded.
After this operation, 4186 kB disk space will be freed.
(Reading database ... 13539 files and directories currently installed.)
Removing groff-base (1.23.0-3build2) ...
Removing libgdbm6t64:amd64 (1.23-5.1build1) ...
Removing libpipeline1:amd64 (1.5.7-2) ...
Removing libuchardet0:amd64 (0.0.8-1build1) ...
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
ana@server:~$ sudo apt purge -y man-db
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  man-db*
0 upgraded, 0 newly installed, 1 to remove and 0 not upgraded.
After this operation, 0 B of additional disk space will be used.
(Reading database ... 13339 files and directories currently installed.)
Purging configuration files for man-db (2.12.0-4build2) ...
  Removing catpages as well as /var/cache/man hierarchy.
ana@server:~$ dpkg -l man-db 2>&1 | tail -1
dpkg-query: no packages found matching man-db
```

1. `apt remove man-db` removed the program and said, before doing so, that four packages **were
   automatically installed and are no longer required**. It did not remove them.
2. `dpkg -l` then showed `rc`: **r**emoved, but **c**onfiguration files remain. `remove` keeps the
   settings in `/etc`, so a reinstall picks up where it left off.
3. `apt autoremove` removed the four dependencies nothing needs any more, **4186 kB**. It knew
   which ones because apt marked them as automatic when it installed them.
4. `apt purge` removed the configuration too. After it, dpkg has no record of `man-db` at all.

| command | removes the program | removes its settings | removes what it brought |
|---|---|---|---|
| `apt remove` | yes | no | no |
| `apt purge` | yes | yes | no |
| `apt autoremove` | no | no | yes, whatever nothing needs |

## The record

Every apt action is written down, with who asked:

```
ana@server:~$ grep -E '^(Commandline|Requested-By)' /var/log/apt/history.log | tail -4
Commandline: apt autoremove -y
Requested-By: ana (1000)
Commandline: apt purge -y man-db
Requested-By: ana (1000)
ana@server:~$ dpkg -l | grep -c '^ii'
208
```

`/var/log/apt/history.log` answers "when was this installed, and by whom?", the question that comes up
when a server starts behaving differently on a Tuesday. The last command counted **208 packages**
installed on this minimal server; a desktop has well over a thousand.
