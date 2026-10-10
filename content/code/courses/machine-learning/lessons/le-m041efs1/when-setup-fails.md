---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, and nearly always over one of a
handful of problems. Each one prints a message you can recognise. **Read the last line of an
error first**: Python prints the chain of calls that led to the problem, and the line that names
the problem is at the bottom.

## "No module named 'numpy'"

The program ran in the wrong Python. `deactivate` here stands for a terminal where the
environment was never activated, which is what you get in a terminal opened before `~/.bashrc`
had its new lines:

```
ana@lab:~/ml$ deactivate
ana@lab:~/ml$ python3 make_data.py
Traceback (most recent call last):
  File "/home/ana/ml/make_data.py", line 6, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
```

`python3` is the system's own, and NumPy was installed into the environment's. Open a new
terminal, or type `source ~/ml/.venv/bin/activate`, and run it again. `which python` answers which
one you are about to run: it should print a path inside `~/ml/.venv`.

## "externally-managed-environment"

The same mistake made one step earlier, when installing:

```
ana@lab:~/ml$ deactivate
ana@lab:~/ml$ python3 -m pip install -r requirements.txt
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**Ubuntu refuses to let pip change the Python the system itself runs on**, because an upgrade
there could break programs the system depends on. The message suggests a virtual environment, and
`~/ml/.venv` is one. Activate it and install again. Do not pass `--break-system-packages`: the
name is accurate.

If `python3 -m venv .venv` itself fails on Ubuntu or Debian with a message that mentions
`ensurepip`, the module that builds environments is packaged separately. `sudo apt-get install
python3-venv` adds it.

## "can't open file"

The program found Python but not itself:

```
ana@lab:~/ml$ cd ~
ana@lab:~$ python make_data.py
python: can't open file '/home/ana/make_data.py': [Errno 2] No such file or directory
```

The message names the path it looked in, and that is the clue: the terminal was in a different
folder. Every program in this course reads `data/` relative to the folder it runs from, so `cd
~/ml` before running anything.

## "No matching distribution found"

pip reached the index and found nothing by that name:

```
ana@lab:~/ml$ cd ~/broken
ana@lab:~/broken$ pip install --quiet -r requirements.txt
ERROR: Could not find a version that satisfies the requirement scikit-lean==1.9.1 (from versions: none)
ERROR: No matching distribution found for scikit-lean==1.9.1
```

`scikit-lean` is a typo, and pip cannot tell a typo from a library that does not exist. **The
same message appears for a version that does not exist**, and for a version that exists but not
for your Python: a Python older than 3.12 is the usual cause, and `python3 --version` settles it.

## pip cannot reach the internet

A message that mentions `SSL`, `certificate`, `ProxyError` or `Connection` means something between
you and the index: a company proxy, a school network, a firewall. Try once from another network.
If it works there, the problem is the network rather than the setup, and the people who run that
network are the ones who can fix it.

## When none of these is it

Copy the last line of the error and search for it with the library's name beside it. Somebody has
nearly always met it before. **If you have changed many things trying to fix it, start again**:
delete `~/ml/.venv` and run the four lines of the install again. It takes a few minutes and puts
you back on a known footing, which is worth more than an afternoon of patching an environment
nobody can describe.
