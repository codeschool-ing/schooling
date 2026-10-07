---
title: Your lab, and three ways to have one
version: 1
---

**Every lesson of this course runs something**: a test suite, a CI that answers a push, a deploy, a
canary that stops a bad release. You run them too, on a machine of your own, and nothing here
needs more than one. This section says what that machine needs and three ways to have it. The next
one builds the project every lesson works on, and the one after it says what to do when the setup
goes wrong.

The lab is one Linux computer with four things on it:

- **git, curl and jq**, from Ubuntu's own packages: git for the project's history and lesson 5's
  CI, curl to talk to the program over HTTP, jq to read JSON in lesson 6;
- **uv**, a tool that makes Python virtual environments and installs Python versions. Lesson 5's CI
  runs the suite under Python 3.11, 3.12 and 3.13, and uv fetches any of them it does not find;
- **Python 3.13** in a virtual environment inside the project, with three libraries pinned to the
  versions the transcripts were recorded with: pytest, coverage and Hypothesis;
- **the project itself**, `shipquote`, which the next section builds.

Nothing else. `shipquote` uses only Python's standard library; the carrier it asks for prices is a
small server you write in lesson 2; the CI of lesson 5 is a script you write into a git repository;
and the "environments" of lessons 7 to 11 are directories and processes on this same machine.
Lesson 6 adds two optional tools and says how to install them there.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04, apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| **installed** | the same tools on the computer you already use | about 75 MB in your home directory, plus each Python uv downloads | match on Ubuntu 24.04; close elsewhere |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**The virtual machine is the recommended path.** From lesson 7 on, the course starts and stops
servers on a dozen ports between 8080 and 9092, and writes releases under `~/envs`; on a
computer you also work on, those collide with whatever else is running there. The scripts lean on
Linux tools such as `setsid` and `sha256sum`, which a Mac does not have under those names. And a
snapshot of the machine taken once the setup works gives you a clean start whenever an experiment
goes wrong. Use the hypervisor your computer already suits: VirtualBox on Windows or Linux, UTM on
an Apple-silicon Mac, Hyper-V on Windows if it is switched on, with an Ubuntu Server 24.04 image
from ubuntu.com. `virtualization` lesson 4 builds one in VirtualBox step by step. On Windows, WSL
running Ubuntu 24.04 is a virtual machine too, and works the same way.

**Installed** is fine on a computer that already runs Ubuntu 24.04, with the same commands. On
another Linux the package names may differ. On a Mac, git and curl come with Apple's command-line
developer tools, and uv and jq install with Homebrew; the first six lessons ask for nothing
Linux-specific, and lessons 7 to 11 need the Linux tools above, which is the reason to use the
virtual machine there. None of that was run for this course, so a path or a version in a
transcript may differ from yours.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser. It costs
your computer nothing; GitHub gives personal accounts a monthly allowance of hours and charges past
it, on terms it sets and can change. It was not run for this course. Which Linux a codespace runs
decides whether the commands below work as printed, and `cat /etc/os-release` tells you before you
start.

## Building it

Everything below is typed in a terminal on the machine you chose. First the system's own packages:

```sh
sudo apt-get update
sudo apt-get install -y git curl jq pipx
```

`pipx` installs a Python program into a directory of its own and puts its command in
`~/.local/bin`. That is how uv goes in, without touching the Python Ubuntu itself runs on:

```sh
pipx install uv
pipx ensurepath
```

`pipx ensurepath` adds `~/.local/bin` to your `PATH` in `~/.bashrc`, which a terminal reads when it
opens. **So close the terminal and open a new one** before going on; the old one does not know
where `uv` is. In the new one, the three tools answer:

```
ana@laptop:~$ uv --version
uv 0.12.23 (x86_64-unknown-linux-gnu)
ana@laptop:~$ git --version
git version 2.43.0
ana@laptop:~$ jq --version
jq-1.7
```

Your uv may be newer than this one; anything from 0.11 on behaves the same for this course.

Last, git needs to know who is committing, once per machine. Use your own name and address; the
transcripts here use those of Ana, the developer whose terminal they come from:

```sh
git config --global user.name "Ana Lima"
git config --global user.email ana@example.org
git config --global init.defaultBranch main
```

The third line names the first branch of every new repository `main`, which is what the whole
course calls it.

## What the transcripts print

Every transcript in the course was recorded on Ubuntu 24.04 and shows the prompt
`ana@laptop:~/shipquote$`. Yours shows your own user and machine, and while a virtual environment
is active, `(.venv)` in front of it, which the transcripts leave out. Commit hashes and the hashes
of a built artifact are different on every machine, because they depend on who committed and
when; everything else, test names, counts, prices and error messages, should match what you see.
