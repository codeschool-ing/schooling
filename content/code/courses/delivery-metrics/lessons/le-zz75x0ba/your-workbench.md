---
title: The computer you will measure on
version: 1
---

**Most of this course is judgement**: reading a chart, deciding what a number can carry, running an incident. That needs no software. The rest is arithmetic on a team's history, and that arithmetic is done by short programs you run on your own computer. Nothing in this course is hosted for you, and nothing needs to be.

You need **one thing: Python 3**, version 3.8 or newer. Every program in the course uses only what comes with Python itself, so there is nothing to install with `pip`, no account to create and no library whose version can drift. You do not need to be a programmer. Each lesson prints its programs whole, says what each part does, and asks you to run them, change one number, and run them again.

## Three ways to get a working setup

| path | what it costs your computer | when to choose it |
|---|---|---|
| **installed on your computer** (recommended) | about 100 MB of disk; works offline | you have a laptop or desktop you can install software on |
| **in a virtual machine** | 25 GB of disk and 4 GB of memory for an Ubuntu machine in VirtualBox | your computer is not yours to change, or you already work inside a Linux virtual machine |
| **online** | nothing installed; needs an account and a connection | you are on a borrowed or locked-down computer |

**The recommended path is the first.** It is the smallest, it works on a train, and your files stay where you put them. The lessons were recorded on Linux, and every command below is the one typed there.

## Installed: the recommended path

- **Linux**: Python 3 is almost certainly there already, because the system uses it. If it is not, `sudo apt install python3` on Debian or Ubuntu, `sudo dnf install python3` on Fedora.
- **macOS**: download the installer from `python.org`. Recent versions of macOS also offer a `python3` when you install Apple's command line tools; it is older, and still new enough.
- **Windows**: download the installer from `python.org`. It installs a launcher called `py`, so **on Windows, type `py` wherever the lessons type `python3`**.

Then make a folder called `delivery`, open a terminal in it, and ask Python which version it is:

```
ana@laptop:~/delivery$ python3 --version
Python 3.13.16
```

Any version from 3.8 on prints the same results for every program in this course. If yours says 2.7, you have found the old Python that some systems still keep for their own use, and you need `python3` rather than `python`.

## In a virtual machine

If you would rather not install anything on your own system, an Ubuntu virtual machine in VirtualBox has Python 3 from the first boot. Give it 4 GB of memory and 25 GB of disk, install Ubuntu from the official image, and follow the Linux line above inside it. This path costs the most and buys isolation, which matters only if your own computer belongs to somebody else's IT department.

## Online

Two services give you a Python with a terminal in the browser, each with a free monthly allowance at the time of writing: **GitHub Codespaces**, which needs a GitHub account, and **Google Colab**, which needs a Google account. In Codespaces, open the terminal and type the commands as the lessons show them. In Colab, put `%%writefile billing.py` as the first line of a cell, paste the program under it and run the cell to save the file; then run a program in another cell with an exclamation mark in front, `!python3 billing.py`.

Neither is required, and the course depends on neither: if one changes its terms, the other path, or the installed one, gives exactly the same numbers. What you lose online is the habit of running things on your own machine, and the files when the session ends, so keep a copy of anything you change.
