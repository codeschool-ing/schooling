---
title: When the setup fails
version: 1
---

**Most setups that fail, fail in one of three ways, and each one prints a message that names it.**
Read the message before anything else. The first error is the one that matters; the lines after it are
usually its consequences. This is also the first piece of testing in the course: a message is evidence,
and you read evidence before you guess.

## The module for virtual environments is missing

On Ubuntu and Debian, `python3 -m venv` without the `python3-venv` package stops at once:

```
lia@lab:~/aurora$ python3 -m venv .venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/lia/aurora/.venv/bin/python3
```

The message names the package and the command. The package it names, `python3.12-venv`, is the one
`python3-venv` pulls in, so either works. Install it with `sudo`, delete the half-made directory with
`rm -rf .venv`, and run `python3 -m venv .venv` again.

## The environment is not active

The commonest failure of all, and the one that looks most like something broken. In a terminal where
the environment was never activated — one opened before the lines went into `~/.bashrc`, or any
terminal on Windows — `python3` is the system's, which has never heard of behave:

```
lia@lab:~/aurora$ python3 -c "import behave"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'behave'
lia@lab:~/aurora$ source .venv/bin/activate
lia@lab:~/aurora$ python3 -c "import behave"
```

Nothing was wrong with the installation. Activating the environment makes the same line print
nothing, which for an `import` means it worked. On Windows, if PowerShell refuses to run `Activate.ps1`
with a message about execution policies, running `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
once allows scripts you made yourself; that case was not run for this course.

## The version does not exist

`pip` answers a pinned version it cannot find with the list of the ones it can:

```
lia@lab:~/aurora$ pip install behave==1.3.9 2>&1 | tail -2
ERROR: Could not find a version that satisfies the requirement behave==1.3.9 (from versions: 1.0.0, 1.1.0, 1.2.0, 1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6, 1.2.7.dev6, 1.2.7.dev8, 1.3.0, 1.3.1, 1.3.2, 1.3.3)
ERROR: No matching distribution found for behave==1.3.9
```

Here the version was mistyped on purpose, `1.3.9` for `1.3.3`. The list is the useful part: it shows
what exists, so a typo is visible at a glance. If your Python is older than 3.10, `pip` may offer an
older behave or none, and the fix is a newer Python rather than a different version of the tool;
`python3 --version` says which you have.

## Anything else

Two habits get past almost everything that is not on this list. **Copy the last line of the error into
a search engine, in quotes**: somebody has had it before. And **start again from nothing**, which in
this lab costs one minute: `rm -rf ~/aurora`, then the commands from the previous section. A lab you can
throw away and rebuild is a lab you are not afraid to break, and testing is mostly breaking things on
purpose.
