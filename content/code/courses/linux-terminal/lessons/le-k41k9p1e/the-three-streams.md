---
title: Three streams, and why two of them look the same
version: 1
---

Section 98 gave you the numbers. This is what they are for.

Every program starts with three connections already open, and it does not have to ask for any of
them:

| | | |
|---|---|---|
| `0` | **stdin** | where input comes from. Your keyboard, a file, another program |
| `1` | **stdout** | where its **results** go |
| `2` | **stderr** | where its **complaints** go |

**Both `1` and `2` land on your screen by default**, which is why they look like one thing. They are
not, and the whole of the next section depends on knowing it.

Here is the difference, visible:

```
ana@vm:~/work$ ls logs nosuchdir
ls: cannot access 'nosuchdir': No such file or directory
logs:
access.log  app.log  app.log.1  empty.log  error.log
ana@vm:~/work$ ls logs nosuchdir > out.txt
ls: cannot access 'nosuchdir': No such file or directory
ana@vm:~/work$ cat out.txt
logs:
access.log
app.log
app.log.1
empty.log
error.log
```

One command, two destinations. `> out.txt` captured the listing and **the error stayed on the
screen**, because `>` redirects stdout and nothing else.

That is not a quirk; it is the design. The results go somewhere a program can read them; the
complaints go where a person can see them. A pipeline that swallowed its own error messages would
be much harder to debug than one that does not.

## And notice what changed shape

Look at those two outputs again. On the screen, `ls` printed the five names **across the line, in
columns**. In the file, it printed them **one per line**.

**`ls` asks whether its output is a terminal, and formats accordingly** — the `isatty()` question
from lesson 6. Columns are for people; one per line is for programs.

This matters more than it looks. It means:

- `ls | wc -l` counts files correctly, because `ls` switched to one per line for the pipe;
- and it means the thing you saw on screen is not always the thing the next command received.

Most tools do not do this. `ls`, `grep` (colour), and `ps` (width) are the three you will meet that
do. **When a pipeline behaves differently from what you saw, this is the first thing to suspect.**

## Where the streams actually go

```
ana@vm:~/work$ ls -l /proc/$FDPID/fd
total 0
lr-x------ 1 ana ana 64 Sep 15 07:23 0 -> /dev/null
l-wx------ 1 ana ana 64 Sep 15 07:23 1 -> /tmp/out.txt
l-wx------ 1 ana ana 64 Sep 15 07:23 2 -> /tmp/err.txt
```

That is lesson 6's transcript, and it is worth a second look now that the numbers mean something.
**Redirection is not a feature of the program.** The program writes to descriptor 1; the shell
decided what descriptor 1 was, before the program started, in section 88's gap between `fork` and
`exec`.

Which is why `>` works on every command ever written, including ones whose authors never thought
about files.

## Reading from stdin

Most of the tools in this lesson take a filename **or** read stdin if you do not give them one:

```
wc -l logs/app.log        # from a file
wc -l < logs/app.log      # from stdin, redirected by the shell
cat logs/app.log | wc -l  # from stdin, through a pipe
```

All three count the same thing. The difference is only who opens the file:

```
ana@vm:~/work$ wc -l logs/app.log
30 logs/app.log
ana@vm:~/work$ wc -l < logs/app.log
30
```

**`wc` printed the filename in the first and not in the second**, because in the second it never
knew one. That is a small thing that catches people out in scripts: the output format changed
because of how the input arrived.

**A `-` as a filename means stdin** in many tools, which is how you mix the two:

```
ana@vm:~/work$ printf "header\n" > /tmp/h.txt; printf "body\n" | cat /tmp/h.txt -
header
body
```

A file, then whatever was piped in, in that order — because that is the order the arguments are
in.
