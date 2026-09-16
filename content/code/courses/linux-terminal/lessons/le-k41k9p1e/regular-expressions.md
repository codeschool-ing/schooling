---
title: Regular expressions, the useful half
version: 1
---

A regular expression is a pattern that describes a set of strings. There is a great deal of it and
you need about a dozen pieces, which is what this section is.

Everything here uses `grep -E`. Section 06 explained why: the basic syntax needs backslashes in
front of half of it, for no benefit.

## Matching one character

```
ana@vm:~/work$ printf "cat\ncot\ncut\ncoat\n" | grep -E "c.t"
cat
cot
cut
ana@vm:~/work$ printf "cat\ncot\ncut\ncoat\n" | grep -E "c[ao]t"
cat
cot
ana@vm:~/work$ printf "cat\ncot\ncut\ncoat\n" | grep -E "c[^o]t"
cat
cut
```

| | |
|---|---|
| `.` | any one character. **Not** "a full stop" |
| `[abc]` | any one of these |
| `[^abc]` | any one **except** these |
| `[a-z]`, `[0-9]` | ranges |

`coat` matched none of the three, because all three describe exactly three characters and `coat` is
four.

**`[^o]` means "a character that is not `o`", not "no character".** A line with nothing between `c`
and `t` does not match it.

## How many

```
ana@vm:~/work$ printf "color\ncolour\n" | grep -E "colou?r"
color
colour
ana@vm:~/work$ printf "a\naa\naaa\n" | grep -E "^a{2,}$"
aa
aaa
```

| | |
|---|---|
| `?` | zero or one |
| `*` | zero or more |
| `+` | one or more |
| `{2}` | exactly two |
| `{2,}` | two or more |
| `{2,5}` | between two and five |

**They apply to the thing immediately before them**, so `ab*` is "an `a` then any number of `b`s",
and `(ab)*` is "any number of `ab`s".

## Where

```
ana@vm:~/work$ printf "2026-09-15\nnot a date\n15/09/2026\n" | grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
2026-09-15
```

| | |
|---|---|
| `^` | the start of the line |
| `$` | the end of the line |
| `\b` | a word boundary — `grep -w` is the readable version |

**`^` and `$` together are how you say "exactly this and nothing else".** Without them, that pattern
would also match a line with a date somewhere in the middle of it, which is usually not what you
meant.

And note `^` means two different things: **at the start of a pattern it is an anchor; inside `[ ]`
it is negation.** `[^^]` is a character that is not a caret, and it is legal.

## Alternatives and groups

```
ana@vm:~/work$ printf "cat\ndog\nbird\n" | grep -E "cat|dog"
cat
dog
ana@vm:~/work$ grep -cE "^(10|198)\." logs/access.log
997
```

`|` is "or". `( )` groups, both for `|` and for repetition.

In basic `grep` those need to be written `\|` and `\( \)`, which is the tax `-E` removes.

## The one that catches everybody

```
ana@vm:~/work$ printf "10.50\n10050\n10x50\n" | grep -E "10.50"
10.50
10050
10x50
ana@vm:~/work$ printf "10.50\n10050\n10x50\n" | grep -E "10\.50"
10.50
ana@vm:~/work$ printf "10.50\n10050\n10x50\n" | grep -F "10.50"
10.50
```

**The first pattern matched all three lines**, because `.` is any character and `10050` and `10x50`
both have one there.

Two fixes, and they are for different situations. **`\.` escapes it** when the rest of the pattern
is still a pattern. **`-F` turns the whole pattern language off** when it is not — which is the
right answer for an IP address, a version number, a file path, and anything a user typed.

The characters that need escaping in an extended regex are `. ^ $ * + ? ( ) [ ] { } | \`. Reaching
for `-F` is easier than remembering that list.

## Character classes with names

`[[:digit:]]` and `[0-9]` do the same thing, and the named ones are worth knowing because they are
locale-aware and readable:

| | |
|---|---|
| `[[:digit:]]` | `0-9` |
| `[[:alpha:]]` | letters |
| `[[:alnum:]]` | letters and digits |
| `[[:space:]]` | space, tab, newline |
| `[[:upper:]]`, `[[:lower:]]` | case |

The double brackets look wrong and are not: the outer pair is the character class, the inner is the
name. `[[:digit:].]` is "a digit or a full stop".

## Greedy, and why it surprises you

```
ana@vm:~/work$ grep -oE "\"[A-Z]+ [^ ]+" logs/access.log | head -3
"GET /static/app.js
"GET /
"POST /index.html
```

That works because `[^ ]+` stops at a space. The version that does not work is `".*"` on a line with
two quoted strings in it: **`*` and `+` take as much as they can**, so `.*` between two quotes
matches from the first quote to the *last* one, swallowing everything in between.

The fix in a basic regex is to say what you actually mean — `[^"]*` instead of `.*` — because grep
has no lazy quantifier. **"Anything except the delimiter" is almost always what you wanted anyway.**

## What to remember

A dozen pieces, and the discipline is: **test the pattern on three lines before running it on a
million.** `printf` and a pipe, as in every transcript on this page, takes ten seconds and catches
the greedy `.*` and the unescaped dot before they matter.

`grep -o` is the other half of that discipline: it prints **what matched** rather than the line that
contained it, so you can see whether the pattern took what you expected.
