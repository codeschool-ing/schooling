---
title: The shape of a command
version: 2
---

Every command you will type for the rest of this course has the same three parts, in the same
order:

```localised
command   [options]   [arguments]
```

**The command** is what to run. **The options** change how it runs. **The arguments** are what it
runs on. Learn this shape once and a thousand unfamiliar commands become guessable rather than
magic.

```
ana@vm:~/demo$ ls -l readme.txt
```

`ls` is the command, `-l` is an option, `readme.txt` is the argument.

## Options come in two spellings

```
$ ls
-strange
folder
readme.txt
with space.txt
```

Plain, with nothing added, `ls` gives you names. Add one option and the same command answers the
same question in much more detail:

```
$ ls -l
total 16
-rw-r--r-- 1 ana ana    2 Sep 14 14:45 -strange
drwxr-xr-x 2 ana ana 4096 Sep 14 14:45 folder
-rw-r--r-- 1 ana ana   46 Sep 14 14:45 readme.txt
-rw-r--r-- 1 ana ana    4 Sep 14 14:45 with space.txt
```

**The command did not change. What changed is how much of the answer it showed.**

| spelling | looks like | notes |
|---|---|---|
| **short** | `-l`, `-a`, `-r` | one letter, one hyphen |
| **long** | `--all`, `--recursive` | a word, two hyphens; readable, and what you want in a script |
| **combined** | `-la` is `-l` plus `-a` | short options only, and the order between them rarely matters |

Combining is ordinary and you will see it constantly:

```
$ ls -la
total 24
-rw-r--r-- 1 ana ana    2 Sep 14 14:45 -strange
drwxr-xr-x 3 ana ana 4096 Sep 14 14:45 .
drwxr-x--- 4 ana ana 4096 Sep 14 14:45 ..
-rw-r--r-- 1 ana ana    0 Sep 14 14:45 .hidden
drwxr-xr-x 2 ana ana 4096 Sep 14 14:45 folder
-rw-r--r-- 1 ana ana   46 Sep 14 14:45 readme.txt
-rw-r--r-- 1 ana ana    4 Sep 14 14:45 with space.txt
```

`-a` added `.hidden`, `.` and `..` — three entries the plain listing left out. Section 11 explains
the dot that hides a file; sections 02 and 12 of lesson 3 explain the other two.

**Not every short option has a long twin, and not every long option has a short one.** `--help`
usually has no short form worth using. That is a fact about each program, which is what `man` is
for — section 16.

## Some options take a value of their own

```
$ head -n 2 readme.txt
first line
second line
$ head --lines=2 readme.txt
first line
second line
```

The `2` belongs to the option, not to the command: it says *how many* lines. The short form
usually takes its value after a space, the long form after an `=`, and many programs accept both
spellings of both. Same result, twice — and in a script, prefer `--lines=2`, because in six
months `-n 2` is a puzzle and `--lines=2` is a sentence.

## Where the shape bites

### A space is a separator, and it means something

The shell splits your line on spaces before the command sees any of it. So a filename with a space
in it arrives as two arguments:

```
$ ls with space.txt
ls: cannot access 'with': No such file or directory
ls: cannot access 'space.txt': No such file or directory
```

Two errors, because `ls` was handed two names and neither exists. Quote it and it is one
argument again:

```
$ ls 'with space.txt'
with space.txt
```

**This is the single most common beginner error in the shell**, and it is not really about
filenames — it is about who splits the line. Lesson 9's `quoting` section is the full treatment;
the rule to carry until then is *if it has a space in it, put quotes around it.*

### A leading hyphen makes an argument look like an option

```
$ ls -strange
ls: invalid option -- 'e'
Try 'ls --help' for more information.
```

There is a file called `-strange` in that directory, and `ls` never considered it. Anything
starting with `-` is read as options, so it took the letters one at a time — `s`, `t`, `r`, `a`,
`n` and `g` are all real `ls` options — and stopped at `e`, which is not. That is why the
complaint names a letter rather than the filename.

The fix is a convention nearly every command honours — **`--` means "no more options, everything
after this is an argument"**:

```
$ ls -- -strange
-strange
```

You will meet this the first time somebody hands you a file whose name begins with a hyphen, and
without it the file is close to untouchable.

### Read the error, and it tells you which part was wrong

Three failures in this section and each one names its own kind:

| message | what it means |
|---|---|
| `bash: celar: command not found` | the **command** is wrong — the shell could not find a program by that name |
| `ls: invalid option -- 'e'` | the **option** is wrong — the program ran, and refused the flag |
| `ls: cannot access 'with'` | the **argument** is wrong — the program ran, took the flag, and could not find the thing |

Which is the same rule as section 03, one level finer: the message tells you which of the three
parts to look at. That is most of the work of fixing it.

## Order, and what is flexible

Options before arguments is the convention and always safe. Most GNU tools on Linux will also
accept `ls readme.txt -l`, and BSD tools on a Mac frequently will not — so write it the
conventional way and it works everywhere.

Two more things are worth knowing now:

- **Case matters.** `-r` and `-R` are usually two different options. `ls` and `LS` are two
  different commands, and only one of them exists.
- **Extra spaces are harmless.** `ls   -l` is the same as `ls -l`. The shell collapses the run of
  spaces when it splits the line — which is the same mechanism that made `with space.txt` two
  arguments a moment ago.
