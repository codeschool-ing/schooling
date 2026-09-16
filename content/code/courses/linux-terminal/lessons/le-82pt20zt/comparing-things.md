---
title: Comparing things, and why `[[` exists
version: 1
---

Numbers and strings do not compare the same way, and the shell makes you say which you meant.

```
ana@vm:/tmp/q$ x=10; y=9
ana@vm:/tmp/q$ [ "$x" -gt "$y" ] && echo 'numeric: 10 > 9'
numeric: 10 > 9
ana@vm:/tmp/q$ [ "$x" \> "$y" ] && echo 'string: 10 > 9' || echo 'string: 10 is not > 9'
string: 10 is not > 9
```

**Ten is greater than nine, and `"10"` sorts before `"9"`.** Both answers are right; only one of
them is the question you asked.

| numbers | strings | |
|---|---|---|
| `-eq` | `=` | equal |
| `-ne` | `!=` | not equal |
| `-lt` `-le` | `\<` | less |
| `-gt` `-ge` | `\>` | greater |

**The letters are for numbers, the symbols are for strings**, which is exactly backwards from every
other language and is the reason to say it out loud once.

And the `\` on `\<` is because `<` inside `[ ]` is a redirection — section 17 has that bug caught
in the act.

## Emptiness

```
ana@vm:/tmp/q$ [ -z "$empty" ] && echo 'empty is empty'
empty is empty
ana@vm:/tmp/q$ [ -n "$x" ] && echo 'x is not empty'
x is not empty
```

`-z` is zero-length, `-n` is non-zero-length. The quotes on `-n` are not optional:

```
ana@vm:/tmp/q2$ empty=; [ -n $empty ] && echo 'says non-empty' || echo 'says empty'
says non-empty
ana@vm:/tmp/q2$ empty=; [ -n "$empty" ] && echo 'says non-empty' || echo 'says empty'
says empty
```

**Unquoted, `[ -n $empty ]` became `[ -n ]`** — `[` with a single argument, which is true whenever
that argument is a non-empty string, and `-n` is a non-empty string. The test answered a question
about the word `-n`.

## The quotes are not advice here

```
ana@vm:/tmp/q$ empty=
ana@vm:/tmp/q$ [ $empty = yes ]; echo "status $?"
bash: [: =: unary operator expected
status 2
ana@vm:/tmp/q$ [ "$empty" = yes ]; echo "status $?"
status 1
ana@vm:/tmp/q$ [[ $empty = yes ]]; echo "status $?"
status 1
```

Three ways to ask the same question. The first is a syntax error, because `[` was handed `= yes ]`
and there is no such test. The second works. **The third works without the quotes**, and that is
what `[[ ]]` is for.

Note the status too: **`[` returns 2 for "you asked me something malformed"**, distinct from 1 for
"false". A script testing `if [ … ]` cannot tell those apart, which is another reason not to reach
this state.

## `[[ ]]`, which is bash and not a command

`[[` is shell syntax — not a program — so the shell parses what is inside it rather than expanding
it into arguments first. Three things follow.

**No word splitting and no globbing**, as above.

**`<` and `>` mean comparison**, with no escaping.

**And `==` does glob matching:**

```
ana@vm:/tmp/q2$ name=report.log
ana@vm:/tmp/q2$ [[ $name == *.log ]] && echo match || echo 'no match'
match
```

That is a pattern, not a string. `[[ $host == web* ]]`, `[[ $f == *.tar.gz ]]` — the same syntax as
`case` in the next section, and the same syntax as globbing in lesson 3 section 10.

Quote the right-hand side and it becomes a literal again:

```
ana@vm:/tmp/q2$ name=report.log; [[ $name == "*.log" ]] && echo match || echo 'no match'
no match
```

That compared against the five characters `*.log`. Which is occasionally what you want, and is
always what you get by accident when you quote out of habit.

### What `[` does with the same line

This is worth watching closely, because it fails in three different ways depending on what is in
the directory:

```
ana@vm:/tmp/q2$ cd /tmp/q2 && rm -f *.log && ls
ana@vm:/tmp/q2$ name=report.log
ana@vm:/tmp/q2$ [ "$name" == *.log ] && echo match || echo 'no match'
no match
ana@vm:/tmp/q2$ touch other.log && ls
other.log
ana@vm:/tmp/q2$ [ "$name" == *.log ] && echo match || echo 'no match'
no match
ana@vm:/tmp/q2$ touch third.log && ls
other.log  third.log
ana@vm:/tmp/q2$ [ "$name" == *.log ] && echo match || echo 'no match'
bash: [: too many arguments
no match
ana@vm:/tmp/q2$ [[ $name == *.log ]] && echo match || echo 'no match'
match
```

One line of script, three outcomes, decided by files it never mentioned:

| files present | what `[` actually received | result |
|---|---|---|
| none | `report.log == *.log` — the glob matched nothing, so it stayed literal | false |
| one | `report.log == other.log` | false, **for the wrong reason** |
| two | `report.log == other.log third.log` | too many arguments |

**The shell expanded the pattern before `[` ever ran**, because `[` is a command and that is what
happens to a command's arguments. The middle row is the one to be frightened of: no error, an
answer, and the answer depends on the working directory.

### Regular expressions

```
ana@vm:/tmp/q$ [[ $name =~ ^report\.[a-z]+$ ]] && echo 'matches the regex'
matches the regex
ana@vm:/tmp/q$ echo "BASH_REMATCH: ${BASH_REMATCH[0]}"
BASH_REMATCH: report.log
```

`=~` takes an extended regular expression — lesson 8 section 07's syntax — and fills `BASH_REMATCH`
with the match and its capture groups.

**Do not quote the pattern.** The same trap as `==`, and it is quieter, because a quoted regex
never errors — it just never matches:

```
ana@vm:/tmp/q2$ n=42; [[ $n =~ "^[0-9]+$" ]] && echo match || echo 'no match'
no match
ana@vm:/tmp/q2$ n=42; [[ $n =~ ^[0-9]+$ ]] && echo match || echo 'no match'
match
ana@vm:/tmp/q2$ re='^[0-9]+$'; [[ $n =~ $re ]] && echo match || echo 'no match'
match
```

The third line is the idiom for a long pattern: put it in a variable, in single quotes, and then
use the variable **unquoted**.

The one thing `=~` is genuinely the right tool for is validating an argument:

```sh
[[ $threshold =~ ^[0-9]+$ ]] || die "-t wants a number, got '$threshold'"
```

## File tests

```
ana@vm:/tmp/q2$ ls -l
total 8
lrwxrwxrwx 1 ana ana    7 Sep 15 10:02 broken -> nowhere
drwxr-xr-x 2 ana ana 4096 Sep 15 10:02 d
-rw-r--r-- 1 ana ana    0 Sep 15 10:02 empty
-rw-r--r-- 1 ana ana    5 Sep 15 10:02 f
lrwxrwxrwx 1 ana ana    1 Sep 15 10:02 good -> f
ana@vm:/tmp/q2$ for t in -e -f -d -s -x -L; do [ $t f ] && echo "$t yes" || echo "$t no"; done
-e yes
-f yes
-d no
-s yes
-x no
-L no
```

| | |
|---|---|
| `-e` | exists |
| `-f` | exists and is a **regular** file |
| `-d` | is a directory |
| `-s` | exists and is **not empty** |
| `-r` `-w` `-x` | you can read / write / execute it |
| `-L` | is a symbolic link |
| `a -nt b` | `a` is newer than `b` |

Two of these have a subtlety worth having seen:

```
ana@vm:/tmp/q2$ [ -e broken ] && echo 'broken: exists' || echo 'broken: -e says no'
broken: -e says no
ana@vm:/tmp/q2$ [ -L broken ] && echo 'broken: -L says yes'
broken: -L says yes
ana@vm:/tmp/q2$ [ -s empty ] && echo 'empty has size' || echo 'empty: -s says no'
empty: -s says no
```

**`-e` follows symlinks**, so a dangling link does not exist as far as it is concerned — even
though `ls` shows it and `rm` can delete it. `-L` is the one that asks about the link itself.

And **`-f` is not "there is a file there"** — it is "there is a regular file there", which excludes
directories, devices and the `/dev/stdin` sort of thing. When you mean "I can read this", `-r` says
so more precisely than `-f`.

## Which bracket to use

**Use `[[ ]]`.** It is safer in every way that matters: no splitting, no accidental globbing,
`&&` and `||` inside it, pattern matching, regular expressions.

Use `[ ]` when the script has `#!/bin/sh` at the top, because `[[` is bash and dash does not have
it — section 02. That is the only reason.

And whichever you use, quote your variables anyway. The habit is worth more than the exception.
