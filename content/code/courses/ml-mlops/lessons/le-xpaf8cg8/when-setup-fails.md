---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up here, on an error about something they have
only just installed. These are the failures the recording machine produced while this lesson was
being written, in the order you would meet them, each as it printed it and with what it means.

## The environment cannot be made

```
ana@dev:~$ python3 -m venv ~/mlenv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/mlenv/bin/python3
```

`venv` makes the environment and then installs `pip` into it, and the second half needs a package
Ubuntu leaves out. **The message says the fix**: `sudo apt install python3-venv`, which the first
command of the previous section does. It also leaves a half-made `~/mlenv` behind; delete it with
`rm -rf ~/mlenv` before you run `python3 -m venv ~/mlenv` again.

## pip refuses to install anything

```
ana@dev:~$ pip install scikit-learn==1.9.1
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

This is `pip` outside the environment, trying to write into the system's own Python, and Ubuntu
refuses on purpose: a library installed there can break programs the system itself runs. **It is
not asking you to pass `--break-system-packages`.** It means the environment is not active in this
terminal. Run `source ~/mlenv/bin/activate`, and the same `pip install` works.

## A program cannot find a library you installed

```
ana@dev:~$ cd ~/ml && python3 generate.py
Traceback (most recent call last):
  File "/home/ana/ml/generate.py", line 15, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
```

The same cause from the other side: a new terminal, the environment not activated, and `python3`
is the system's, which has none of the course's libraries. `which python` answers the question
when you are not sure; inside the environment it prints a path under `~/mlenv`.

## A table that does not exist, in a file that does

```
ana@dev:~$ python ml/supervised.py 2>&1 | tail -n 3
FROM members m JOIN recent r USING (member_id)
GROUP BY m.member_id
': no such table: members
ana@dev:~$ ls -l shop.db
-rw-r--r-- 1 ana ana 0 Oct 10 04:09 shop.db
```

**This is the one that costs an afternoon.** The program was run from the home directory instead
of `~/ml`. It opens `shop.db` by a relative name, so it looked for the file in the directory it was
started from, and SQLite, asked to open a file that is not there, **creates it, empty**, rather
than failing. The error is about a table, which sends you looking at the SQL. The empty file left
behind, zero bytes, is the evidence. Delete it and run the program from `~/ml`.

The programs in this course all expect to be run from `~/ml`. Lesson 5 says why a pipeline should
name its files in full instead, and from then on the programs do.

## The network is the problem

`pip` needs to reach `pypi.org`. On a network with a proxy, the error mentions a timeout, a
certificate or `ProxyError`, and the fix is the network's, not Python's: the proxy's address in
`HTTPS_PROXY`, and its certificate where your system keeps trusted ones. That failure was not
reproduced for this course, so there is no transcript of it here.
