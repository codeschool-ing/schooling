---
title: When the setup fails
version: 1
---

Getting started is where most people give up on a course like this, usually over one line of
output that looked like a disaster and was a small thing. These are the failures that come up while
following the last two sections and the first programs of this lesson, each with what it prints and
what fixes it. The ones with a transcript were produced on purpose, on the machine the transcripts
come from.

## `python: command not found`

```
ana@laptop:~/patterns/oo$ python check.py
bash: line 1: python: command not found
```

Ubuntu installs Python as `python3` and has no plain `python` unless you add a package for it.
An interactive terminal words the message differently and may suggest a package to install; the
cause is the same. **Type `python3`.** On Windows it is the other way round: `py` or `python` work and `python3` may
not. On Windows, a `python` that opens the Microsoft Store instead of running is an *app execution
alias*, a shortcut Windows ships before any Python is installed; installing from python.org with
*Add python.exe to PATH* ticked replaces it. That one was not run for this course.

## `can't open file`

```
ana@laptop:~$ python3 check.py
python3: can't open file '/home/ana/check.py': [Errno 2] No such file or directory
```

The path in the message is the giveaway: Python looked for `check.py` in the home directory,
because that is where the terminal was. **`cd ~/patterns/oo` first**, or give the path,
`python3 ~/patterns/oo/check.py`. The command `pwd` prints which directory a terminal is in.

## A file that lost its indentation

Python reads indentation as structure, so a pasted line with the wrong number of spaces stops the
program before it runs. Here one line of `loan.py`, from the encapsulation section, came in with
two spaces where there should be eight:

```
ana@laptop:~/patterns/oo$ python3 loan.py
due: 2026-03-16
fine on 20 March: 200
fine after return: 100
refused: 'Dom Casmurro' was already returned
```

**The last line is the cause and the line above it is the place**: line 22. Open the file there and
make the indentation match the lines around it. If the editor mixed tabs and spaces, an editor that
shows whitespace makes it visible; set it to insert four spaces for a tab.

## `No module named`

`member.py`, from the composition section, imports `notices.py`. Run it in a directory where
`notices.py` is not, and:

```
ana@laptop:~/patterns/oo$ python3 member.py
e-mail to bia@example.org, subject "Library": Bia, your reservation is ready
SMS to +55 11 5550-0142: Bia, your reservation is ready
```

Python looks for an imported module first in the directory of the program it is running. **Save the
imported file beside the one that imports it**; within a lesson, every program goes in the same
directory, and the lesson says when one file uses another.

## A Python that is too old

`check.py` prints *This course needs Python 3.12 or newer* and stops. This one was not run, because
the machine the transcripts come from has 3.12. Install a newer Python by one of the paths in the
lab section; on Linux, `uv python install 3.12` puts one in your home directory without touching the
system's, and `uv run --python 3.12 check.py` runs a program with it.

## When none of these is it

Read the last line of the output first: Python puts the kind of error and its message there, and
the lines above are the route it took to get there. Search for that last line, in quotes, with the
word Python. Then compare your file with the lesson's, character by character, from the line the
error names; a missing colon or bracket is reported on the line *after* it more often than on its
own.
