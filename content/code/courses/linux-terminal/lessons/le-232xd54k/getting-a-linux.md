---
title: Getting a Linux to practise on
version: 2
---

This section teaches no Linux at all, and it is the one without which the rest of the course does
not work. **Everything after this assumes you have a prompt in front of you** — not a video of one,
not a diagram, a real one you can type into and break.

Reading about commands does not produce the skill. The skill is in your hands, and it arrives
through repetition on a machine that is yours to ruin. So: three ways to have one, what each costs,
the one to choose, and what to do when building it goes wrong.

## What "a machine to practise on" has to be

Three properties, and they rule out some options that look convenient:

1. **You can break it.** You will run something destructive by accident. That has to be a
   ten-minute inconvenience, not a disaster.
2. **You can throw it away and get a fresh one.** Starting clean is a learning tool, not an
   admission of failure.
3. **It is a real Linux that boots.** Not a simulator, not a website that pretends. The whole
   subject is how the actual system behaves, and lesson 5 is about what happens when it starts.

## Three ways

| | what it is | what it costs you | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | a whole computer simulated inside yours, running Ubuntu Server 24.04 LTS | free software, 25 GB of disk, 2 to 3 GB of memory while it runs | match, but for names, numbers and dates |
| **installed** | Linux on the computer itself, as its only system or beside the one it has | nothing, if it already runs Linux; a free partition and a reboot if it does not | match on Ubuntu 24.04, close on others |
| **online** | somebody else's machine, rented by the hour or lent from a monthly allowance | nothing on your computer; money, or the allowance a company decides | close, and lesson 5 may not work |

## The recommended one: a virtual machine

**Make a virtual machine and install Ubuntu Server 24.04 LTS in it.** It is the one path that has
all three properties: a mistake stays inside it, a snapshot taken once it is installed brings it
back in a minute, and it boots, so lesson 5's services and lesson 13's timers are there in full. It
is also what most of the machines you will look after at work are: a server with no desktop,
reached through a terminal.

What it costs is measurable. Ubuntu's own documentation for 24.04 asks for **at least 1.5 GB of
memory and 5 GB of disk** to install from the ISO, and suggests 3 GB and 25 GB for a machine that
does any real work. Give it **2 GB of memory if your computer has 8 GB, and 4 GB if it has 16**, two
processors, and a 25 GB disk. The disk grows as it is written to, so a fresh install takes a few
gigabytes of the 25, not all of them. The memory is taken only while the machine is running.

The program that runs it depends on what your computer already is:

| your computer | the hypervisor | |
|---|---|---|
| **Windows 10 or 11** | **WSL 2**, which is a virtual machine Windows manages for you | `wsl --install -d Ubuntu-24.04` in PowerShell, then a restart |
| | or VirtualBox, free | the full install below, the same as on any other computer |
| **macOS, Apple silicon** (M1 and later) | UTM, free | the **ARM** server ISO: Ubuntu publishes one for 24.04 |
| **macOS, Intel** | VirtualBox, free | the ordinary server ISO |
| **Linux** | virt-manager, which drives KVM; or VirtualBox | the ordinary server ISO |

**WSL is the short way on Windows and it counts as this path.** It boots a real Linux kernel,
current versions start systemd, and it skips the installer. What it does not give you is the
installer itself, the console, and a snapshot button. If you want those, use VirtualBox.
Inside WSL, work on the Linux side: your home is `/home/<you>`, and the Windows disk appears at
`/mnt/c`, where files are slower and carry Windows line endings, which is section 12's subject.

**Everywhere else, the install is the same five decisions**, whichever hypervisor asks them:

1. Download the Ubuntu Server 24.04 LTS ISO from `ubuntu.com/download/server`.
2. Create a machine with the memory, processors and disk above, and point its optical drive at the
   ISO.
3. Start it and accept the installer's defaults, with two exceptions. **Your name and the server's
   name:** every transcript in this course prints `ana@vm` — `ana` the user, `vm` the machine — and
   yours will print whatever you choose. **"Install OpenSSH server": tick it.** Lesson 5 connects to
   the machine over SSH.
4. When it says to, remove the ISO and reboot, then sign in at the console with the name and
   password you chose.
5. **Shut it down and take a snapshot.** Call it `clean`. That snapshot is the "throw it away and get
   a fresh one" of the list above.

## The other two, named

**Installed.** If your computer already runs Linux, you have a machine and it costs nothing. Ubuntu
24.04 matches every transcript here; another distribution matches most of them, and lesson 2 says
what differs. The cost is the first property on the list: lessons 4, 5 and 7 change users, services
and packages, and a mistake there is on the computer you work on. Installing Linux beside Windows
(a *dual boot*) is the same path with a partition to make first, and it is more work than a virtual
machine for a course.

**Online.** A cloud provider rents a Linux server by the hour, and some development services lend a
terminal in the browser from a monthly free allowance. It costs your computer nothing, which makes
it the path for a computer that cannot run a virtual machine. It costs money or an allowance, on
terms the company sets and can change, so nothing in this course depends on one. Two things to
check before you start: `cat /etc/os-release`, below, says which Linux you were lent; and a
terminal in a browser is very often **a container** rather than a machine, which the next part is
about.

**On a Mac, Terminal is not a fourth path.** It opens instantly and most commands work, so you will
be tempted. It is a BSD userland: flags differ, `sed -i` behaves differently, there is no `/proc`,
there is no `apt` and no systemd. It is fine for lessons 3 and 4 and actively misleading for 2, 5,
7 and 11. Use it for convenience, and have a real Linux for the course.

## A container is quick, and it is not enough

You will meet containers early, and one is a complete throwaway Linux in a second:

```
docker run -it --rm ubuntu:24.04 bash
```

`-it` gives you a terminal, `--rm` deletes the machine when you exit, `bash` is what to run inside.
When you type `exit`, everything you did is gone, which is the point.

It fails the third property, and the course meets that failure in lesson 5. **A container does not
boot.** It runs one program, not a whole machine's worth of them, so the service manager everybody
else's Linux starts first is not there. Use one for a quick look at another distribution, which
lesson 2 does; do not use one as the machine for this course.

## Check that what you got is what you think

The first reflex of this course, and you will use it for years: when you arrive on a machine, ask
it what it is.

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.5 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

`ID` and `ID_LIKE` are the two lines that matter, and lesson 2 explains why: they tell you which
family you are in, which tells you the package manager, the service names and half the paths.

And ask who you are:

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana),27(sudo)
```

An ordinary user, with a number, in a group called `sudo` — which is what lets this account act as
the administrator, one command at a time, and lesson 4 is about. On a machine you have just
installed the number is most likely `1000`, because the first account made on a machine gets it.
This one had an account before `ana`, so hers is `1001`, and an installer may put you in a few more
groups than these. If `id` says `uid=0(root)`, you are the administrator itself, which is very
common inside containers and is discussed in section 14.

## When the setup fails

This is where most people stop, so here are the failures that happen, each with what it looks like
and what to do.

**The hypervisor will not start a machine, or starts it unbearably slowly.** A virtual machine needs
the processor's virtualisation extensions — Intel calls them VT-x, AMD calls them AMD-V — and many
computers ship with them switched off in the firmware. On a Linux computer, one program asks, and
`sudo apt install cpu-checker` installs it:

```
ana@vm:~$ sudo kvm-ok
[sudo] password for ana:
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used
```

That is the answer from a machine whose processor offers none — this one is itself a virtual
machine, and nothing was passed through to it. On your own computer the fix is in the firmware
settings, the screen a key such as F2, F10 or Del opens while it starts: turn on *Intel
Virtualization Technology*, *SVM* or *AMD-V*, whichever name it uses, save, and restart. On Windows,
WSL needs the same setting, and Windows' own *Virtual Machine Platform* feature, which
`wsl --install` switches on and which takes effect only after the restart it asks for.

**The installer stops, or the machine freezes during it.** Too little memory, almost always. Give it
the 2 GB above, not the 1 GB a hypervisor sometimes offers by default, and start again: nothing on
your computer was touched.

**The machine is running and `apt` will not get on with it.** A fresh Ubuntu installs its security
updates by itself in the first minutes after it boots, and while it does, nothing else may install
anything:

```
ana@vm:~$ sudo apt install tree
[sudo] password for ana:

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 8129 (unattended-upgr)...
```

`unattended-upgr` is the program doing the updates, its name cut short to fifteen characters, and
`apt` repeats that last line every second while it waits. Leave it and it carries on by itself when
the updates finish; or press Ctrl+C and run the command again in a few minutes. **Never delete the
lock file**: it is there because two programs writing the package database at once is how a machine
ends up with half a package installed. (The warning above it is lesson 7's subject.)

**A command is missing.** Ubuntu Server ships without some things you will see in the course, and
the answer names the package that has it:

```
ana@vm:~$ tree
Command 'tree' not found, but can be installed with:
sudo apt install tree
```

`sudo apt install tree` installs it, and lesson 7 is about everything that line does.

**`systemctl` says the system was not booted.** You are in a container, not a machine:

```
ana@vm:~$ systemctl status
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

Nothing is broken. There is no service manager running, because nothing booted. Most of the course
still works there; lesson 5 and the timers of lesson 13 need the virtual machine. The transcripts in
this course were captured on such a machine, and lesson 5 says where that shows.

**And if it all goes wrong after it worked,** go back to the snapshot. That is what it is for.

## Before you go on

You should be able to do this, now, before reading further:

1. open a terminal and see a prompt;
2. type `whoami` and press enter, and see a name;
3. type `uname -s` and see `Linux`;
4. type something that does not exist — `hello` will do — and read what comes back.

The fourth one is not a joke. It is the first error message of the course, and section 17 spends
its time on exactly that line. Getting a refusal from a machine you have just built is a better
start than getting nothing.

## The files this lesson uses

The sections ahead list and read a few small files. Make them now, so that what you see matches what
the page shows. Copy this into the terminal as it is; it runs in a few milliseconds and prints
nothing:

```sh
mkdir -p ~/notes ~/demo/folder ~/plain/folder ~/case ~/crlf
cd ~/demo
printf 'first line\nsecond line\nthird line\nfourth line\n' > readme.txt
printf 'x\n' > ./-strange
printf 'abc\n' > 'with space.txt'
touch .hidden
cp readme.txt .hidden ~/plain/
cd ~/case
touch NOTES.TXT Notes.txt notes.txt
printf 'not a PDF at all\n' > report.pdf
cd ~/crlf
printf '#!/bin/bash\necho "hello"\n' > unix.sh
printf '#!/bin/bash\r\necho "hello"\r\n' > windows.sh
printf '#!/bin/bash\r\nif [ -n "$HOME" ]; then\r\n  echo "home is set"\r\nfi\r\n' > vars.sh
chmod +x unix.sh windows.sh vars.sh
cd
```

`printf` writes exactly what it is given, with `\n` as the end of a line and `\r\n` as the end of a
line the way Windows writes it, which is section 12's subject. You do not need to understand any of
this yet: by lesson 3 every line of it is ordinary.
