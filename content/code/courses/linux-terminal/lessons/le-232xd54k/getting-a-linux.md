---
title: Getting a Linux to practise on
version: 1
---

This section teaches no Linux at all, and it is the one without which the rest of the course does
not work. **Everything after this assumes you have a prompt in front of you** — not a video of one,
not a diagram, a real one you can type into and break.

Reading about commands does not produce the skill. The skill is in your hands, and it arrives
through repetition on a machine that is yours to ruin. So: five ways to have one, what each costs,
and a recommendation.

## What "a machine to practise on" has to be

Three properties, and they rule out some options that look convenient:

1. **You can break it.** You will run something destructive by accident. That has to be a
   ten-minute inconvenience, not a disaster.
2. **You can throw it away and get a fresh one.** Starting clean is a learning tool, not an
   admission of failure.
3. **It is a real Linux.** Not a simulator, not a website that pretends. The whole subject is how
   the actual system behaves.

## Five ways

| | what it is | costs you | good for |
|---|---|---|---|
| **WSL 2** | a real Linux kernel running beside Windows, with a terminal into it | nothing; Windows 10/11 only | **the answer if you are on Windows** |
| **a container** | a Linux userland on a Linux or Mac host, started in a second | nothing; needs Docker or Podman installed | quick practice, throwaway machines, lessons 1–4 and 7–9 |
| **a virtual machine** | a whole computer simulated inside your computer | free software, a few GB of disk, some RAM | the most complete option; the only one that gives you the boot, systemd and the desktop |
| **a live USB** | booting your own hardware from a stick, touching nothing on the disk | a USB stick and a reboot | trying a distribution on real hardware |
| **a cloud instance** | somebody else's machine, rented by the hour | money, and a credit card | practising remote access; how it will really be at work |

## Pick one, in one line

**On Windows → WSL 2.** It is free, it is a genuine kernel rather than an emulation, and it is one
command in PowerShell:

```
wsl --install
```

That installs Ubuntu by default, and after a restart `wsl` from any terminal drops you at a
prompt. If you want a specific distribution, `wsl --list --online` shows what is available.

**On macOS or Linux → a container**, for speed, and a virtual machine when you reach lesson 5.
With Docker installed, this is a complete throwaway Linux:

```
docker run -it --rm ubuntu:24.04 bash
```

`-it` gives you a terminal, `--rm` deletes the machine when you exit, `bash` is what to run inside.
When you type `exit`, everything you did is gone — which is the point. To keep a machine between
sessions, drop `--rm` and give it a name.

**On a Mac, do not just use Terminal.** You will be tempted, because it opens instantly and most
commands work. It is a BSD userland: flags differ, `sed -i` behaves differently, there is no
`/proc`, there is no `apt` and no systemd. It is fine for lessons 3 and 4 and actively misleading
for 2, 5, 7 and 11. Use it for convenience, and have a real Linux for the course.

## Check that what you got is what you think

The first reflex of this course, and you will use it for years: when you arrive on a machine, ask
it what it is.

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
```

`ID` and `ID_LIKE` are the two lines that matter, and lesson 2 explains why: they tell you which
family you are in, which tells you the package manager, the service names and half the paths.

And ask who you are:

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana)
```

An ordinary user, with a number. If that says `uid=0(root)`, you are the administrator, which is
very common inside containers and is discussed in section 14.

## Three things that will confuse you, named in advance

**A container has no systemd.** This is the most common surprise of the whole list and it is not a
fault. A container runs one program, not a whole machine's worth of them, so `systemctl` inside a
plain `ubuntu` container answers:

```
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

Nothing is broken. There simply is no init system running, because nothing booted. Lesson 5 is
about systemd and needs a virtual machine or WSL, not a container. Plan for that now rather than
concluding your machine is wrong.

**A fresh container is missing tools you expect.** `ubuntu:24.04` ships small: no `ps`, no `vim`,
no `curl`. Lesson 7 teaches installing them; until then, `apt update && apt install -y procps
vim curl` gets you a workable machine.

**WSL's filesystem has two sides.** Your Linux home is `/home/you` and your Windows disk appears at
`/mnt/c`. Work on the Linux side — files on `/mnt/c` are slower, and they carry Windows line
endings, which is section 12's entire subject.

## Before you go on

You should be able to do this, now, before reading further:

1. open a terminal and see a prompt;
2. type `whoami` and press enter, and see a name;
3. type `uname -s` and see `Linux`;
4. type something that does not exist — `hello` will do — and read what comes back.

The fourth one is not a joke. It is the first error message of the course, and section 17 spends
its time on exactly that line. Getting a refusal from a machine you have just built is a better
start than getting nothing.
