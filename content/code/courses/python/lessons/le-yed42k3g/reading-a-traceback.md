---
title: Read it from the bottom
version: 1
---

This is the most useful section in the lesson and possibly in the first half of the course.

When Python cannot do what a line says, it stops and prints a **traceback**. It looks like a wall.
It is four facts in a fixed order, and the order is upside down on purpose.

```
Traceback (most recent call last):
  File "/home/ada/greet.py", line 2, in <module>
    greeting = "Hello, " + nmae
                           ^^^^
NameError: name 'nmae' is not defined
```

## Bottom line first: what happened

`NameError: name 'nmae' is not defined`

Two halves. **`NameError`** is the kind of failure — one of maybe a dozen you will meet in your
first month, and lesson 8 names them all. **The text after the colon** is the specific complaint,
written for a person.

## Second from the bottom: where

`File "/home/ada/greet.py", line 2` — the file and the line the interpreter was standing on. Then
the line itself, quoted back, with `^^^^` under the part it could not resolve.

That caret is doing real work. In a long line with four function calls in it, the caret says which
one.

## The top: how it got there

`Traceback (most recent call last)` means what it says: the list above the error is the chain of
calls that led here, **oldest first**. In a one-file program it is one line and you can ignore it.
When your program has functions calling functions, this is the part that tells you the route.

## Why upside down

Because the last line is the answer, and the answer should be closest to where your eye already is
— at the bottom of the terminal, where you just pressed Enter.

## The four you will meet this week

| | it means |
|---|---|
| `NameError` | you used a word Python has no meaning for — usually a typo, sometimes a missing import |
| `SyntaxError` | the file could not be read at all; nothing ran |
| `TypeError` | the operation is real but not for these types — `"2" + 2` |
| `IndentationError` | the spaces at the start of a line do not line up |

**`SyntaxError` is the odd one out**, and it is worth knowing why: the others happen while your
program is running, so anything above the failing line already happened. A `SyntaxError` happens
*before* anything runs, because the interpreter could not finish reading the file. If you see one,
no part of your program executed — not even the `print` on line 1.
