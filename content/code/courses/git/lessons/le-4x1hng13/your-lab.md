---
title: Where you will type — three ways to have Git
version: 1
---

From the next section on, this course is learnt by typing. Every lesson shows a command and what
came back, and you run the same command and compare. **The platform does not run Git for you.**
You need a terminal with Git in it, on a machine you control, and there are three ways to have one.
One is recommended. The other two are real options, each with a cost the first does not have.

## In a virtual machine — the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
that you can break and throw away without touching anything else. Run **Ubuntu Server 24.04 LTS**
in one and you have the exact system this course was recorded on. It comes with Git already
installed, version 2.43.0, the same one every transcript shows.

The program that runs the machine is a **hypervisor**, and which one depends on your computer:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

The steps, once:

1. Install the hypervisor, and download the Ubuntu Server 24.04 LTS installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a new machine from that image with **2 processors, 2 GB of memory and a 20 GB disk**.
3. Start it and accept the installer's defaults. It asks for your name, a name for the server and
   a username. Pick ones you will remember, because you will type the username every day.
4. When it reboots, log in with that username and password, and ask Git what it is:

```
ana@vm:~$ git --version
git version 2.43.0
ana@vm:~$ sudo apt install git
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
git is already the newest version (1:2.43.0-1ubuntu7.3).
0 upgraded, 0 newly installed, 0 to remove and 29 not upgraded.
```

The second command is the one you would use to install it, and here it only confirms that there is
nothing to do. `sudo` asks for your password the first time: it runs the command as the machine's
administrator, which installing anything needs.

**What it costs your computer:** the 2 GB of memory while the machine runs, and the few gigabytes
of disk Ubuntu grows into. Everything this course makes is a few megabytes on top. The first setup
takes most of an hour, and most of that is waiting for the installer.

> **Your prompt will not say `ana@vm`.** In this course `ana` is the user and `vm` is the machine.
> On yours they are the names you chose in step 3. Every command is the same.

## Installed directly on your computer

If your computer **already runs Ubuntu or Debian**, skip the virtual machine: `sudo apt install git`
installs it, and everything in this course works as printed. This is the cheapest path there is.

On **macOS**, typing `git` in a terminal offers to install Apple's developer tools, which include
it. On **Windows**, the installer from git-scm.com brings Git and a terminal called Git Bash, and
every command in this course works in that terminal. Either costs a few hundred megabytes of disk
and nothing while you are not using it.

What they do not give you is the same system. Apple's Git is a different version from the one in
the transcripts. Git for Windows asks, during installation, which editor to use and what to call
the first branch; the next section sets both with commands, so any answer will do. Windows also ends lines in
text files differently from Linux and macOS, and Git converts between the two when you commit, so
you will see warnings about `LF` and `CRLF` that no transcript here has. None of it changes what a
command does. It changes what the screen says around it.

## Online, on somebody else's server

Some services give you a terminal in a browser tab, on a machine of theirs, with Git installed:
GitHub Codespaces and Google Cloud Shell are two, and both have a free allowance at the time of
writing. **It costs your computer nothing**, and it needs an account and a connection.

Use it if the other two are out of reach today, and plan to move. A free allowance is a company's
offer, and offers change their limits and their terms; this course does not depend on any of them.
The machine is also theirs: what you leave in it lasts as long as they decide, so a history you
care about should not live only there.

## Which to pick

The virtual machine, unless your computer already runs Ubuntu. It costs an hour once, and it
buys the one property the others do not have: **when your screen and the transcript disagree, the
difference is in what you typed**, not in which system you are on.

The next section starts at that prompt, and the one after it is for when this one did not go as
written.
