---
title: Your computer, ready to work
version: 1
---

From lesson 5 on, the course asks you to do things to your project: commit, tag, test, push. Before
any of that, your computer needs four things:

- **a terminal**, where every command in this course is typed;
- **git**, which keeps the project's history, and **OpenSSH**, which lesson 15 uses to reach a server;
- **an editor** you are comfortable in; any will do, and nothing in the course depends on which;
- **whatever your project is written in**, which lesson 3 helps you decide. loanbook is Python, and
  you need Python only if your project is too.

## Three ways to have them

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the tools on the computer you already use | a few hundred megabytes of disk | match on Ubuntu 24.04; close elsewhere |
| **a virtual machine** | Ubuntu 24.04 apart from your own system | about 25 GB of disk, and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installed is the recommended path.** A portfolio project lives where you work every day, and git,
OpenSSH and an editor are small, ordinary programs that change nothing else on the computer. On
**Windows**, Git for Windows, from git-scm.com, brings git and a terminal called Git Bash; Windows 10
and 11 already have OpenSSH. On **macOS**, `xcode-select --install` in the Terminal installs git, and
OpenSSH is already there. On **Ubuntu**, `sudo apt install git openssh-client python3`.

**A virtual machine** is the path when you cannot install programs on the computer you have, a work
laptop for instance. Install Ubuntu 24.04 with a desktop in VirtualBox, which is free on Windows, macOS
and Linux, and work inside it. Lesson 15 builds a second, smaller virtual machine for the server; that
one is needed whichever path you take here.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal and an editor in the browser.
It costs your computer nothing; GitHub gives personal accounts a monthly allowance and charges past it,
on terms it sets and can change. It was not run for this course, and it changes lesson 15: a server on
your own computer cannot be reached from a codespace, so your server would have to be online too.

## Checking, and telling git who you are

The transcripts in this course were captured on a laptop running Ubuntu 24.04, by Ana Lima, the author
of loanbook. Her prompt, `ana@laptop:~$`, says who typed the command, on which machine, in which
directory; yours prints your own name. Ask each tool for its version first, which is also the quickest
way to find out it is not installed:

```
ana@laptop:~$ git --version
git version 2.43.0
ana@laptop:~$ ssh -V
OpenSSH_9.6p1 Ubuntu-3ubuntu13, OpenSSL 3.0.13 30 Jan 2024
ana@laptop:~$ python3 --version
Python 3.12.3
```

Your versions will differ, and nothing in this course needs these exact ones. Then git needs to know
who you are, because **every commit carries a name and an e-mail address**:

```
ana@laptop:~$ git config --global user.name "Ana Lima"
ana@laptop:~$ git config --global user.email ana@example.org
ana@laptop:~$ git config --global init.defaultBranch main
ana@laptop:~$ git config --global --list
user.name=Ana Lima
user.email=ana@example.org
init.defaultbranch=main
```

`--global` writes the setting once for every repository on this computer. The third line names the first
branch of every new repository `main`, which is what the course's transcripts and the hosting sites use.
The address is published with every commit you push, and lesson 18 reads it back and shows a no-reply
address that keeps your mailbox out of it. If you will push to a public site, setting that address now saves rewriting
history later.

Last, the proof that it all works: a repository, one file, one commit.

```
ana@laptop:~$ mkdir project && cd project && git init && echo "# project" > README.md
Initialized empty Git repository in /home/ana/project/.git/
ana@laptop:~/project$ git add README.md && git commit -q -m "Say what the project is for" && git log --oneline
d530b40 Say what the project is for
```

One line of history, with a hash of its own; yours will be different, because the hash covers the name,
the time and the content. If you got this far, your computer is ready for the rest of the course. If
something along the way printed an error, the next section is for you.
