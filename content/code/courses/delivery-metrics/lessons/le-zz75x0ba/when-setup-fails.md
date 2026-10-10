---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, and with Python and no libraries there are only a handful of ways for it to go wrong. Each one has a message you can recognise. The first three below were made on purpose on the computer these lessons were recorded on; the last two were not run here, because they need a system this one is not, and they are described from what those systems print.

## "can't open file"

```
ana@laptop:~/delivery$ python3 biling.py
python3: can't open file '/home/ana/delivery/biling.py': [Errno 2] No such file or directory
```

**The message names the path Python looked for**, and that path is the clue: a typo in the name, as here, or a terminal opened in a different folder. A text editor on Windows may also have saved the file as `billing.py.txt` while showing you `billing.py`; turning on file extensions in the file explorer shows the real name.

## "IndentationError"

```
ana@laptop:~/delivery$ python3 broken.py
  File "/home/ana/delivery/broken.py", line 60
    reviewed.append(name)
IndentationError: expected an indented block after 'if' statement on line 59
```

Python uses the spaces at the start of a line to know which lines belong together, so **a paste that loses them breaks the program**. This copy lost the indentation of one line, and Python names it. Some editors and chat tools strip or convert leading spaces when you paste; copy with the button on the block, paste into a plain text editor, and if the error persists, compare the line it names with the lesson.

## The files went somewhere else

```
ana@laptop:~/delivery$ cd ..
ana@laptop:~$ python3 delivery/billing.py
118 items merged, 17 not yet, 47 deploys
ana@laptop:~$ ls -1 delivery
billing.py
ana@laptop:~$ ls -1 *.csv
deploys.csv
items.csv
```

The program ran and reported success, and the folder still has no data in it. **A program writes its files into the folder you run it from**, not the folder it lives in. Every later program reads `items.csv` from the folder it is run from too, so the rule that makes all of it work is the simplest one: open the terminal in `delivery` and run everything from there. Delete the two stray files and run it again in the right place.

## "python3: command not found", or the Microsoft Store opens

Not run here. On Windows, typing `python3` or `python` in a fresh system can open the Microsoft Store instead of running anything, because Windows ships a shortcut with that name that offers to install Python. If you installed from `python.org`, type `py` instead. On Linux and macOS, `command not found` means Python 3 is not installed, or not on the path; section 04 of this lesson says how to install it.

## "SyntaxError: invalid syntax" on a line with an f in front of a string

Not run here. Lines such as `print(f"{len(days)} days")` need Python 3.6 or newer, and this course asks for 3.8. A `SyntaxError` pointing at one of them means the command ran an old Python, almost always 2.7, kept by some systems for their own tools. `python3 --version` tells you which one you have; use the one that answers 3.8 or later.

## When none of these is it

Read the **last line** of the error first. Python prints the chain of calls that led to the problem, and the line that names it is at the bottom. Search for that exact line, and you will almost always find somebody who hit it before you. If your program runs but prints different numbers from the lesson's, the copy differs from the page somewhere: copy it again, whole, rather than hunting for the difference by eye.
