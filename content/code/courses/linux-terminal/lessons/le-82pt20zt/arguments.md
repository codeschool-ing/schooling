---
title: Arguments, and why `"$@"` has quotes around it
version: 1
---

A script that only works on one file is a note to yourself. Arguments are what make it a tool.

```
ana@vm:~/work/scripts$ cat args.sh
#!/bin/bash
echo "name:  $0"
echo "count: $#"
echo "first: $1   second: $2   tenth: ${10}"
echo "all:   $@"
ana@vm:~/work/scripts$ ./args.sh one two
name:  ./args.sh
count: 2
first: one   second: two   tenth: 
all:   one two
```

| | |
|---|---|
| `$0` | how the script was invoked — a path, not just a name |
| `$1` … `$9` | the arguments |
| `${10}` | the tenth. **Braces are required from ten on** |
| `$#` | how many there are |
| `$@` | all of them |
| `$*` | all of them, joined into one string |

`${10}` is not a nicety. `$10` is `$1` followed by a `0`, because the shell reads the longest name
it can and `1` is a complete name. With ten arguments:

```
ana@vm:~/work/scripts$ ./args.sh a b c d e f g h i j
name:  ./args.sh
count: 10
first: a   second: b   tenth: j
```

And `$2` printed nothing at all in the first run, because there was no second argument — the same
silent empty expansion as any other unset variable.

## `"$@"` versus `$@` versus `"$*"`

This is the one thing in this section that is not obvious, and it matters in every script that
passes its arguments on to something else.

```
ana@vm:~/work/scripts$ cat loopargs.sh
#!/bin/bash
echo "-- unquoted \$@"
for a in $@; do echo "  [$a]"; done
echo "-- quoted \"\$@\""
for a in "$@"; do echo "  [$a]"; done
echo "-- quoted \"\$*\""
for a in "$*"; do echo "  [$a]"; done
ana@vm:~/work/scripts$ ./loopargs.sh 'two words' second
-- unquoted $@
  [two]
  [words]
  [second]
-- quoted "$@"
  [two words]
  [second]
-- quoted "$*"
  [two words second]
```

Two arguments went in. Three ways of asking for them back, and only one of them gives you two.

| | |
|---|---|
| `$@` | expands, then splits. Two arguments became three words |
| `"$@"` | **one quoted word per argument.** Two arguments, both intact |
| `"$*"` | one word, everything joined with a space. One argument |

**`"$@"` is a special case in the grammar**, not a normal expansion: the quotes do not make it one
string, they make it *n* strings. There is no other construct in bash that behaves this way, and it
exists precisely because passing arguments along is what scripts do.

```sh
mycommand "$@"          # hand on exactly what you were given
mycommand $@            # hand on something else, if any argument had a space
mycommand "$*"          # hand on one argument that looks like all of them
```

`"$*"` is genuinely useful for one thing: building a message. `log "$*"` in a function joins all
the words into one line, which is what you wanted.

## `shift`

```
ana@vm:~/work/scripts$ cat shifter.sh
#!/bin/bash
while [ "$#" -gt 0 ]; do
  echo "handling [$1], $# left"
  shift
done
echo "done, \$# is $#"
ana@vm:~/work/scripts$ ./shifter.sh alpha beta gamma
handling [alpha], 3 left
handling [beta], 2 left
handling [gamma], 1 left
done, $# is 0
```

**`shift` throws away `$1` and moves everything down**: `$2` becomes `$1`, `$#` drops by one. It is
how you walk the argument list, and the loop above is the skeleton of every option parser you will
write — section 09 fills in the middle of it.

`shift 2` shifts by two, which is how an option that takes a value consumes both.

## Checking you were given something

Two lines at the top of any script that takes arguments:

```sh
[ "$#" -ge 1 ] || { echo "usage: $0 LOGFILE" >&2; exit 2; }
[ -r "$1" ]    || { echo "$0: cannot read $1" >&2; exit 1; }
```

```
ana@vm:~/work/scripts$ ./needsarg.sh; echo "exit $?"
usage: ./needsarg.sh LOGFILE
exit 2
ana@vm:~/work/scripts$ ./needsarg.sh /etc/shadow; echo "exit $?"
./needsarg.sh: cannot read /etc/shadow
exit 1
ana@vm:~/work/scripts$ ./needsarg.sh ~/work/logs/app.log; echo "exit $?"
would report on /home/ana/work/logs/app.log
exit 0
ana@vm:~/work/scripts$ ./needsarg.sh > /tmp/out.txt; echo "exit $?"; cat /tmp/out.txt
usage: ./needsarg.sh LOGFILE
exit 2
```

**The `>&2` is not optional**, and the last run is why. The whole of standard output went into
`/tmp/out.txt`, and the usage message was still on the screen — because it went to standard error
(lesson 8 section 02), which the redirect did not touch. Without the `>&2` it would be sitting
silently in a file the user did not want and is not going to read.

And `exit 2` rather than `exit 1` for a usage error is a mild convention worth keeping: it lets a
caller tell "you invoked me wrongly" from "I ran and failed".

## `$0` is not a name

```sh
./args.sh        →  $0 is ./args.sh
/home/ana/args.sh →  $0 is /home/ana/args.sh
```

Use `${0##*/}` (section 15) when you want just the filename for a message. And do not use `$0` to
find the script's own directory — it is unreliable in enough cases that the idiom is a line of its
own, worth copying rather than deriving:

```
ana@vm:~/work/scripts$ cat whereami.sh
#!/bin/bash
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
echo "the script lives in $here"
ana@vm:~/work/scripts$ ./whereami.sh
the script lives in /home/ana/work/scripts
ana@vm:~/work/scripts$ cd /tmp && ~/work/scripts/whereami.sh
the script lives in /home/ana/work/scripts
```

Called two different ways, from two different directories, one answer. That is what the line buys,
and it is why a script that needs a file next to itself uses `"$here/data.csv"` and not
`./data.csv`.
