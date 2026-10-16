---
title: Installing Python and the libraries
version: 1
---

These steps are for Ubuntu 24.04, which is what you have on the first two paths of the previous
section: on Linux directly, inside WSL on Windows, or in the virtual machine. A Mac and Windows take
a different first step and then the same ones, and the end of this section says where they part.

Open a terminal. Everything below is typed in it.

## Three system packages

```sh
sudo apt update
sudo apt install -y python3-venv git sqlite3
```

**`python3-venv`** lets Python make an isolated environment for the course's libraries, which the
next step does. **`git`** keeps the history of the project from lesson 7, where DVC records versions
of the data beside it. **`sqlite3`** is a command that opens the shop's database and answers SQL
typed at it, which is the quickest way to look at a table.

## An environment for the course

Python on Ubuntu belongs to the system, and the system refuses to let `pip` write into it. The
course's libraries go into a **virtual environment** of their own instead, a directory with its own
copy of Python and its own packages:

```sh
python3 -m venv ~/mlenv
source ~/mlenv/bin/activate
pip install numpy==2.5.3 pandas==3.0.6 scikit-learn==1.9.1 scipy==1.18.1
```

**The versions are pinned** because these libraries change every few months, and a lesson written
against one version and run against another prints different numbers, or fails in a way that looks
like your mistake. `numpy` is arrays of numbers, `pandas` is tables of them, `scikit-learn` is the
learning algorithms, and `scipy` is the statistics lesson 10 uses. Later lessons add MLflow, DVC and
the libraries that serve a model, each with a `pip install` line where it is first needed.

`source ~/mlenv/bin/activate` is what puts the environment's Python first in your path. **Every new
terminal starts with it.** The prompt then begins with `(mlenv)`, which this course's transcripts
leave out.

The check that it all fits together:

```
ana@dev:~$ python --version
Python 3.12.3
ana@dev:~$ pip list 2>/dev/null | grep -E '^(numpy|pandas|scikit-learn|scipy) '
numpy           2.5.3
pandas          3.0.6
scikit-learn    1.9.1
scipy           1.18.1
```

## On a Mac

Install Python 3.12 from `python.org`, and the command-line tools with `xcode-select --install`,
which bring `git`; `sqlite3` is already there. Then open Terminal and follow every step from "An
environment for the course" on. macOS's shell is `zsh`, and the activation command works in it
unchanged. **This was not run for this course**, which was recorded on Linux.

## On Windows

Open PowerShell as administrator and install WSL with Ubuntu:

```sh
wsl --install -d Ubuntu-24.04
```

Restart when it asks, open *Ubuntu 24.04* from the Start menu, choose a user name and a password,
and follow this section from the top, inside it. Keep the project inside WSL's own home directory
rather than under `/mnt/c`, where every file operation crosses into Windows and is slower. **This
command was not run for this course** either.
