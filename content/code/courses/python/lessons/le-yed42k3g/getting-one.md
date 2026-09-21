---
title: `python3`, and the three you are likely to meet
version: 1
---

There is probably a Python on your machine already, and it is probably not the one you want to use
for your own work. Three arrive by different routes.

| | where it came from | what to do with it |
|---|---|---|
| **the system's** | shipped with macOS or your Linux distribution | leave it alone; things you did not install depend on it |
| **python.org's** | you downloaded and installed it | this is the one to use |
| **a manager's** | `pyenv`, Homebrew, `uv`, the Microsoft Store | fine, and know which one is answering |

## Check what you have

```
python3 --version
```

Anything from **3.10** upwards is enough for everything in this course. Below that, some of the
syntax in later lessons will not parse.

## `python3` and not `python`

On most machines `python` either does not exist or is the ancient 2.x that a few old scripts still
want. Python 2 has been out of support since 2020 and its `print` is a statement rather than a
function, which is why a copied example from a fifteen-year-old answer sometimes fails on the first
line.

**Type `python3`.** On Windows the launcher is `py` and `py -3` is the same idea.

## Installing one

**Windows:** the installer from python.org, and **tick "Add python.exe to PATH"** on the first
screen. That box is the single most common reason a fresh Windows install answers
`'python' is not recognized`.

**macOS:** the installer from python.org, or `brew install python`.

**Linux:** you already have one. `sudo apt install python3-venv python3-pip` on Debian and Ubuntu
gets you the two pieces that are packaged separately and that lesson 18 needs.

## The one thing not to do yet

Do not start installing libraries into whichever Python answers. That is lesson 18, and it has its
own section on why the system's interpreter is not yours to fill up.
