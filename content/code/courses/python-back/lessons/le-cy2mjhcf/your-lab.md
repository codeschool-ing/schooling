---
title: Your lab is the one the python course built
version: 1
---

Every lesson in this course runs a server, a database or a worker, and the platform runs none of
them for you. **You work on a Linux machine of your own, and it is the same machine the `python`
course had you build**: Ubuntu 24.04 with its own Python 3.12, and uv to manage each project's
packages. If you took that course, you have it already, and this section only checks it. If you did
not, the steps are below in brief, and `python` lesson 1 and lesson 19 explain them in full.

## Three places to have it

| path | what you get | what it costs your computer |
|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04, apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs |
| **installed** | the same tools on the computer you already use | the disk the tools take, plus each service once lessons 4, 13 and 16 add them |
| **online** | a Linux machine with a terminal, in your browser | nothing on your computer; hours from a monthly allowance somebody else sets |

**The virtual machine is the one to pick for this course**, more firmly than for `python`. From
lesson 4 on, the course installs PostgreSQL, then Redis in lesson 13, nginx in lesson 16 and Docker
in lesson 17, and runs them as system services that start when the machine boots. On a computer you
also work on, those collide with whatever else is running there; in a virtual machine they are
yours to break, and a snapshot taken once a lesson works gives you a clean start when an experiment
goes wrong. Use VirtualBox on Windows or Linux, UTM on an Apple-silicon Mac, or WSL running Ubuntu
24.04 on Windows, with 2 GB of memory and a 20 GB disk, as `python` lesson 1 set it up.

**Installed** works as printed on a computer that already runs Ubuntu 24.04. On macOS or Windows,
Python and uv install from their own sites and every lesson's Python code runs the same, but the
services of lessons 4 to 17 install differently and the transcripts here will not match yours; none
of that was run for this course.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser. It costs
your computer nothing, and GitHub gives personal accounts a monthly allowance of hours and charges
past it, on terms it sets and can change. It was not run for this course. Any machine that runs
Ubuntu 24.04 and lets you install packages with `sudo` will do, from any company; nothing here
depends on one of them.

## The setup, in brief

On the machine, in a terminal:

```sh
sudo apt update
sudo apt install -y python3 python3-venv python3-pip pipx git curl
pipx install uv
pipx ensurepath
```

The `apt` line is `python` lesson 1's, with `pipx`, `git` and `curl` beside it. `pipx` installs a
Python program into a directory of its own, which is how uv goes in without touching the Python
that Ubuntu itself runs on. `pipx ensurepath` adds `~/.local/bin` to your `PATH`, which a terminal
reads when it opens, **so close the terminal and open a new one** before the next step.

## Check that each tool answers

```
ana@vm:~$ python3 --version
Python 3.12.3
ana@vm:~$ uv --version
uv 0.13.1 (x86_64-unknown-linux-gnu)
ana@vm:~$ git --version
git version 2.43.0
ana@vm:~$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.7
```

**Python 3.12 is the version this course was recorded with**, and Django 6.1, the version uv
installs today, refuses anything older. Your uv may be newer than 0.13.1, and any 0.13 or later
behaves the same for this course. `curl` is how every lesson talks to a server it has just started,
and `git` is what lessons 15 and 17 put a project under.

## What the transcripts print

Every transcript in the course was recorded on Ubuntu 24.04 by a developer called Ana, on a machine
called `vm`, so the prompt reads `ana@vm:~$`. Yours shows your own user and machine. Dates, times,
process numbers and the milliseconds uv reports differ on every run; everything else, versions,
status codes, file names and error messages, should match what you see. Each library is whatever
PyPI served on the day of the recording, and the lessons print its version where it matters.
