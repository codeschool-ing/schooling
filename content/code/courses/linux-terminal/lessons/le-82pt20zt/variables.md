---
title: Variables, and the four characters that are not allowed
version: 1
---

```
ana@vm:~/work/scripts$ name=ana
ana@vm:~/work/scripts$ echo $name
ana
```

Assign with `=`, read with `$`. That is the whole of it, and then there is one rule that costs
everybody their first ten minutes.

## No spaces around the `=`

```
ana@vm:~/work/scripts$ name = ana
bash: name: command not found
ana@vm:~/work/scripts$ name= ana
bash: ana: command not found
```

**Both of those are valid shell — they just do not mean what you wanted.** The shell splits a
line into words and runs the first one as a command, so `name = ana` is "run the command `name`
with arguments `=` and `ana`", and `name= ana` is "run `ana` with `name` set to empty".

That second one is a real feature, and it comes back later in this section. Right now, remember:
**`name=value`, with nothing on either side of the `=`.**

## Everything is a string

```
ana@vm:~/work/scripts$ count=3
ana@vm:~/work/scripts$ echo $count+1
3+1
```

There is no number type. `count` holds the two characters `3`, and `$count+1` is the string `3+1`.
Arithmetic needs `$(( ))`, which is section 151.

Quotes are only for the shell's benefit — they never end up in the value:

```
ana@vm:~/work/scripts$ greeting='hello there'
ana@vm:~/work/scripts$ echo $greeting
hello there
```

The quotes are how you got `hello there` into one variable instead of running `there` as a command.
The variable itself contains no quotes.

## Braces, for where the name ends

```
ana@vm:~/work/scripts$ echo ${name}s
anas
ana@vm:~/work/scripts$ echo $names

```

**`$names` is a variable called `names`**, which does not exist — so it expanded to nothing and
`echo` printed a blank line. `${name}s` is the variable `name` followed by a literal `s`.

The shell reads a name as far as it can: letters, digits and underscores. Anything else ends it,
which is why `$name.txt` and `$name/file` work without braces and `${name}s` needs them.

**Braces are also where everything in section 152 hangs off**, so it is not a bad habit to use them
always. Both spellings are correct; pick one and be consistent.

## An unset variable is not an error

```
ana@vm:~/work/scripts$ unset name; echo "[${name}]"
[]
```

**A name that does not exist expands to nothing at all**, silently. This is the single most
dangerous behaviour in the shell, it has erased real directories, and section 143 is about turning
it into an error.

Meanwhile there are two defaults:

```
ana@vm:~/work/scripts$ echo "[${name-not set}] [${name:-empty or unset}]"
[not set] [empty or unset]
```

| | |
|---|---|
| `${name-default}` | use the default when `name` is **unset** |
| `${name:-default}` | use the default when `name` is unset **or empty** |

**The colon is the difference between the two, and the one with the colon is almost always the one
you meant.** A variable set to the empty string is a bug as often as it is a value.

## Shell variables and environment variables

These are two different things and the difference decides what your scripts can see.

```
ana@vm:~/work/scripts$ SHELLVAR=one
ana@vm:~/work/scripts$ export ENVVAR=two
ana@vm:~/work/scripts$ echo "$SHELLVAR $ENVVAR"
one two
ana@vm:~/work/scripts$ ./child.sh
shell variable SHELLVAR is [unset]
environment  ENVVAR   is [two]
ana@vm:~/work/scripts$ env | grep -E '^(SHELLVAR|ENVVAR)='
ENVVAR=two
```

Both exist in the shell you typed them in. Only the exported one crossed into the child.

**`export` is what makes a variable part of the environment**, and the environment is the only
thing a child process inherits. This is why a script cannot see a variable you set at the prompt
unless you exported it, and why `source` (section 139) is the other way round the same problem.

`env` lists exactly what is exported, which makes it the way to check.

### One command, one variable

```
ana@vm:~/work/scripts$ SHELLVAR=three ./child.sh
shell variable SHELLVAR is [three]
environment  ENVVAR   is [two]
ana@vm:~/work/scripts$ echo $SHELLVAR
one
```

That is `name= command` from the top of this section, used on purpose: **a variable written in
front of a command is exported into that one command and nothing else.** The shell's own
`SHELLVAR` is still `one` afterwards.

This is how you run something once with a different setting — `LANG=C sort file`,
`DEBUG=1 ./deploy.sh` — without changing your shell.

## `declare`, and two flags worth knowing

```
ana@vm:~/work/scripts$ readonly PI=3.14; PI=3
bash: PI: readonly variable
ana@vm:~/work/scripts$ declare -i n=5; n=n+2; echo $n
7
ana@vm:~/work/scripts$ declare -p ENVVAR SHELLVAR n
declare -x ENVVAR="two"
declare -- SHELLVAR="one"
declare -i n="7"
```

`declare -i` makes a variable integer, so assignments to it are evaluated as arithmetic —
`n=n+2` gave `7` rather than the string `n+2`. It is occasionally handy and mostly a curiosity;
`$(( ))` is clearer.

`readonly` is the one to actually use, for the handful of things a script must not reassign.

**`declare -p` is the debugging tool**: it prints a variable with its type and its exact value,
quoted. When you are staring at output wondering whether a variable has a trailing space in it,
`declare -p` answers in one line where `echo` will not.

## Names

| | |
|---|---|
| `lower_case` | your own variables, by convention |
| `UPPER_CASE` | exported variables and constants, by convention |
| `PATH HOME USER PWD` | the system's. Do not assign to these by accident |

The convention matters more than it looks: **a script that does `PATH=/opt/mytool` instead of
`PATH=/opt/mytool:$PATH` has just lost every command on the machine**, and the failure is a cascade
of "command not found" that does not obviously point at the assignment.
