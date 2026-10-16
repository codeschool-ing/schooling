---
title: Your lab, and three ways to have one
version: 1
---

**A manual tester's lab is small**: the application under test, a browser to use it with, and a
terminal for the moments when a browser hides what happened. This course gives you the
application, a single Python file in the next section, and this section gets the rest onto a
computer of your own. Nothing in the course runs anywhere else. There is no server of ours to sign
in to, and the application keeps nothing once you stop it, so you can break it as often as you
like.

The lab is three things:

- **Python 3.10 or newer**, which runs the application. It uses nothing outside Python's own
  standard library, so there is nothing else to install for it;
- **a browser**, the one you already use. Lesson 7 asks for a second one, and says which;
- **a terminal with `curl`**, which sends one request to the application and prints the answer.
  The transcripts in this course use it to show exactly what came back, and lesson 15 uses it to
  write a defect report somebody else can replay.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Python on the computer you already use | about 100 MB of disk | match, apart from paths on Windows |
| **a virtual machine** | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installed is the recommended path**, and the reason is the browser. Testing is done with the
browser you use every day, its developer tools and its narrow-screen mode, and an application
running on the same computer is one address away from it: `http://127.0.0.1:8000`. In a virtual
machine the application sits behind the machine's own network, and reaching it from your browser
is one more thing to set up before you can test anything.

**Installed, on Linux**: Python 3 and curl are almost always there already. On Ubuntu or Debian,
`sudo apt-get install -y python3 curl` adds whichever is missing.

**Installed, on a Mac**: curl comes with macOS. Python 3 comes with Apple's command-line developer
tools, which macOS offers to install the first time you type `python3` in Terminal; the installer
from python.org works too.

**Installed, on Windows 10 or 11**: install Python from python.org and, on the first screen of the
installer, tick **Add python.exe to PATH**. curl ships with Windows. Two differences from the
transcripts follow you through the course: on Windows the command is `python` or `py` rather than
`python3`, and a path reads `C:\Users\ana\boxoffice` rather than `~/boxoffice`. The commands that
pipe one program into another, with `|`, are for a Unix shell; the lessons that use them also say
what to look for in the browser instead. None of the Mac or Windows steps were run for this
course.

**A virtual machine** is the path if you would rather keep the course apart from your own system,
or if your computer will not let you install software. VirtualBox on Windows or Linux and UTM on
an Apple-silicon Mac both run Ubuntu Desktop 24.04, which has Firefox, and everything in this
course happens inside it. On Windows, WSL running Ubuntu 24.04 is a virtual machine too, and the
browser you already have reaches a program running in WSL at `127.0.0.1` the same way.
`virtualization` lesson 4 builds a virtual machine step by step.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal and an editor in the
browser, and forwards the application's port to an address you can open. It costs your computer
nothing; GitHub gives personal accounts a monthly allowance of hours and charges past it, on terms
it sets and can change. It was not run for this course, and the address it gives you replaces
`127.0.0.1:8000` everywhere.

## Checking it

Open a terminal and ask each tool for its version:

```
ana@laptop:~/boxoffice$ python3 --version
Python 3.13.16
ana@laptop:~/boxoffice$ curl --version | head -n 1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
```

Any Python from 3.10 on runs the application, and any curl does what this course asks of it, so a
different number on either line is fine. A `command not found` is not, and the section after next
says what to do about it.

## What the transcripts print

Every transcript in this course was recorded on Ubuntu 24.04, as Ana, the tester whose terminal
they come from, and shows her prompt: `ana@laptop:~/boxoffice$`. Yours shows your own name and
computer. Two things in them depend on the day they were recorded and will differ on yours: **the
dates of the shows** and **the links in the confirmation e-mails**. Everything else, the messages,
the prices, the order numbers and the states, should match what you see once you have reset the
application the way the next section says.
