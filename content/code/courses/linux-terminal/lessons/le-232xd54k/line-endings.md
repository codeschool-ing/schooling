---
title: The character you cannot see
version: 1
---

A text file is a sequence of lines, and something has to mark where each one ends. Two answers
exist, both from the 1960s, and nobody ever reconciled them:

| | ends a line with | used by |
|---|---|---|
| **LF** | one byte, `\n` | Linux, macOS, and every protocol you will meet |
| **CRLF** | two bytes, `\r\n` | Windows |

The `\r` is a carriage return — the instruction that moved a typewriter's carriage back to the
left margin. Windows kept both characters because the teleprinters it inherited from needed both.
Unix kept one.

**This would be trivia if the extra byte were ignored. It is not ignored — it is part of the
line**, and a shell that reads a line reads the `\r` as content.

## Three ways the same fault appears

Here is one script written twice. Same text, same permissions, different line endings.

### The interpreter that does not exist

```
ana@vm:~/crlf$ ./unix.sh
hello
ana@vm:~/crlf$ ./windows.sh
bash: ./windows.sh: cannot execute: required file not found
```

**"Required file not found" — and the file is right there.** The missing file is not the script. A
script's first line is `#!/bin/bash`, which names the program that should run it, and with CRLF
that line reads `/bin/bash\r`. The kernel looks for a program at that path, carriage return
included, and there is no such program.

### The syntax error at a line that is fine

```
ana@vm:~/crlf$ bash vars.sh
vars.sh: line 5: syntax error: unexpected end of file
```

That script is four lines long and the error names line 5. Bash read `then\r` and `fi\r`, neither
of which is the keyword it was waiting for, so as far as it is concerned the `if` was never closed
— and it says so when it runs out of file.

### The one that works, which is the worst

```
ana@vm:~/crlf$ bash windows.sh
hello
```

Same broken file, run by naming bash explicitly, and it prints. The shebang is skipped, no keyword
is involved, and the `\r` just travels along at the end of the argument. It will keep working
until the day a value from that file is compared to something, or used to build a path, and then
it will fail somewhere entirely else.

**One cause, three faces, and the third is the one that wastes a day.**

## How to see it

The character is invisible by definition, so ask a program that reports bytes rather than draws
them:

```
ana@vm:~/crlf$ file windows.sh unix.sh
windows.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
unix.sh:    Bourne-Again shell script, ASCII text executable
```

`with CRLF line terminators` is the whole diagnosis, in one clause, and `file` is the first thing
to reach for whenever a script behaves impossibly.

To see the bytes themselves:

```
ana@vm:~/crlf$ cat -A windows.sh
#!/bin/bash^M$
echo "hello"^M$
```

`cat -A` marks the end of each line with `$` and shows control characters. `^M` is the carriage
return, sitting exactly where nothing should be.

## How to fix it, and how to stop it

```
ana@vm:~/crlf$ sed -i 's/\r$//' windows.sh
ana@vm:~/crlf$ ./windows.sh
hello
```

That is lesson 8's `sed` arriving early: delete a carriage return at the end of every line, in
place. `dos2unix` does the same thing with a friendlier name, when it is installed.

**Stopping it is better than fixing it**, and there are three places it gets in:

- **Your editor.** Every editor can be told to write LF. VS Code shows `CRLF` or `LF` in its status
  bar and lets you click it.
- **Git.** `git config --global core.autocrlf input` on Windows commits LF and leaves your working
  copy alone. A repository that has both is a repository where every diff is the whole file.
- **WSL's `/mnt/c`.** Files edited on the Windows side carry Windows habits. Keep work in
  `/home/you`, which section 04 already recommended for speed and now recommends twice.

## Why this is section 12 and not an appendix

Because it is the first fault a student meets that **the error message actively misdescribes**.
"Required file not found" points at the file you are looking at, "syntax error" points at a line
that does not exist, and the third face points at nothing at all. Every other error in this lesson
says what it means.

Knowing the shape of this one — *the file looks right and behaves impossibly, so run `file` on it*
— is worth more than the fix.
