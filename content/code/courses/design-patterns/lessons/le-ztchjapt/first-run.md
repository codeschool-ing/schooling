---
title: The first run
version: 1
---

**Before the first lesson asks you to run anything, check the one thing the whole course
depends on.** Open a terminal on the machine you chose and ask Python which version it is:

```
ana@laptop:~$ python3 --version
Python 3.12.3
```

That is Ubuntu 24.04's own Python, the one every transcript in this course was recorded with.
Anything from 3.12 up works. On Windows, ask `py --version`.

Every lesson keeps its programs in a directory of its own under `~/patterns`, so that two lessons
never overwrite each other's `main.py`. Make the directory for this lesson and go into it:

```sh
mkdir -p ~/patterns/oo
cd ~/patterns/oo
```

Then save this program as `check.py` in that directory. It is the course's way of saying the lab is
ready, and it refuses politely on a Python that is too old:

```python
# check.py
import platform
import sys

need = (3, 12)
have = sys.version_info[:2]
print("Python", platform.python_version(), "on", platform.system())
if have < need:
    print(f"This course needs Python {need[0]}.{need[1]} or newer.")
    sys.exit(1)
print("Ready for the course.")
```

```
ana@laptop:~/patterns/oo$ python3 check.py
Python 3.12.3 on Linux
Ready for the course.
```

`platform.system()` answers `Darwin` on a Mac and `Windows` on Windows; the second line is what
matters. If yours printed it, every program in the course will run on your machine. If it did not,
the next section has what goes wrong and how to get past it.

## What the transcripts print

The transcripts are recorded as Ana, a developer at the library, on a machine called `laptop`, so
the prompt reads `ana@laptop:~/patterns/oo$`. Yours shows your own name, machine and directory.
Everything after the prompt is what the program printed, byte for byte. When a program prints
something that changes from run to run, like a time or the order threads finished in, the lesson
says so beside it.
