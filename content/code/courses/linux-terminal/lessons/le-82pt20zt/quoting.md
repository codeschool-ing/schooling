---
title: Quoting, which is where the bugs live
version: 1
---

More shell bugs come from quoting than from everything else in this lesson combined. The reason is
that **an unquoted expansion is not one value — it is a list of words, and the shell decides how
many.**

There are three kinds of quoting and they differ in exactly one way: what they still let the shell
do.

```
ana@vm:~/work/scripts$ who='ana'
ana@vm:~/work/scripts$ echo "double: $who"
double: ana
ana@vm:~/work/scripts$ echo 'single: $who'
single: $who
ana@vm:~/work/scripts$ echo "escaped: \$who"
escaped: $who
```

| | |
|---|---|
| `"double"` | expands `$var`, `` `cmd` ``, `$(cmd)` and `\`. Blocks splitting and globbing |
| `'single'` | expands nothing at all. The only thing it cannot contain is a single quote |
| `\x` | one character, taken literally |

**Single quotes are the strong ones.** Anything between them arrives exactly as written, which is
why every regular expression, every `awk` program and every `sed` command in the last lesson was in
single quotes: `$1` inside double quotes would have been the shell's first argument, not awk's
first field.

## What double quotes actually stop

Not expansion — they let that through. They stop the *two things that happen after* it.

```
ana@vm:/tmp/q$ touch 'my file.txt' plain.txt a.log b.log
ana@vm:/tmp/q$ f='my file.txt'
ana@vm:/tmp/q$ ls -l $f
ls: cannot access 'my': No such file or directory
ls: cannot access 'file.txt': No such file or directory
ana@vm:/tmp/q$ ls -l "$f"
-rw-r--r-- 1 ana ana 0 Sep 15 10:00 'my file.txt'
```

**The variable held one filename and `ls` received two arguments.** The shell expanded `$f` to
`my file.txt` and then split it on whitespace, because that is what it does to the *result* of an
unquoted expansion. This is called word splitting.

The second one is globbing:

```
ana@vm:/tmp/q$ pattern='*.log'
ana@vm:/tmp/q$ echo $pattern
a.log b.log
ana@vm:/tmp/q$ echo "$pattern"
*.log
```

Same variable, same two characters in it, two different results — because unquoted, the `*` that
came *out* of the variable was then matched against the directory.

So: **`"$var"` means "this one value"; `$var` means "cut this into words and then expand any
wildcards in them".** You want the first one approximately always.

## The whitespace goes too

```
ana@vm:/tmp/q$ sentence='one   two'
ana@vm:/tmp/q$ echo $sentence
one two
ana@vm:/tmp/q$ echo "$sentence"
one   two
```

Word splitting does not just separate — it collapses. Three spaces became one, because the shell
split into two words and `echo` joined them with a single space. If your script is reformatting
its own data, this is why.

## The empty variable, which is the dangerous one

```
ana@vm:/tmp/q$ empty=
ana@vm:/tmp/q$ echo "rm -rf /var/cache/$empty/*"
rm -rf /var/cache//*
```

That is an `echo`, so nothing happened. Take the `echo` away and read it again.

**An unset or empty variable expands to nothing, and the path around it closes up.** A script
meant to clear one application's cache directory clears every application's. There is no error, no
warning, and the command is syntactically perfect.

Quoting does not save you here — `"$empty"` is still empty. Three things do, and you should use
all three:

| | |
|---|---|
| `set -u` | section 143. An unset variable becomes an error rather than an empty string |
| `${var:?message}` | section 152. Refuse to expand, with your own message |
| `[ -n "$var" ] \|\| exit 1` | check it yourself, early |

## Command substitution is an expansion too

```
ana@vm:/tmp/q$ count=$(ls | wc -l); echo "there are $count entries"
there are 4 entries
```

`$(...)` runs a command and becomes its output — and that output is then subject to the same
splitting and globbing as anything else. **`$(command)` unquoted is the same bug as `$var`
unquoted**, and it is more likely, because command output is more likely to contain spaces.

## The rule

**Double quote every expansion, every time.** `"$var"`, `"$@"`, `"$(cmd)"`, `"${arr[@]}"`.

Not "when the value might have a space in it" — always, because you do not know what will be in
that variable on a machine you have not seen, on a day when a filename has a space in it because
somebody exported it from a spreadsheet.

There are two places where you can leave them off:

```
[[ $count -gt 5 ]]      # inside [[ ]] no splitting or globbing happens, so quotes are optional
cmd $FLAGS              # when you deliberately want one variable to become several arguments
```

`[[ ]]` is section 145, and the quotes are still not *wrong* there — they just change nothing.
The second line is a real technique and is also how people get hurt; when you need it, an array
(section 149) does the same job and keeps the words you meant.

Note that `[ ]` — one bracket — is **not** on that list. It is an ordinary command, its arguments
are split like any other command's, and section 145 shows what that costs.

`shellcheck` (section 154) flags every missing quote in a file in under a second, which is a better
proofreader than this paragraph.
