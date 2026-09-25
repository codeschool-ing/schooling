---
title: Finding help for a command
version: 1
---

Nobody remembers every option. The skill is knowing where the answer is, and every shell carries it.

```
ana@server:~$ ls --help | head -8
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --author               with -l, print the author of each file
ana@server:~$ type cd ls
cd is a shell builtin
ls is hashed (/usr/bin/ls)
PS /home/ana> (Get-Command -Verb Get).Count
61
PS /home/ana> Get-Command -Noun Location | Select-Object Name

Name
----
Get-Location
Pop-Location
Push-Location
Set-Location
```

- `--help` after almost any Linux command prints its options. It is long, so it is usually read
  through `head`, or `less` to scroll.
- `type` says what a name actually is. `cd` is a **builtin**, part of the shell itself, which is
  why it can change the shell's own folder; `ls` is a program on the disk, at `/usr/bin/ls`.
- `Get-Command` does both jobs in PowerShell. `-Verb Get` counted 61 cmdlets whose name starts with
  `Get-` on this installation, and `-Noun Location` found every cmdlet that works on locations,
  including two you did not know to look for.

That last trick is what the Verb-Noun names buy. **Guess the noun, ask for it, and read the verbs**:
`Get-Command -Noun Service` on Windows lists everything that manages services before you know any of
their names.

## The full manuals

On a normal Linux installation, **`man ls`** opens the complete manual page, with every option and
examples. In PowerShell, **`Get-Help Set-Location -Examples`** does the same, after `Update-Help` has
downloaded the help files once. Lesson 3's server is a minimal installation and leaves the manuals
out, so here the first of them does not even exist:

```
ana@server:~$ man ls
bash: man: command not found
```

`sudo apt install man-db` brings it back, which is lesson 11's subject.
