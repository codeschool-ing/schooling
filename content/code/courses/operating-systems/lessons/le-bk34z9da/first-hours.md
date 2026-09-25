---
title: The first hour after installing
version: 1
---

The installer's copy is as old as the ISO, so the first job is the same as on Windows: updates. On
Ubuntu that is two commands. The first asks the repositories what is new:

```
ana@server:~$ sudo apt update
Hit:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu noble InRelease
Hit:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
50 packages can be upgraded. Run 'apt list --upgradable' to see them.
ana@server:~$ apt list --upgradable 2>/dev/null | head -6
Listing...
apt/noble-updates 2.8.3 amd64 [upgradable from: 2.7.14build2]
base-files/noble-updates 13ubuntu10.5 amd64 [upgradable from: 13ubuntu10]
coreutils/noble-updates,noble-security 9.4-3ubuntu6.3 amd64 [upgradable from: 9.4-3ubuntu6]
diffutils/noble-updates,noble-security 1:3.10-1ubuntu0.1 amd64 [upgradable from: 1:3.10-1build1]
dpkg/noble-updates,noble-security 1.22.6ubuntu6.6 amd64 [upgradable from: 1.22.6ubuntu6]
```

`sudo apt update` only **refreshes the list**: it downloaded the current catalogue from Ubuntu's servers
(the four `Hit` lines) and compared it with what is installed. Fifty packages have newer versions, and
the second command lists them: `apt`, the package tool itself, the base files, the core utilities. Lesson
11 is about `apt` in detail.

The second command installs them:

```
ana@server:~$ sudo apt upgrade -y > upgrade.log 2>&1; tail -3 upgrade.log
Setting up e2fsprogs (1.47.0-2.4~exp1ubuntu4.1) ...
e2scrub_all.service is a disabled or a static unit not running, not starting it.
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
ana@server:~$ apt list --upgradable 2>/dev/null
Listing...
```

`sudo apt upgrade` downloads and installs every newer version. The last lines of its log are packages
being configured, and afterwards the list of upgradable packages is empty. Unlike Windows, most of this
needs **no restart**; a new kernel is the main exception, and Ubuntu says so when one arrives.

## sudo: administrator for one command

On Linux, the administrator is a user called **root**. Ubuntu does not let you sign in as root. Instead,
the first account belongs to the **`sudo` group**, which lets it run one command at a time as root:

```
ana@server:~$ id
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
ana@server:~$ sudo whoami
root
```

`id` shows Ana is in group 27, `sudo`. `sudo whoami` runs `whoami` as the administrator, and the answer
is `root`. `sudo` asks for **Ana's own password**, not root's, remembers it for a few minutes, and writes
every use to a log. On this test machine it was set not to ask, which is why the transcript shows no
prompt; a real installation asks. Lesson 10 compares it with Windows's UAC, which is the same idea with a button instead
of a password prompt.

The habit to take from here: work as yourself, and put `sudo` in front of the few commands that change
the system. The commands in this course that need it say so.
