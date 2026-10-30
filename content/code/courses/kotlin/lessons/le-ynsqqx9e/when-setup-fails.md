---
title: When the setup fails
version: 1
---

A setup that fails seldom says "your setup failed". It says something about a command, a file or a
checksum, and the temptation is to remove everything and start again. **Each failure below has one
cause, and the message names it** if you read it to the end. All three were produced on purpose,
on a fresh copy of the same Ubuntu 24.04.

## `kotlinc: command not found`, right after unpacking it

The compiler is on disk, and the shell cannot find it. The shell looks for a command only in the
directories listed in `PATH`, and a terminal reads `~/.bashrc`, where section 02 added the two new
ones, **when it starts**. A terminal that was already open before the `echo` still has the old
list:

```
ana@vm:~$ kotlinc -version; echo $?
bash: line 1: kotlinc: command not found
127
ana@vm:~$ ~/.local/share/kotlinc/bin/kotlinc -version
info: kotlinc-jvm 2.4.21 (JRE 21.0.12.1+1-1-24.04.4-Ubuntu)
ana@vm:~$ echo $PATH
/usr/local/bin:/usr/bin:/bin
```

**Exit status 127 is the shell's own number for "no such command"**, so the message comes from
`bash` and not from Kotlin. The full path works, which proves the file is there. `echo $PATH` shows
the list the shell is searching, and neither `.local/share` directory is in it. Open a new
terminal, or type `source ~/.bashrc` in this one, and `kotlinc` answers.

If a new terminal still cannot find it, look at the end of `~/.bashrc` with
`tail -1 ~/.bashrc`. The line should read exactly as section 02 typed it. Double quotes outside
instead of single quotes is the usual mistake: the shell then replaced `$HOME` and `$PATH` with
their values at the moment you typed the `echo`, which still works but freezes the old `PATH` into
the file.

## `kotlinc` is found, and Java is not

`kotlinc` is a shell script that starts a JVM. Unpack the compiler on a machine with no JDK, and
the script is found and then fails on the first thing it needs:

```
ana@vm:~$ kotlinc -version; echo $?
/home/ana/.local/share/kotlinc/bin/kotlinc: line 102: java: command not found
127
```

The message names `java`, not `kotlinc`. **Read a message for the program it names**: the script
was found, ran, and could not start the JVM it is a wrapper around. The fix is the `apt` line of
section 02. Installing a JRE alone, the runtime without the development tools, would make this
particular message go away and leave Gradle unable to compile anything in lesson 14, so install
the JDK.

## A download that stopped halfway

A connection that drops can leave a zip that is shorter than it should be, with the right name.
Nothing about the file name tells you, and `unzip` finds out late:

```
ana@vm:~/downloads$ echo "$(cat kotlin-compiler-2.4.21.zip.sha256)  kotlin-compiler-2.4.21.zip" | sha256sum -c
kotlin-compiler-2.4.21.zip: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@vm:~/downloads$ unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share; echo $?
[kotlin-compiler-2.4.21.zip]
  End-of-central-directory signature not found.  Either this file is not
  a zipfile, or it constitutes one disk of a multi-part archive.  In the
  latter case the central directory and zipfile comment will be found on
  the last disk(s) of this archive.
unzip:  cannot find zipfile directory in one of kotlin-compiler-2.4.21.zip or
        kotlin-compiler-2.4.21.zip.zip, and cannot find kotlin-compiler-2.4.21.zip.ZIP, period.
9
ana@vm:~/downloads$ ls -l kotlin-compiler-2.4.21.zip
-rw-r--r-- 1 ana ana 41943040 Oct 30 03:01 kotlin-compiler-2.4.21.zip
```

`sha256sum -c` said `FAILED` before anything was unpacked, which is why section 02 checks the file
first. `unzip` then confirms it in its own words: a zip keeps its table of contents at the end of
the file, the "central directory", and a file cut short has no end. **Delete the file and download
it again**; there is nothing in a damaged zip worth keeping. `ls -l` shows the difference too, as
a size smaller than the one the release page lists, and that is the quickest thing to look at when
you did not keep the checksum.

## When none of these is it

Three things to collect before asking anybody for help, because they answer most of the questions
you will be asked:

- `java -version`, `kotlinc -version` and `gradle --version`, and which of them fails;
- `echo $PATH`, and `ls ~/.local/share`;
- the **last** lines of the failing command's output, not the first. A JVM program fails with a
  stack of lines, and the cause is named at the bottom, in the line that starts `Caused by` or in
  the one that names an exception.
