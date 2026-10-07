---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, and almost always over one of five
problems. Each has a message you can recognise and a fix that takes a minute.

## "No module named 'matplotlib'"

```
ana@vm:~/viz$ python3 bars.py
Traceback (most recent call last):
  File "/home/ana/viz/bars.py", line 2, in <module>
    import matplotlib.pyplot as plt
ModuleNotFoundError: No module named 'matplotlib'
```

**The program ran in the wrong Python.** `python3` is the system's, and matplotlib was installed in
the virtual environment's. Run it as `.venv/bin/python bars.py`, or activate the environment
first. On some computers the system Python happens to have matplotlib too, and then the mistake
stays hidden until the day the two versions differ.

## "can't open file"

```
ana@vm:~/viz$ .venv/bin/python bar.py
.venv/bin/python: can't open file '/home/ana/viz/bar.py': [Errno 2] No such file or directory
```

The message names the path it looked for, and that path is the clue: a typo in the name, as
here, or a terminal opened in a different folder. `ls` shows what is really there.

## "No such file or directory: 'monthly.csv'"

The program found itself but not its data. The CSV files are written by `horta.py` **into the
folder you run it from**, and the programs read them from the folder *they* are run from. Run
everything from the course folder and the problem disappears.

## pip says "externally-managed-environment"

Recent Linux distributions refuse `pip install` into the system's own Python, to protect the
packages the system depends on. **That is the reason for the virtual environment**: install into
`.venv`, never with `sudo pip`. If `python3 -m venv` itself fails on Ubuntu or Debian, the module is
packaged separately: `sudo apt install python3-venv`.

## pip cannot reach the internet

A message mentioning `SSL`, `certificate` or `Could not find a version` usually means a network in
between: a company proxy, a school firewall. Try from another network once; if it works there, the
problem is the network and not your setup, and the online path in "The computer you will draw on" avoids
it entirely.

## When none of these is it

Read the **last line** of the error first. Python prints the whole chain of calls that led to the
problem, and the line that names it is at the bottom. Search for that exact line with the word
`matplotlib`, and you will almost always find somebody who hit it before you.
