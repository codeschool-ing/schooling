---
title: The lab, and three ways to build it
version: 1
---

**Most of this course is thinking, and some of it has to be done with your hands.** You will read a
small program the way a tester reads one, run it with inputs you chose, catch it giving a wrong
answer, and later watch the tests that would have caught it first being written. The platform runs
nothing for you. This section builds the machine you do that on, and it is the only setup the course
asks for.

**You do not need to know how to program.** Every program in the course is printed whole in the
lesson that uses it, with a note beside each part saying what it does. What you type is a command
that runs a program, never the program itself; from lesson 15 on you also copy tests from the page
and run them. Reading a program well enough to doubt it is a tester's skill, and this course teaches
it; writing one is a later course's.

The lab is **one directory, one Python and one tool**:

- `~/aurora`, a directory where every program in the course is saved and run;
- **Python 3.10 or newer**, which runs the programs. Everything in the course uses Python's own
  standard library, apart from one tool;
- a **virtual environment** in `~/aurora/.venv` holding that tool, **behave**, which reads the
  plain-language test scenarios of lessons 16 and 17 and runs them.

You also need a **plain-text editor** to save the programs: one that writes exactly the characters
you typed and nothing else. Visual Studio Code is free on every system and a good one; so are gedit
on Linux, TextEdit in plain-text mode on macOS, and Notepad++ on Windows. A word processor is not,
because it adds formatting a program cannot read.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the lab on the computer you already use | 19 MB for the environment, plus Python itself where the system lacks it; nothing running when you are not | match on Ubuntu 24.04; close elsewhere |
| **a virtual machine** | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installed is the recommended path.** The lab is a directory: it changes nothing else on the
computer, starts nothing in the background, and deleting `~/aurora` removes every trace of this
course. Python runs on Windows, macOS and Linux alike, and behave is written in Python, so there is
nothing to compile on any of them. On Windows two of the commands below are spelt differently, and the
section says which.

**A virtual machine** is the path if you would rather keep your own system untouched, or if the
computer is one you may not install software on. VirtualBox is free and runs Ubuntu Server 24.04 in
2 GB of memory; `virtualization` lesson 4 builds one step by step. On Windows, WSL running Ubuntu
24.04 is a virtual machine too, and the Linux commands below work in it as printed. Every transcript in
this course was recorded on Ubuntu 24.04 with Python 3.12, on a machine called `lab`, as a user called
`lia`. Yours will print your own names.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser, and it costs
your computer nothing. GitHub gives personal accounts a monthly allowance of hours and charges past
it, on terms it sets and can change; any service that gives you a terminal and a `python3` will do.
It was not run for this course, and `python3 --version` tells you what you have before you start.

## Building it

Python comes with Ubuntu. On Windows and macOS, install it from python.org, and on Windows tick the box
that adds it to the `PATH` on the installer's first screen. Anything from 3.10 up will do.

On Ubuntu and Debian, the module that makes virtual environments is a package of its own. Install it
first:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
```

On Windows and macOS the Python from python.org already has it, and you skip those two lines.

Then the directory, the environment and the tool. The version is pinned, because lessons 16 and 17
print what behave prints, and a newer version can word its summary differently:

```sh
mkdir ~/aurora
cd ~/aurora
python3 -m venv .venv
source .venv/bin/activate
pip install behave==1.3.3
```

On Windows, in PowerShell, the fourth line is `.venv\Scripts\Activate.ps1`, and `python3` is `py`.

`source` **activates** the environment: from then on, in that terminal, `python` and `pip` are the
ones inside `.venv`, and the prompt starts with `(.venv)`. The transcripts in this course leave that
prefix out, so the lines are shorter; everything after it is what you will see.

Last, two lines at the end of `~/.bashrc`, so that every new terminal starts with the environment
already active and in the course's directory:

```sh
printf 'source ~/aurora/.venv/bin/activate\ncd ~/aurora\n' >> ~/.bashrc
```

On Windows, leave this step out and activate the environment by hand in each new terminal. Open a new
terminal and check:

```
lia@lab:~/aurora$ python --version
Python 3.12.3
lia@lab:~/aurora$ which python
/home/lia/aurora/.venv/bin/python
lia@lab:~/aurora$ behave --version
behave 1.3.3
```

That is the lab. It cost this much disk:

```
lia@lab:~/aurora$ du -sh .venv
19M	.venv
```

If you are on a virtual machine, take a snapshot now: an experiment that goes wrong later is then one
click from undone.
