---
title: Redirection, and why the order of `2>&1` matters
version: 1
---

Six operators, and you will use four of them daily.

| | |
|---|---|
| `> file` | stdout to a file, **replacing** it |
| `>> file` | stdout to a file, **appending** |
| `< file` | the file as stdin |
| `2> file` | stderr to a file |
| `2>&1` | stderr **to wherever stdout currently goes** |
| `&> file` | both, in bash. Shorthand for `> file 2>&1` |

## `>` empties the file first

```
ana@vm:~/work$ echo one > note.txt; echo two > note.txt; cat note.txt
two
ana@vm:~/work$ echo three >> note.txt; cat note.txt
two
three
```

**`>` truncates before the command runs**, not after it succeeds. That is worth internalising,
because it means `sort file > file` destroys the file:

```
ana@vm:~/work$ printf "c\na\nb\n" > /tmp/t.txt; cat /tmp/t.txt
c
a
b
ana@vm:~/work$ sort /tmp/t.txt > /tmp/t.txt; wc -c /tmp/t.txt; cat /tmp/t.txt
0 /tmp/t.txt
```

**Zero bytes.** The shell emptied the file while `sort` was still opening it, `sort` read nothing,
and wrote nothing. No error, no warning, and the data is gone.

The fix is to write somewhere else and move, or use a tool that edits in place. Section 13's
`sed -i` exists for exactly this.

## Redirecting errors

```
ana@vm:~/work$ ls logs nosuchdir > out.txt 2> err.txt; cat err.txt
ls: cannot access 'nosuchdir': No such file or directory
```

Two files, two streams, nothing on the screen. And to throw errors away entirely:

```
ana@vm:~/work$ ls nosuchdir 2>/dev/null; echo "exit: $?"
exit: 2
```

**`/dev/null` accepts anything and keeps nothing** — lesson 3's empty sink. Note what survived:
the exit status. Silencing a command's complaints does not silence its **answer**, which is why
`2>/dev/null` is safe in a script that checks `$?` and dangerous in one that does not.

## Both to one place

```
ana@vm:~/work$ ls logs nosuchdir > both.txt 2>&1; cat both.txt
ls: cannot access 'nosuchdir': No such file or directory
logs:
access.log
app.log
app.log.1
empty.log
error.log
```

`2>&1` reads as **"make descriptor 2 a copy of descriptor 1"**, which is lesson 6 section 13's
sentence. Because 1 already points at `both.txt` by the time it runs, 2 ends up there too.

## And that is why the order matters

```
ana@vm:~/work$ ls nosuchdir 2>&1 > out.txt; cat out.txt
ls: cannot access 'nosuchdir': No such file or directory
```

**Same two operators, swapped, and the error is on the screen and the file is empty.**

Read it left to right, as the shell does:

1. `2>&1` — make 2 a copy of 1. Right now 1 is **the terminal**, so 2 is now the terminal. Which it
   already was.
2. `> out.txt` — point 1 at the file. **This does not follow 2 along**; 2 is still the terminal.

`2>&1` copies where a descriptor points *at that moment*. It is not a link, and nothing updates it
afterwards.

**So `> file 2>&1` is the one that works, and `2>&1 > file` is a silent mistake.** It produces no
error, writes a file, and loses the thing you were probably trying to keep. When somebody says a
log file is mysteriously missing the errors, this is usually why.

`&> file` avoids the whole question and is bash-only. In a script with `#!/bin/sh`, use
`> file 2>&1`.

## Redirecting inside a pipeline

A pipe carries stdout only. Errors go around it, to the terminal:

```
some-command 2>/dev/null | grep thing      # drop errors, pipe results
some-command 2>&1 | grep thing             # search results AND errors
```

**The second one is how you grep an error message**, and people reach for the first by habit and
then wonder why `grep` finds nothing. If what you are looking for was printed in red, it was on
stderr, and a bare `|` never saw it.

## Two more, occasionally

**Here-doc** feeds a block of text as stdin, which is how a script supplies input without a file:

```
cat > /tmp/config.txt <<'EOF'
first line
second line
EOF
```

The quotes around `'EOF'` matter: without them the shell expands `$variables` inside the block, and
with them it does not.

**Here-string** is the one-line version, `<<<`:

```
ana@vm:~/work$ grep -c o <<< "hello world"
1
```

One, because `grep -c` counts **lines that match**, not occurrences — section 06 comes back to
that.

And `tee` is the one that is not redirection but solves the same problem — writing to a file **and**
passing the text on:

```
some-command | tee out.txt | grep error
```

`tee -a` appends. It is the standard way to keep a copy of what went past, and the standard way to
write to a root-owned file from a pipeline, since `sudo cmd > /root/file` fails — **the redirection
is done by your shell, not by `sudo`** — and `cmd | sudo tee /root/file` works.
