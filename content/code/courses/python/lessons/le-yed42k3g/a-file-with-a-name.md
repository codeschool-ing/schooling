---
title: `hello.py`, and the difference between running and importing
version: 1
---

Put this in a file called `hello.py`:

```python
name = "Ada"
print("Hello,", name)
```

Then, in a terminal, in the directory that file is in:

```
python3 hello.py
```

```
Hello, Ada
```

That is the loop you will be in for the rest of this course: edit, save, run, read.

## The name of the file

`.py` is the extension, and it is what your editor reads to decide about colours and indentation.
The rest of the name is yours, with two rules that bite:

**No spaces and no hyphens** — `my-script.py` cannot be imported in lesson 7, because `-` means
subtraction. Use `my_script.py`.

**Do not name it after something in the library.** A file called `random.py` in your directory will
be found before the real `random`, and the error you get says `module 'random' has no attribute
'randint'` — which sounds like the library is broken. It is not; it is your file. Section
`where-python-looks` in lesson 7 is where this becomes precise.

## What running does

`python3 hello.py` reads the file from the top and does each line once. There is no `main` that
gets called; the file itself is the program.

## And what importing does

Lesson 7 covers it properly, but the distinction starts here, because it is the reason for a line
you will see in almost every Python file you ever open:

```python
if __name__ == "__main__":
    main()
```

A file can be **run** or it can be **imported by another file**. Both read it top to bottom. That
line is how a file says *do this part only when I am the one being run*, so that importing it to
borrow a function does not also set the whole program going.

You do not need it today. You need to not be surprised by it.

## Where to run it from

The terminal has a current directory and `python3 hello.py` looks for the file there. If it says
`can't open file`, you are somewhere else — `ls` on macOS and Linux, `dir` on Windows, will tell
you what it can see.
