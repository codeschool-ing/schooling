---
title: Spaces, and capital letters
version: 1
---

Two things that are invisible on a desktop decide whether a command works.

## A space separates words

The shell splits what you type at every space, and `cd` received two words:

```
ana@server:~$ cd office
ana@server:~/office$ cd invoices 2026
bash: cd: too many arguments
ana@server:~/office$ cd "invoices 2026"
ana@server:~/office/invoices 2026$ pwd
/home/ana/office/invoices 2026
```

`cd invoices 2026` asked `cd` to go to `invoices` *and* `2026`, and `cd` goes to one place. **Quotes
make one word of it**, and so does a backslash before the space: `cd invoices\ 2026`. The error is
harmless here; the same mistake with a command that deletes can remove two things instead of one.

**The Tab key does the quoting for you.** Type `cd inv` and press Tab: the shell completes the name
and escapes the space itself. It is also the fastest way to type any long name, and the surest check
that a file exists, because Tab completes only what is there.

## Capital letters are different letters

```
ana@server:~$ cd office
ana@server:~/office$ ls Notes.txt
ls: cannot access 'Notes.txt': No such file or directory
ana@server:~/office$ ls notes.txt
notes.txt
```

**On Linux, `Notes.txt` and `notes.txt` are two different names**, lesson 3's point met again at the
prompt. On Windows and, by default, on macOS they are the same file. A script written on a laptop that
says `Notes.txt` can work there for years and fail on the server on its first run.

## On Windows

Paths use `\`, start with a **drive letter**, and are *case-insensitive*: `cd c:\users` and
`cd C:\Users` go to the same place. Spaces need quotes the same way, and they are everywhere in
Windows paths, `C:\Program Files` first among them. PowerShell also accepts `/`, which is why the
same PowerShell line often works on both systems.
