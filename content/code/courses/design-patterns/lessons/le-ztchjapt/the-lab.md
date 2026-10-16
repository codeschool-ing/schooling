---
title: Your lab, and three ways to have one
version: 1
---

**This course runs every program it shows, and you run them too, on a machine of your own.** The
platform gives you no machine. What you need is small: Python 3.12 or newer, a terminal and a text
editor. No database, no server, no package from outside Python's standard library, in any lesson.
Lesson 10 uses SQLite, and SQLite comes inside Python as the `sqlite3` module.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Python on the computer you already use | about 100 MB of disk | match as printed on Ubuntu 24.04; close elsewhere |
| **a virtual machine** | Ubuntu 24.04, apart from your own system | about 25 GB of disk, and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine with a terminal in the browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installing is the recommended path**, because nothing in this course listens on a port, writes
outside `~/patterns` or needs administrator rights after Python is in place. There is nothing a
virtual machine would protect you from.

- **Linux.** Ubuntu 24.04 already has Python 3.12 as `python3`. Fedora 40 and later ship a newer
  one. On a distribution whose Python is older than 3.12, such as Debian 12 with 3.11, use the
  virtual machine or the tool `uv`, which installs a separate Python for your user with
  `uv python install 3.12` and leaves the system's alone.
- **macOS.** Download the installer for the newest Python 3 from python.org, or run
  `brew install python@3.12` if you use Homebrew. The command is `python3`.
- **Windows.** Download the installer from python.org and tick *Add python.exe to PATH* on its first
  screen, or run `winget install Python.Python.3.12` in a terminal. The command is `py` or
  `python`; where this course types `python3`, type that instead. The paths in the transcripts are
  Linux paths, so `~/patterns/oo` is `C:\Users\<you>\patterns\oo` on your machine.

**A virtual machine** is the right choice when the computer is not yours to install on, such as a
work laptop with a locked-down administrator account. Any hypervisor does: VirtualBox on Windows or
Linux, UTM on an Apple-silicon Mac, Hyper-V on Windows if it is switched on, with the Ubuntu Server
24.04 image from ubuntu.com. `virtualization` lesson 4 builds one in VirtualBox step by step. On
Windows, WSL running Ubuntu 24.04 is also a virtual machine and works the same way.

**Online**, a browser-based environment such as GitHub Codespaces gives you a Linux terminal and an
editor with Python already on it. It costs your computer nothing; the hours come from a monthly
allowance on terms the company sets and can change, so do not let the course depend on one free
tier. It was not run for this course; `python3 --version` tells you before you start whether its
Python is new enough.

Only the first row on Ubuntu 24.04 was run for this course. The macOS, Windows and online
instructions follow each vendor's own documentation and were not run, so a path or a version in a
transcript may differ from what your machine prints.

## An editor

Any editor that saves plain text works. If you already write code in one, use it. If not, Visual
Studio Code, which is free, highlights Python and has a terminal built in, so the program and the
command that runs it share a window. What matters for this course is that the editor indents with
**spaces, four at a time**, which is what every program here uses and what Python's style guide
asks for.
