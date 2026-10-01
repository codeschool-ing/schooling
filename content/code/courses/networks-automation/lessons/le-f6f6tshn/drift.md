---
title: Finding a change nobody announced
version: 1
---

Somebody logs in to edge1 and changes two things by hand, a description and a static route:

```
ana@ctl:~$ ssh netops@edge1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge1# configure terminal
edge1(config)# interface eth2
edge1(config-if)# description guest wifi
edge1(config-if)# exit
edge1(config)# ip route 192.0.2.128/25 198.51.100.1
edge1(config)# end
edge1# exit
Connection to edge1 closed.
```

The next backup notices, and only edge1 gets a commit:

```
ana@ctl:~$ cd net && python backup.py
committed: edge1.conf
ana@ctl:~$ cd net && git -C backups log --oneline
3c44ac7 backup: edge1
4ad37d6 backup: core1, edge1, edge2
```

`git show --stat` gives the commit's date, the night the change was found, and the file it
touched. The change itself is a diff between the file before and after; `git show HEAD~1:edge1.conf`
prints edge1's file as it was one commit earlier:

```
ana@ctl:~$ cd net && git -C backups show --stat HEAD
commit 3c44ac770f8088930c95197c6cc8a307e0beb760
Author: ana <ana@example.net>
Date:   Thu Oct 1 19:14:13 2026 -0300

    backup: edge1

 edge1.conf | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
ana@ctl:~$ cd net && diff <(git -C backups show HEAD~1:edge1.conf) backups/edge1.conf
8a9,10
> ip route 192.0.2.128/25 198.51.100.1
> !
16c18
<  description branch LAN
---
>  description guest wifi
```

**This is the backup as an audit tool.** Nobody has to remember to announce a change; the router
says what it runs, and the history says when it started. What the history cannot say is who typed
it or why; for that, the router's own logs, the AAA server's accounting, or a change ticket like
lesson 7's.

The date is the night the backup ran, not the minute the change was typed, so a backup once a day
places a change within a day. That is enough to ask the right people the right question, and it
is why a backup job runs at least daily.
