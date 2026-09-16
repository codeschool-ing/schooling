---
title: `if`, and the fact that `[` is a program
version: 1
---

```
ana@vm:~/work/scripts$ cat grade.sh
#!/bin/bash
n=$1
if [ "$n" -ge 90 ]; then
  echo "excellent"
elif [ "$n" -ge 60 ]; then
  echo "pass"
else
  echo "fail"
fi
ana@vm:~/work/scripts$ ./grade.sh 95; ./grade.sh 70; ./grade.sh 12
excellent
pass
fail
```

The shape is `if … then … elif … else … fi`, the `then` needs a `;` or a newline before it, and the
block ends with `fi`. That much is memorisation.

The part that is not memorisation is what goes between `if` and `then`.

## `if` does not take a condition. It takes a command.

**There is no boolean expression in the shell.** `if` runs a command and looks at its exit status:
zero means then, anything else means else. Lesson 6 section 14's rule, used as control flow.

```
ana@vm:~/work/scripts$ test -f /etc/hostname; echo $?
0
```

So this is legal, and means exactly what it says:

```
ana@vm:~/work$ if grep -q 'GET /health' logs/access.log; then echo 'it is in the log'; fi
it is in the log
```

**No brackets anywhere**, because `grep` already reports success and failure. People write
`if [ $(grep -c ERROR file) -gt 0 ]` out of habit; `grep -q` is shorter, faster, and stops reading
at the first match. The same goes for `ping -c1 -W1 host`, `systemctl is-active nginx`,
`id -u someuser` — anything whose job is to answer a question already answers it in `$?`.

## `[` is a command

```
ana@vm:~/work/scripts$ type [ ; ls -l /usr/bin/[
[ is a shell builtin
-rwxr-xr-x 1 root root 55744 Jun 22  2025 '/usr/bin/['
```

There is a **file on disk called `[`**. It is not punctuation, it is a program — the same program
as `test`, which is why `[` requires a closing `]` as its last argument, and why it is written with
spaces around it.

```
ana@vm:~/work/scripts$ [ 1 -lt 2 ]; echo $?
0
ana@vm:~/work/scripts$ [ 1 -lt 0 ]; echo $?
1
```

`[ 1 -lt 2 ]` is `[` run with four arguments, the last of which is `]`. That single fact explains
every strange message it will ever give you:

```
ana@vm:~/work$ [1 -lt 2]
bash: [1: command not found
ana@vm:~/work$ x=; [ $x = y ]
bash: [: =: unary operator expected
ana@vm:~/work$ touch /tmp/q2/'a b'; [ /tmp/q2/a b ]
bash: [: /tmp/q2/a: unary operator expected
```

The first says *command not found* because `[1` is a word and there is no such command. The other
two say *unary operator expected* because `[` counts its arguments: with two of them it expects a
test like `-f`, and it got `=` in one case and a stray filename in the other.

**It is a command, so its arguments are split and globbed like any command's.** That is the whole
source of the trouble in section 08.

## `&&` and `||`

```
ana@vm:~/work/scripts$ [ -d /etc ] && echo 'etc is a directory'
etc is a directory
ana@vm:~/work/scripts$ [ -d /nope ] || echo 'not a directory'
not a directory
```

| | |
|---|---|
| `a && b` | run `b` only if `a` succeeded |
| `a \|\| b` | run `b` only if `a` failed |

These are short-circuit operators on exit status, and `mkdir -p x && cd x` is the everyday use: do
the second thing only if the first worked.

**`a && b || c` is not an if-then-else**, and the difference bites:

```
ana@vm:~/work$ true && echo b-ran || echo c-ran
b-ran
ana@vm:~/work$ true && false || echo 'c ran even though a succeeded'
c ran even though a succeeded
```

The first line is what everybody expects. In the second, `a` succeeded, `b` ran and failed, and
`c` ran anyway — because `||` is looking at the status of everything to its left, not at which
branch was taken. It is fine for `[ -d x ] && echo yes || echo no`, where `echo` cannot fail. For
anything where the middle can fail, write the `if`.

## `!`, and the small ones

```sh
if ! command; then …            # negate
if [ -f a ] && [ -f b ]; then … # two tests, joined with the shell's own &&
if [ -f a -a -f b ]; then …     # test's own -a. Works, deprecated, avoid
```

**Two separate `[ ]` joined by `&&` is the spelling to use.** `-a` and `-o` inside a single `[` are
obsolescent in POSIX and ambiguous when a value looks like an operator.

And three commands that exist only for control flow:

| | |
|---|---|
| `true` | does nothing, succeeds |
| `false` | does nothing, fails |
| `:` | does nothing, succeeds. The shortest way to write "nothing goes here" |

`while true; do …; done` is an infinite loop, `|| true` is section 06's escape hatch, and `:` is
what fills a branch you have not written yet — a `then` with nothing in it is a syntax error.

## Formatting

```sh
if [ "$n" -ge 90 ]; then          # the common one
if [ "$n" -ge 90 ]
then                              # also fine, and used in older scripts
```

The `;` before `then` is there because `then` must start a new command. A newline does the same
job. Both forms are everywhere; neither is more correct.
