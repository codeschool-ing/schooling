---
title: `wc`, and what "a line" means
version: 1
---

`wc` counts. Three numbers, in a fixed order:

```
ana@vm:~/work$ wc logs/access.log
  1200  16995 148233 logs/access.log
```

**Lines, words, bytes.** And with flags, one at a time:

| | |
|---|---|
| `-l` | lines |
| `-w` | words — runs of non-whitespace |
| `-c` | **bytes** |
| `-m` | **characters**, which differs from `-c` on anything non-ASCII |
| `-L` | the length of the longest line |

```
ana@vm:~/work$ wc -l logs/*.log
  1200 logs/access.log
    30 logs/app.log
     0 logs/empty.log
     1 logs/error.log
  1231 total
```

Several files gets you a `total`, which is convenient and is also a line you have to remember to
drop if you are feeding it onward.

## `wc -l` counts newlines

This is the whole of the section, and it explains an off-by-one that people hit once:

```
ana@vm:~/work$ printf "no newline at the end" > frag.txt; wc -l frag.txt; grep -c . frag.txt
0 frag.txt
1
```

**One file, one line of text, and two answers: zero and one.**

`wc -l` counts **newline characters**, and that file has none. `grep -c .` counts lines that contain
at least one character, and finds one.

Neither is wrong. They are answering different questions, and the difference only shows up on a
file whose last line has no newline — which is common in files written by programs, and in anything
that came out of a Windows editor or a copy-paste.

**So: `wc -l` is right for files that end properly, and `grep -c ''` is right when you are not
sure.** On a well-formed file they agree:

```
ana@vm:~/work$ grep -c . logs/app.log; wc -l < logs/app.log
30
30
```

## `-c` against `-m`

`-c` is bytes and `-m` is characters, and on UTF-8 text they differ whenever anything is not ASCII.
A file of accented Portuguese text will have more bytes than characters, because `ã` is two bytes.

**Use `-c` when you care about disk or transfer size** and `-m` when you care about how much text
there is. And note that `head -c` from section 123 is bytes too, which is why cutting a UTF-8 file
at an arbitrary byte can split a character in half.

## Counting things that are not lines

Most counting questions are not "how many lines in this file", they are "how many of *these*", and
the shape is always the same:

```
grep -c " 500 " logs/access.log              # lines matching
grep -o "GET" logs/access.log | wc -l        # occurrences, not lines
cut -d" " -f1 logs/access.log | sort -u | wc -l   # distinct values
ls -1 | wc -l                                # files in a directory
```

**The third one is the pattern worth keeping**: `sort -u | wc -l` is "how many different", and it is
a different question from "how many". On this log there are twelve hundred requests and far fewer
addresses.

`ls -1 | wc -l` has the caveat lesson 3 gave: it misses dotfiles, and a filename containing a
newline would be counted twice. `find . -maxdepth 1 -type f | wc -l` is the careful version, and
`ls -1A | wc -l` includes the dotfiles.

## `wc` on stdin, and the filename

```
wc -l logs/app.log       # prints "30 logs/app.log"
wc -l < logs/app.log     # prints "30"
```

Section 120 showed this. In a script, **the second form is the one you want**, because the output
is a number and not a number plus a name you then have to `cut` off.

`$(wc -l < file)` is the idiom, and it is why the redirect is worth the extra character.
