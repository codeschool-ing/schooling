---
title: Functions, which are small scripts that share your variables
version: 1
---

```
ana@vm:~/work/scripts$ cat funcs.sh
#!/bin/bash
log() {
  echo "[$(date +%H:%M:%S)] $*" >&2
}

greet() {
  local who="${1:-world}"
  echo "hello, $who"
}

is_even() {
  [ $(( $1 % 2 )) -eq 0 ]
}

sum() {
  local total=0 n
  for n in "$@"; do total=$((total + n)); done
  echo "$total"
}

log "starting"
greet
greet ana
if is_even 4; then echo "4 is even"; fi
if is_even 7; then echo "7 is even"; else echo "7 is odd"; fi
t=$(sum 1 2 3 4 5)
echo "the sum is $t"
log "done"
ana@vm:~/work/scripts$ ./funcs.sh
[10:04:43] starting
hello, world
hello, ana
4 is even
7 is odd
the sum is 15
[10:04:43] done
ana@vm:~/work/scripts$ ./funcs.sh 2>/dev/null
hello, world
hello, ana
4 is even
7 is odd
the sum is 15
```

The second run threw away standard error and the two `log` lines disappeared with it, while the
report stayed. That is `>&2` inside `log` doing its job, and the reason for it is at the bottom of
this section.

`name() { … }`, and then `name` to call it. **A function must be defined before the line that calls
it**, because the shell reads the file top to bottom — which is why definitions go at the top and
the script's actual work goes at the bottom.

## A function is a small script

That is the mental model, and it is nearly exact.

| | |
|---|---|
| `$1 $2 $#` | **the function's** arguments, not the script's |
| `"$@"` | the function's arguments, same quoting rule as section 05 |
| `return N` | the function's exit status. `$?` afterwards |
| `exit N` | **exits the whole script.** Not the function |
| `$0` | still the script. Functions do not have their own name in `$0` |

The difference from a script is that a function shares the shell — its variables, its working
directory, its redirections. That is the point of it, and it is also the trap.

## `local`

```
ana@vm:~/work/scripts$ cat funcbugs.sh
#!/bin/bash
i=outer
nolocal() { i=clobbered; }
withlocal() { local i=safe; }
echo "before: i=$i"
nolocal;    echo "after nolocal:    i=$i"
i=outer
withlocal;  echo "after withlocal:  i=$i"

big() { return 300; }
big; echo "return 300 arrived as $?"

neg() { return -1; }
neg; echo "return -1 arrived as $?"

double() { echo $(( $1 * 2 )); }
r=$(double 21); echo "double 21 is $r"

talky() { echo "about to compute" ; echo $(( $1 * 2 )); }
r=$(talky 21); echo "talky 21 is [$r]"
ana@vm:~/work/scripts$ ./funcbugs.sh
before: i=outer
after nolocal:    i=clobbered
after withlocal:  i=outer
return 300 arrived as 44
return -1 arrived as 255
double 21 is 42
talky 21 is [about to compute
42]
```

That one file has four lessons in it. Start with the first three lines of output.

`nolocal() { i=clobbered; }` reached out and changed the caller's variable;
`withlocal() { local i=safe; }` did not.

**Everything in a function is global unless you say `local`.** A loop counter called `i` inside a
function will silently destroy the caller's `i`, and this is the kind of bug that appears only when
the script grows to the point where two loops are nested through a function call.

The rule is mechanical: **every variable a function assigns to gets a `local`**, on the first line
that mentions it, unless changing the caller's copy is the entire purpose.

`local total=0 n` on one line declares two, which is the usual spelling for "and my loop variable
too".

One wart, and it is worth seeing rather than being told:

```
ana@vm:~/work/scripts$ cat localstatus.sh
#!/bin/bash
set -e
try_one() { local out=$(grep nothing /etc/hostname); echo "local assignment: still here"; }
try_two() { local out; out=$(grep nothing /etc/hostname); echo "never reached"; }
try_one
try_two
echo "never reached either"
ana@vm:~/work/scripts$ ./localstatus.sh; echo "exit $?"
local assignment: still here
exit 1
```

The same failing `grep` in both functions. In `try_one` it was invisible, because the command whose
status `set -e` looked at was `local`, and `local` succeeded. In `try_two` the declaration and the
assignment are separate statements, and the failure stopped the script.

**`local x; x=$(cmd)` on two statements, whenever the status matters.**

## Returning a value

**`return` returns a status, not a value.** It is an integer from 0 to 255, and it means success or
failure, not data. Back to `funcbugs.sh`, lines four and five of its output:

`return 300` arrived as **44**, which is 300 modulo 256. `return -1` arrived as **255**. The number
is truncated without a word of complaint, which makes `return` useless for anything but success and
failure.

So a function that computes something *prints* it, and the caller catches it with `$( )`:
`double() { echo $(( $1 * 2 )); }`, called as `r=$(double 21)`, gave 42. **Standard output is how a
function returns data**, exactly like a program.

Which leads directly to the trap, the last two lines of that output. `talky` printed a progress
message and then its answer, and the caller got both — `[about to compute` and `42]` are one
string.

**A function that returns data on standard output cannot also chat on standard output.** Progress
messages, warnings, anything a human reads — send it to standard error with `>&2`, which is what
`log()` at the top of this section does.

That is not a workaround. It is what standard error is for (lesson 8 section 02), and it is why a
well-behaved script's normal output can be piped into something else without being contaminated.

## Two things that make functions worth it

**A `die` function, in every script you write:**

```sh
die() { echo "${0##*/}: $*" >&2; exit 1; }

[ -r "$1" ] || die "cannot read $1"
```

Every error path becomes one line, every message is formatted the same way, and every one of them
goes to standard error and exits non-zero — because there is one place that decides, not fourteen.

**A `usage` function**, printing a heredoc:

```sh
usage() {
  cat <<'USAGE'
usage: logreport.sh [-t MS] [-n COUNT] LOGFILE
  -t MS     call a request slow above this many milliseconds (default 1000)
  -n COUNT  how many rows per table (default 5)
USAGE
}
```

`<<'USAGE'` with the marker quoted means **no expansion happens inside** — the text arrives exactly
as written, which is what you want for something containing `$` and `*`. Unquoted, `<<USAGE`
expands variables, which is occasionally useful and usually a surprise.

## What functions cannot do

They cannot be called before they are defined, they cannot return anything but a number, and
**they cannot be exported to a child script** in any way you should rely on — `export -f` exists,
is bash-only, and was the mechanism behind a famous security hole in 2014.

If two scripts need the same function, put it in a third file and `source` it (section 02). That
is the shell's version of a library, and it is the whole of it.
