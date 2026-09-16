---
title: Loops, and never looping over `ls`
version: 1
---

`for` walks a list of words. That is all it does, and everything else follows from where the list
comes from.

```
ana@vm:/tmp/q2$ for i in 1 2 3; do echo "i=$i"; done
i=1
i=2
i=3
```

`for NAME in WORDS; do … done`. The `;` before `do` is the same rule as `then` in section 07 — a
newline works too.

## The list is usually a glob

```
ana@vm:/tmp/q2$ for f in *.log; do echo "[$f]"; done
[a.log]
[b.log]
[two words.log]
ana@vm:/tmp/q2$ for f in $(ls *.log); do echo "[$f]"; done
[a.log]
[b.log]
[two]
[words.log]
```

Three files went in. The glob gave three; `$(ls)` gave four.

**Never loop over the output of `ls`.** `ls` prints filenames separated by newlines, the shell
splits that on whitespace, and a filename with a space in it becomes two. `shellcheck` has a rule
number for this — SC2045 — because it is that common.

The glob does not have the problem, because the shell produced the list itself and knows where each
name ends. **`for f in *.log` is the right spelling, always.**

### The two glob surprises

```
ana@vm:/tmp/q2$ for f in *.nothing; do echo "[$f]"; done
[*.nothing]
```

**A glob that matches nothing stays literal.** The loop ran once, with the pattern as the value.
If the body was `rm "$f"` you get an error; if it was `mkdir -p "$f"` you get a directory called
`*.nothing`.

```
ana@vm:/tmp/q2$ shopt -s nullglob; for f in *.nothing; do echo "[$f]"; done; echo 'loop over'
loop over
```

**`shopt -s nullglob` makes an unmatched glob expand to nothing at all**, so the loop runs zero
times, which is what you meant. Set it once at the top of a script that globs.

The alternative, if you would rather not change the shell's behaviour globally, is to check inside
the loop:

```sh
for f in *.log; do
  [ -e "$f" ] || continue
  …
done
```

## Ranges

```
ana@vm:/tmp/q2$ for i in {1..5}; do printf '%s ' "$i"; done; echo
1 2 3 4 5 
ana@vm:/tmp/q2$ for i in {0..20..5}; do printf '%s ' "$i"; done; echo
0 5 10 15 20 
ana@vm:/tmp/q2$ for ((i=0; i<4; i++)); do printf '%s ' "$i"; done; echo
0 1 2 3 
```

`{1..5}` is brace expansion — it happens before anything else, and it is **not** a glob, so it
works on anything: `{a..e}`, `{web,db}0{1..3}`, `file{,.bak}`.

**Brace expansion cannot use a variable**, because braces are processed before parameters:

```
ana@vm:/tmp/q2$ n=4; for i in {1..$n}; do printf '%s ' "$i"; done; echo
{1..4} 
ana@vm:/tmp/q2$ n=4; for ((i=1; i<=n; i++)); do printf '%s ' "$i"; done; echo
1 2 3 4 
ana@vm:/tmp/q2$ echo {web,db}0{1..2}
web01 web02 db01 db02
```

The first loop ran **once**, over the literal eight characters `{1..4}` — the `$n` was substituted
but far too late to help. That is the one common reason to reach for the C-style `for (( ))`.

The third line is brace expansion doing what it is good at, and it is worth knowing outside loops
too: `mkdir -p /srv/{app,db}/{logs,data}` builds four directories in one command.

## `while` and `until`

```
ana@vm:/tmp/q2$ n=0; while [ $n -lt 3 ]; do echo "n=$n"; n=$((n+1)); done
n=0
n=1
n=2
ana@vm:/tmp/q2$ n=0; until [ $n -ge 3 ]; do echo "n=$n"; n=$((n+1)); done
n=0
n=1
n=2
```

`while` runs while a command succeeds; `until` runs until one does. They are the same loop with the
condition inverted, and `until` earns its place in exactly one idiom:

```sh
until curl -sf http://localhost:8080/health >/dev/null; do
  echo "waiting for the service…"
  sleep 2
done
```

"Keep trying until it works" reads better than "keep trying while it does not".

**`while` takes a command, like `if` does** — so `while read …` (the next section) is the same
construction, not a special form.

## `break` and `continue`

```
ana@vm:/tmp/q2$ for i in 1 2 3 4 5 6; do [ $((i%2)) -eq 0 ] && continue; echo "odd $i"; done
odd 1
odd 3
odd 5
ana@vm:/tmp/q2$ for i in 1 2 3 4 5; do [ $i -eq 3 ] && break; echo "i=$i"; done
i=1
i=2
```

`continue` skips to the next iteration, `break` leaves the loop. Both take a number for nested
loops:

```
ana@vm:/tmp/q2$ for i in 1 2; do for j in a b; do echo "$i$j"; done; done
1a
1b
2a
2b
ana@vm:/tmp/q2$ for i in 1 2; do for j in a b; do [ $j = b ] && break 2; echo "$i$j"; done; done
1a
```

**`break 2` leaves two levels**, which ended the outer loop as well — one line of output instead of
four. A plain `break` there would have ended only the inner loop and the outer one would have
started again.

## Loops and pipes

A loop is a command, so it can be redirected and piped like one:

```
ana@vm:/tmp/q2$ for f in *.log; do echo "$f: $(wc -l < "$f") lines"; done > summary.txt
ana@vm:/tmp/q2$ cat summary.txt
a.log: 2 lines
b.log: 1 lines
```

**One `>` on the `done`, not one inside the loop.** The version with `>> summary.txt` inside the
body opens and closes the file on every iteration; this one opens it once. On three files it does
not matter. On thirty thousand it does.

## When not to write a loop at all

This is the part that separates a shell script from a program written in the shell.

```sh
for f in *.log; do gzip "$f"; done      # a loop
gzip *.log                              # the same thing, one process
```

**Most commands already take many arguments.** A loop that calls `mv`, `rm`, `chmod` or `gzip` once
per file is usually a loop that did not need to exist — and lesson 8 section 16's `xargs` covers
the case where the list is too long or comes from somewhere else.

Write the loop when each iteration needs to *do* something different: build a name, check a
condition, keep a running total. Not when it is the same command with a different argument.
