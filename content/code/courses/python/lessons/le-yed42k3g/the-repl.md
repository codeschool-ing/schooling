---
title: The prompt that answers back
version: 1
---

Type `python3` with no filename and you get a prompt:

```
Python 3.12.3
>>> 
```

This is the **REPL** — read, evaluate, print, loop. You type an expression, it evaluates it and
shows you the answer, and then it waits again.

```
>>> 2 + 2
4
>>> "ada".upper()
'ADA'
>>> len("hello")
5
```

Notice that it printed those without being asked. In a file you need `print`; at the prompt, the
value of what you typed is shown to you. That difference catches everybody once.

## Three things worth knowing

**`_` is the last value.**

```
>>> 17 * 3
51
>>> _ + 1
52
```

**`help()` reads the documentation to you.** `help(len)` prints what `len` does and what it takes.
`help(str.upper)` does the same for a method. It works on anything, including things you wrote.

**`dir()` lists what is there.** `dir("")` shows every method a string has. It is a long list and
you are not meant to learn it; it is for the moment you think *there must be something that does
this* and you are right.

## Leaving

`exit()` or `quit()`, or `Ctrl-D` on macOS and Linux, `Ctrl-Z` then Enter on Windows.

## When it is the wrong tool

The REPL is for a **question**. What does this method return, is this a list or a tuple, what
happens if the string is empty.

It is the wrong place for **work**, for one reason that is not about preference: nothing you type
there survives closing the window. Anything you will want tomorrow, or want to run twice, goes in a
file. That is the next section, and it is the only habit in this lesson that matters in six months.
