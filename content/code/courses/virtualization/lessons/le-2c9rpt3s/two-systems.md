---
title: Two systems, not one
version: 1
---

With vm1 running, there are two operating systems on the computer, and they are more separate than
they look:

```
ana@host:~$ uname -r; hostname
6.18.44-fc-v37
host
ana@vm1:~$ uname -r; hostname
6.8.0-139-generic
vm1
ana@host:~$ echo "written on host" > ~/note.txt; ls ~
note.txt
ana@vm1:~$ ls -A ~; ls ~/note.txt
.bash_logout
.bashrc
.cache
.profile
.ssh
ls: cannot access '/home/ana/note.txt': No such file or directory
```

**Each has its own kernel.** host runs `6.18.44-fc-v37` and vm1 runs `6.8.0-139-generic`, Ubuntu's own,
which came with the base disk. They are not even the same version, and they do not have to be. A guest
could be Windows on the same host, and the host's kernel would never know.

**Each has its own files and its own users.** ana wrote `note.txt` in her home on host, and ana on
vm1 has no such file: she is another account, in another `/etc/passwd`, on another disk, which happens
to have the same name because the lab made it so.

What follows is the part that catches people out:

| on host | inside a guest |
|---|---|
| its own updates | its own updates, which the host's do not install |
| its own users and passwords | its own, and a leaked host password does not open it |
| its own firewall | its own firewall, and traffic between them passes both |
| its own antivirus, if any | nothing, unless the guest has one of its own |

**A guest is a computer to maintain.** Ten guests on a laptop are ten systems that need updates, and
the guest nobody has started for a year is a year behind on security fixes the day it is started
again.
