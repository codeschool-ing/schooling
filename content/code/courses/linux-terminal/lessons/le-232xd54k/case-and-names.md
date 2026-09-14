---
title: Names, and four rules that are not the ones you expect
version: 1
---

A filename on Linux is freer than you think and stricter than you think, in different places from
the ones you are used to. Four rules, and each one costs somebody an afternoon the first time.

## 1 · Case matters

```
ana@vm:~/case$ ls
NOTES.TXT
Notes.txt
notes.txt
```

**Three different files**, in one directory, at the same time. Windows and macOS would have
refused to create the second: on those, `Notes.txt` and `notes.txt` are the same name spelled two
ways.

This is the rule that breaks deployments. A project works on somebody's Mac, where `Header.css`
and `header.css` are one file, and fails on the Linux server that serves it, where they are two
and only one exists. The code did not change. The filesystem stopped being forgiving.

The habit that avoids all of it: **lower case, always**, and a hyphen where you want a space.

## 2 · The extension decides nothing

```
ana@vm:~/case$ file report.pdf
report.pdf: ASCII text
```

That file is called `report.pdf` and it is a text file. Linux did not check, did not warn, and did
not care — because **the extension is part of the name and nothing else.** There is no registry of
file types, and no association between `.pdf` and a program.

`file` is the command that actually looks:

```
ana@vm:~$ file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked
```

`/bin/ls` has no extension at all and is a program. It reads the first bytes of the content and
reports what it found, which is the only honest way to answer.

Two consequences:

- **Renaming does not convert.** `mv a.txt a.pdf` produces a text file with a misleading name.
- **What decides whether something runs is a permission bit**, not `.exe`. Lesson 4 is about that
  bit, and `file` reporting "executable" above is reporting it.

## 3 · A dot at the front hides it

A name beginning with `.` is left out of an ordinary listing. That is the whole mechanism — there
is no hidden attribute anywhere, just a convention that `ls` honours:

```
ana@vm:~/plain$ ls
folder	readme.txt
ana@vm:~/plain$ ls -a
.  ..  .hidden	folder	readme.txt
```

It is not secrecy and it is not protection. It is a way of keeping configuration out of your way:
your home directory holds dozens of these — `.bashrc`, `.ssh`, `.gitconfig` — and you would never
want them in the way when you list your documents.

`.` and `..` in that output are the current and parent directories. They are entries like any
other, which is why `-a` shows them and why `cd ..` works.

## 4 · Almost any character is allowed, and you should not

A Linux filename may contain anything except two things: a `/`, which separates directories, and a
zero byte. **Everything else is legal** — spaces, quotes, newlines, emoji, a leading hyphen.

Legal is not wise, and section 07 already showed why:

```
ana@vm:~/demo$ ls with space.txt
ls: cannot access 'with': No such file or directory
ls: cannot access 'space.txt': No such file or directory
```

The file exists. The shell split the line before `ls` saw it. A name containing a space is a name
you must quote for the rest of its life, and a name beginning with `-` needs `--` in front of it
forever.

**So the rule is a habit, not a restriction:** lower case, letters, digits, hyphens, underscores
and dots. Nothing else. You will read other people's names that break this, and quoting is how you
survive them.

## The four, together

| | |
|---|---|
| case | `Notes.txt` and `notes.txt` are two files |
| extension | part of the name; `file` is what actually knows |
| leading dot | hidden from `ls`, by convention, not by a flag |
| the rest | legal does not mean advisable |
