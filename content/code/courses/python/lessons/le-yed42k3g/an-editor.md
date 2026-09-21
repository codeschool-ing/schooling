---
title: What an editor gives you that the prompt does not
version: 1
---

You can write Python in any text editor, including the one that came with your operating system.
You should not, and the reason is not comfort.

## The four things that matter

**It knows the file is Python.** Which means the colours are meaningful — an unterminated string is
the wrong colour from the quote onwards, and you see it before you run anything.

**It indents for you, in spaces.** The previous section's `TabError` is a class of bug that simply
stops existing once the editor is set to insert four spaces for the Tab key.

**It tells you the name does not exist**, before you run it. Most editors run a small checker as
you type; the misspelling that produced the `NameError` in the demonstration is underlined while
you are still on the line.

**And it can run the file** without you switching windows, which sounds like a convenience and is
actually the thing that makes the edit-run-read loop fast enough to learn in.

## The two settings to make now

Whatever editor you pick:

1. **Insert spaces instead of tabs, four of them.**
2. **Show whitespace**, at least on request. Indentation being the syntax means a stray space is a
   syntax question, and it is the one kind of bug you cannot see.

## What to use

**VS Code** with the Python extension is what most people use and what most tutorials assume.
**PyCharm** is heavier and knows more about your code. **Vim**, **Emacs** or **Helix** if you
already live in one — `linux-terminal` lesson 12 is the course for that, and this is not the week
to start.

None of this is a requirement. `hello.py` written in Notepad runs exactly the same. The editor is
how fast you find out you were wrong, which over a course this long is most of the learning.
