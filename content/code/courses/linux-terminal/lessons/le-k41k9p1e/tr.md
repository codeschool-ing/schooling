---
title: `tr`, which works on characters and not words
version: 1
---

`tr` translates one set of characters into another. It has no idea what a word is, no idea what a
line is, and no pattern language — and that narrowness is what makes it the right tool for four
specific jobs.

**It only reads stdin.** There is no filename argument; `tr a-z A-Z < file` or a pipe.

## Case

```
ana@vm:~/work$ echo "Hello World" | tr a-z A-Z
HELLO WORLD
```

`tr '[:lower:]' '[:upper:]'` is the locale-aware spelling and is better on non-English text.

## One character for another

```
ana@vm:~/work$ echo "a,b,c" | tr , "\n"
a
b
c
ana@vm:~/work$ printf "a\tb\tc\n" | tr "\t" ","
a,b,c
```

**Turning a delimiter into newlines is the most useful thing `tr` does**, because it converts "a
line with things on it" into "things, one per line" — which is the shape every other tool in this
lesson wants.

The two sets are matched up position by position: `tr abc xyz` turns every `a` into `x`, `b` into
`y`, `c` into `z`. If the second set is shorter, its last character is repeated.

## `-d` deletes

```
ana@vm:~/work$ cut -d" " -f1 logs/access.log | tr -d "." | head -2
10016
100111
```

Every dot gone. That example is deliberately silly — the addresses are now meaningless — and it
makes the point: **`tr -d` removes characters, with no idea whether that was sensible.**

The real uses are removing things that should not be there:

```
tr -d '\r' < windows.txt > unix.txt     # strip carriage returns
tr -d '[:blank:]'                       # strip spaces and tabs
tr -dc '[:print:]\n'                    # keep only printable characters
```

**`tr -d '\r'` is the one you will actually need:**

```
ana@vm:~/work$ printf "line one\r\nline two\r\n" > /tmp/w.txt; cat -A /tmp/w.txt
line one^M$
line two^M$
ana@vm:~/work$ tr -d '\r' < /tmp/w.txt | cat -A
line one$
line two$
```

A file edited on Windows has `\r\n` at the end of every line. Section 05's `cat -A` shows it as
`^M$`, and a shell script with those endings fails with an error that names a command you can see
is spelled correctly — because the command it actually tried to run had an invisible carriage
return on the end of its name.

`-c` complements the set, so `-dc` is "delete everything except". That last line is the sanitiser
for a file with stray control characters in it.

## `-s` squeezes runs

```
ana@vm:~/work$ head -2 logs/access.log | tr -s " " | cut -d" " -f1,6,7
10.0.1.6 "GET /static/app.js
10.0.1.11 "GET /
```

**This is the fix for section 08's one-character delimiter.** `tr -s " "` turns any run of spaces
into a single space, which makes `cut -d" "` work on text that is aligned with padding rather than
separated by one character.

`tr -s '\n'` collapses blank lines — several empty lines become one — which tidies up output before
you read it.

## The four uses worth remembering

| | |
|---|---|
| `tr a-z A-Z` | case |
| `tr , '\n'` | split on a character, one per line |
| `tr -d '\r'` | strip carriage returns from a Windows file |
| `tr -s ' '` | squeeze runs, so `cut` can work |

## What `tr` cannot do

**It cannot replace a word:**

```
ana@vm:~/work$ echo "cat attack" | tr cat dog
dog oggodk
ana@vm:~/work$ echo "cat attack" | sed "s/cat/dog/g"
dog attack
```

`tr cat dog` turns every `c` into `d`, every `a` into `o` and every `t` into `g`. `cat` does become
`dog` — which is why this looks like it works until you give it a second word. Replacing a word is
section 13's `sed`.

**It has no patterns.** No `.`, no `*`, no anchors. Sets of characters and nothing else.

**And it cannot insert.** The two sets are the same length by construction, so one character becomes
one character. Deleting is the only change of length it can make.

Which is the dividing line: **`tr` for characters, `sed` for patterns, `awk` for fields.** Reaching
for `sed` when `tr -d '\r'` would do is a common and harmless waste; reaching for `tr` when you
meant `sed` produces `oggodk`.
