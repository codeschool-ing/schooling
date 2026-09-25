---
title: Finding and installing with apt
version: 1
---

The server does not have `tree`, a small program that draws folders as a tree:

```
ana@server:~$ tree
bash: tree: command not found
```

**Find it first, and read what it is before installing it:**

```
ana@server:~$ apt search --names-only '^tree$'
Sorting... Done
Full Text Search... Done
tree/noble-updates 2.1.1-2ubuntu3.24.04.2 amd64
  displays an indented directory tree, in color

ana@server:~$ apt-cache show tree | grep -E '^(Package|Version|Section|Installed-Size|Depends|Description-en)'
Package: tree
Section: universe/utils
Installed-Size: 108
Version: 2.1.1-2ubuntu3.24.04.2
Depends: libc6 (>= 2.38)
Description-en: displays an indented directory tree, in color
Package: tree
Version: 2.1.1-2ubuntu3
Section: universe/utils
Installed-Size: 108
Depends: libc6 (>= 2.38)
Description-en: displays an indented directory tree, in color
```

`apt search` found one package with exactly that name. `apt-cache show` printed the record for **two
versions**: the one in `noble-updates`, the newer, and the one the release shipped with. Its section,
`universe/utils`, is lesson 6's point about who maintains it; it needs only `libc6`, which every
system has.

```
ana@server:~$ sudo apt install -y tree
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  tree
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 47.4 kB of archives.
After this operation, 111 kB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu noble-updates/universe amd64 tree amd64 2.1.1-2ubuntu3.24.04.2 [47.4 kB]
Fetched 47.4 kB in 0s (242 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package tree.
(Reading database ... 13325 files and directories currently installed.)
Preparing to unpack .../tree_2.1.1-2ubuntu3.24.04.2_amd64.deb ...
Unpacking tree (2.1.1-2ubuntu3.24.04.2) ...
Setting up tree (2.1.1-2ubuntu3.24.04.2) ...
ana@server:~$ which tree
/usr/bin/tree
ana@server:~$ dpkg -L tree | grep bin/
/usr/bin/tree
ana@server:~$ tree -L 1 /etc/apt
/etc/apt
├── apt.conf.d
├── auth.conf.d
├── keyrings
├── preferences.d
├── sources.list.d
└── trusted.gpg.d

7 directories, 0 files
```

What the installation said, in order: what it will install, how much it downloads (*47.4 kB*) and how
much disk it takes (*111 kB*), where it came from (`noble-updates/universe`), and the three steps
dpkg does underneath, *unpack* and *set up*. `apt` is the friendly front; **`dpkg`** is the tool
that actually puts files on disk and keeps the record of them.

`dpkg -L` lists **every file a package installed**, which is how you find where a program put its
parts. Here there is one program, `/usr/bin/tree`, the same path `which` found.
