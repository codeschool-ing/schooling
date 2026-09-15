---
title: Debugging, and the tool that reads your script for you
version: 1
---

Four things, in the order you should reach for them.

## `bash -n`, before you run it

```
ana@vm:~/work/scripts$ cat typo.sh
#!/bin/bash
for i in 1 2 3; do
  echo "$i"
done
if [ 1 -eq 1 ]; then
  echo yes
ana@vm:~/work/scripts$ bash -n typo.sh; echo "exit $?"
typo.sh: line 7: syntax error: unexpected end of file
exit 2
```

**`-n` parses the file and does not run it.** The missing `fi` is found in a tenth of a second,
without executing the three lines before it.

Note where it points: **line 7 is the end of the file**, not line 5 where the `if` is. A shell
cannot know which unterminated block you meant, so the error always lands at the bottom. When
`bash -n` says "unexpected end of file", the answer is a missing `fi`, `done`, `esac` or `}` and
you look for it from the top.

`-n` catches syntax and nothing else. A script that parses cleanly can still do something dreadful.

## `shellcheck`, which is the important one

```
ana@vm:~/work/scripts$ cat buggy.sh
#!/bin/bash
files=$1
count=`ls $files | wc -l`
if [ $count > 5 ]; then
  echo "many files"
fi
for f in $(ls $files); do
  rm $f
done
ana@vm:~/work/scripts$ shellcheck buggy.sh

In buggy.sh line 3:
count=`ls $files | wc -l`
      ^-----------------^ SC2006 (style): Use $(...) notation instead of legacy backticks `...`.
       ^-------^ SC2012 (info): Use find instead of ls to better handle non-alphanumeric filenames.
          ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
count=$(ls "$files" | wc -l)


In buggy.sh line 4:
if [ $count > 5 ]; then
     ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.
            ^-- SC2071 (error): > is for string comparisons. Use -gt instead.

Did you mean: 
if [ "$count" > 5 ]; then


In buggy.sh line 7:
for f in $(ls $files); do
         ^----------^ SC2045 (error): Iterating over ls output is fragile. Use globs.
              ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
for f in $(ls "$files"); do


In buggy.sh line 8:
  rm $f
     ^-- SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
  rm "$f"
```

Nine lines of script. It parses cleanly, `bash -n` is happy with it, and it has a bug on every
line — four missing quotes, backticks, looping over `ls`, and a comparison that is not a
comparison.

Every one of those is something from this lesson. Section 141 is `SC2086`, section 147 is `SC2045`,
section 151 is `SC2006`, and `SC2071` is section 145.

Install it — `apt install shellcheck`, `dnf install ShellCheck` — and run it before every script you
run for the first time. **It is not a style checker with opinions; it finds bugs.**

### What `SC2071` is actually about

```
ana@vm:/tmp/q2$ cd /tmp/q2 && rm -rf ./* && count=3
ana@vm:/tmp/q2$ if [ $count > 5 ]; then echo 'many'; else echo 'few'; fi
many
ana@vm:/tmp/q2$ ls -l
total 0
-rw-r--r-- 1 ana ana 0 Sep 15 10:06 5
ana@vm:/tmp/q2$ if [ $count -gt 5 ]; then echo 'many'; else echo 'few'; fi
few
```

Three is not greater than five, and the script said `many`.

**The `>` was a redirection.** `[ $count > 5 ]` ran `[ 3 ]` with its output redirected into a file
called `5` — which the `ls` found sitting in the directory. `[ 3 ]` is "is the string `3` non-empty",
which is true, so the `then` branch ran.

Wrong answer, no error, and a stray file. This is the class of bug `shellcheck` exists for: the
script is valid, it runs, and it is wrong.

## `bash -x`, when it runs but does the wrong thing

```
ana@vm:~/work/scripts$ bash -x traced.sh
+ total=0
+ for n in 3 4
+ total=3
+ for n in 3 4
+ total=7
+ echo 'total is 7'
total is 7
```

**`-x` prints every command after expansion, prefixed with `+`.** After expansion is the whole
point: you see `total=3`, not `total=$((total + n))`, so you see the values your script actually
had rather than the ones you assumed.

It goes to standard error, so `bash -x script.sh 2>trace.log` keeps the trace and the output apart.

Turn it on for part of a script with `set -x` and off with `set +x`, which is how you trace the one
function that is misbehaving in a script that prints four thousand lines.

### `PS4`, which makes it twice as useful

```
ana@vm:~/work/scripts$ PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
ana@vm:~/work/scripts$ bash -x traced.sh 2>&1 | head -8
+ total=0
+ for n in 3 4
+ total=3
+ for n in 3 4
+ total=7
+ echo 'total is 7'
total is 7
ana@vm:~/work/scripts$ export PS4; bash -x traced.sh 2>&1 | head -8
+ traced.sh:2: total=0
+ traced.sh:3: for n in 3 4
+ traced.sh:4: total=3
+ traced.sh:3: for n in 3 4
+ traced.sh:4: total=7
+ traced.sh:6: echo 'total is 7'
total is 7
```

`PS4` is the prefix `-x` uses, and the default is a single `+`. Setting it to the file and line
number turns a wall of commands into something you can match against the source — and look at the
second and third lines of the second run: `3, 4, 3, 4` is the loop, visibly going round.

The first attempt did nothing, and that is the part worth noticing. **`PS4` has to be exported**,
because the trace is printed by the `bash` you are starting, not by the shell you typed in.

Put it in your own shell's startup file and every `-x` you ever run is better.

## Printing things

The oldest technique, and the one you will use most:

```sh
echo "DEBUG: f=[$f] count=[$count]" >&2
declare -p f count >&2
```

**The brackets are the technique**, not decoration — they show you the trailing space, the empty
string, the newline that `echo` alone would hide. `declare -p` (section 140) does it properly, with
types and quoting.

And `>&2`, so your debugging does not end up in the file the script is writing.

## In what order

| | |
|---|---|
| it will not run | `bash -n` |
| before running anything new | `shellcheck` |
| it runs and does the wrong thing | `bash -x`, with `PS4` exported |
| you know roughly where | `echo "…[$var]…" >&2` |

And one habit that is worth more than all four: **run the destructive version last.** Put `echo` in
front of the `rm`, look at the twenty lines it prints, and then take the `echo` away. Section 134
made the same argument about `xargs`, and it is the same argument here.
