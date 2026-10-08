---
title: When the setup fails
version: 1
---

Most setups fail in one of four ways, and the machine names each of them. The transcripts here were
taken on a fresh Ubuntu 24.04, the system the virtual machine path installs, on a machine called
`lab` with a user called `ana`. Yours will print your own names.

## `python` is not found

```
ana@lab:~$ python
Command 'python' not found, did you mean:
  command 'python3' from deb python3
  command 'python' from deb python-is-python3
ana@lab:~$ python3 --version
Python 3.12.3
```

**Ubuntu has no `python`, only `python3`**, and it says so: the first suggestion is the program
you already have. Type `python3`, as every lesson here does. The second suggestion is a package that
makes `python` a second name for it, which you do not need.

## `pip` is not found, and a virtual environment will not build

```
ana@lab:~$ pip --version
Command 'pip' not found, but can be installed with:
sudo apt install python3-pip
ana@lab:~$ python3 -m venv .venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/.venv/bin/python3

```

Both are one cause: **the `apt` line in the previous section was skipped.** Ubuntu packages `pip`
and `venv` apart from Python itself, so a fresh machine has the interpreter and not the two
pieces lesson 18 builds on. Both messages name the package that is missing. Run that `apt` line,
then try again:

```
ana@lab:~$ python3 -m venv .venv
ana@lab:~$ ls .venv
bin  include  lib  lib64  pyvenv.cfg
ana@lab:~$ pip --version
pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.12)
```

No output from `venv` is success. Lesson 18 explains what that directory is; until then,
`rm -r .venv` removes it.

## Windows says `'python' is not recognized`

The box **"Add python.exe to PATH"** on the installer's first screen was left empty, so the
terminal cannot find the program it installed. Run the installer again, choose **Modify**, and
tick **"Add Python to environment variables"** under the advanced options. Then close the terminal
and open a new one, because a terminal reads the PATH once, when it starts.

If instead typing `python` opens the Microsoft Store, Windows is answering with a shortcut of its
own. Use `py`, the launcher the installer puts there, or switch the shortcut off under
*Settings > Apps > Advanced app settings > App execution aliases*. Neither was run for this
course, which was recorded on Linux.

## The version is too old

`python3 --version` answering 3.9 or lower is an operating system that is several years old. Don't
upgrade the system's Python, which other programs on it depend on: on macOS install python.org's
alongside it, and on an old Linux take the virtual machine path, which gives you 3.12 without
touching what is there.

## Anything else

**Read what it printed before you search for it.** A failed install often prints a page, and the
first line that says `error` is the cause; the lines after it are usually its consequences. A
message that names a package to install, like the two above, means exactly that. It is the same
habit as reading a traceback, which is where this lesson goes after the REPL.
