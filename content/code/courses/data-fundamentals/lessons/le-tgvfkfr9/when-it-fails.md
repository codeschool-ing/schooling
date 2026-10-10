---
title: When the setup fails
version: 1
---

**Most setups that fail, fail in one of three ways, and each one prints a message that names it.**
Read the message before anything else; the first error is the one that matters, and the lines after it
are usually its consequences.

## The module for virtual environments is missing

On Ubuntu and Debian, `python3 -m venv` without the `python3-venv` package stops at once:

```
ana@lab:~/roda$ python3 -m venv .venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/roda/.venv/bin/python3
```

The message is unusually helpful: it names the package, and the command. The package it names,
`python3.12-venv`, is the one `python3-venv` pulls in, so either works. Install it with `sudo`, delete the
half-made directory with `rm -rf .venv`, and run `python3 -m venv .venv` again.

## The environment is not active

The commonest failure of all, and the one that looks most like something broken. In a terminal where
the environment was never activated — one opened before the lines went into `~/.bashrc`, or any
terminal on Windows — `python3` is the system's, which has never heard of pyarrow:

```
ana@lab:~/roda$ python3 -c "import pyarrow"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'pyarrow'
ana@lab:~/roda$ source .venv/bin/activate
ana@lab:~/roda$ python3 -c "import pyarrow"
```

Nothing was wrong with the installation. Activating the environment makes the same line print
nothing, which for an `import` means it worked. On Windows, if PowerShell refuses to run
`Activate.ps1` with a message about execution policies, running
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once allows scripts you made yourself; that
case was not run for this course.

## The version does not exist for your Python

`pip` answers a pinned version it cannot find with the list of the ones it can:

```
ana@lab:~/roda$ pip install pyarrow==99.0.0 2>&1 | tail -2
ERROR: Could not find a version that satisfies the requirement pyarrow==99.0.0 (from versions: 0.9.0, 0.10.0, 0.11.0, 0.11.1, 0.12.0, 0.12.1, 0.13.0, 0.14.0, 0.15.1, 0.16.0, 0.17.0, 0.17.1, 1.0.0, 1.0.1, 2.0.0, 3.0.0, 4.0.0, 4.0.1, 5.0.0, 6.0.0, 6.0.1, 7.0.0, 8.0.0, 9.0.0, 10.0.0, 10.0.1, 11.0.0, 12.0.0, 12.0.1, 13.0.0, 14.0.0, 14.0.1, 14.0.2, 15.0.0, 15.0.1, 15.0.2, 16.0.0, 16.1.0, 17.0.0, 18.0.0, 18.1.0, 19.0.0, 19.0.1, 20.0.0, 21.0.0, 22.0.0, 23.0.0, 23.0.1, 24.0.0, 25.0.0, 25.0.1, 26.0.0)
ERROR: No matching distribution found for pyarrow==99.0.0
```

Here the version was mistyped on purpose. The same message appears for a version that exists but has
no package for your Python, and that is the likelier case: pyarrow 26.0.0 needs Python 3.11 or newer,
and Ubuntu 22.04's own Python is 3.10. Check `python3 --version` first. If yours is older, `python`
lesson 1 installs a newer one.

## Anything else

Two habits get past almost everything that is not on this list. **Copy the last line of the error into
a search engine, in quotes**: somebody has had it before. And **start again from nothing**, which in
this lab costs one minute: `rm -rf ~/roda`, then the commands from the previous section. A lab you can
throw away and rebuild is a lab you are not afraid to break, and the course will break it on purpose
more than once.
