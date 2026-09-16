---
title: How to answer your own question
version: 1
---

This course covers 228 sections and it will not cover everything. **The skill that outlasts it is
knowing how to ask the machine**, because the machine came with its documentation and answers
faster than a search engine.

Four ways to ask, in the order you should try them.

## 1 · `--help`, for the shape of a command

```
ana@vm:~$ ls --help | head -8
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --author               with -l, print the author of each file
```

Read the first line as section 07 taught you: the command, then `[OPTION]...`, then `[FILE]...`.
Square brackets mean optional and `...` means repeatable, and that is the whole grammar of a usage
line.

`--help` is the fastest answer and almost always enough. It is printed by the program itself, so
it is never out of date, and it is short. Pipe it to `head` when it is not.

## 2 · `man`, for the full account

`man ls` opens the manual page: every option, the exit statuses, the standards it follows, and the
related commands at the bottom. It is a pager — **`q` quits**, arrows scroll, `/` searches. Nobody
tells beginners that `q` quits, and it is the single most common way to feel trapped in a
terminal.

The manual has numbered sections, and the numbers matter exactly once: `man 5 passwd` is the file
format, `man 1 passwd` is the command. When a page seems to be about the wrong thing, that is why.

**And it may not be installed.** On a container or a minimised cloud image:

```
ana@vm:~$ man ls
This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, including manpages, you can run the 'unminimize'
command. You will still need to ensure the 'man-db' package is installed.
```

Nothing is broken. The image was built small on purpose — section 04 warned that a fresh container
ships without tools you expect — and the message tells you exactly how to get them back. This is
the ordinary state of a container, so `--help` is the one that always works.

## 3 · `type` and `help`, when `man` has nothing

Some commands have no manual page because they are not programs at all:

```
ana@vm:~$ type cd
cd is a shell builtin
```

`cd` is part of bash. There is no `/bin/cd` to document, which is why `man cd` disappoints. For
builtins, bash documents itself:

```
ana@vm:~$ help cd | head -3
cd: cd [-L|[-P [-e]] [-@]] [dir]
    Change the shell working directory.
```

**`type` before anything else** is a good habit generally: it tells you whether a name is a
program, a builtin, an alias somebody set up, or a function. When a command behaves differently
from what you read, `type` is usually the explanation.

## 4 · `apropos`, when you do not know the name

`apropos` searches the manual's descriptions, so it answers "what is the command for…" rather than
"what does this command do". `apropos "list directory"` finds `ls`. It needs the manual pages
installed, so on a minimised image it finds nothing and that is the same cause as above.

## And `tldr`, which is not installed and is worth installing

`tldr` is a community project: the same commands, documented as **five examples of what people
actually type** instead of every option. `tldr tar` is the answer to the three-flag incantation
that lesson 3 complains about.

It does not come with the system. `sudo apt install tldr` — and it is the one thing in this section
that has to be fetched rather than found.

## Which to reach for

| the question | ask |
|---|---|
| what are this command's options? | `--help` |
| what does this option mean, exactly? | `man` |
| why is this command behaving oddly? | `type` |
| what is the command for…? | `apropos` |
| show me what people actually type | `tldr` |

And read the error first. Section 17 is the next one because in practice the answer is usually in
the line you already have, not in a manual.
