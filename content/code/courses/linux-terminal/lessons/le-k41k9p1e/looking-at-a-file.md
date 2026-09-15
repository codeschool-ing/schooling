---
title: Looking at a file before you process it
version: 1
---

Every pipeline in this lesson starts the same way: look at one line and work out what the fields
are. Skipping that step is how people write a `cut -f9` that takes the wrong column.

```
ana@vm:~/work$ head -1 logs/access.log
10.0.1.6 - - [14/Sep/2026:06:01:23 +0000] "GET /static/app.js HTTP/1.1" 200 3484 "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" 87
```

Count the space-separated fields and you have the map the rest of the lesson uses: the address is
`$1`, the timestamp is `$4` and `$5`, the method is `$6`, the path is `$7`, the status is `$9`, the
size is `$10`, and the milliseconds are last.

## `head` and `tail`

```
ana@vm:~/work$ head -3 logs/app.log
app started
app ready
app handled a request
ana@vm:~/work$ tail -3 logs/app.log
app started
app ready
app handled a request
```

Both default to ten lines. `-n 3` and `-3` are the same thing.

**`tail -n +29` is the one worth learning**, because the `+` changes what the number means:

```
ana@vm:~/work$ tail -n +29 logs/app.log
app ready
app handled a request
```

"From line 29 to the end", rather than "the last 29". **That is how you skip a header** —
`tail -n +2` on a CSV drops the first line and keeps everything else, which is a pattern you will
use constantly with section 126's `cut`.

`head -c 40` counts bytes rather than lines:

```
ana@vm:~/work$ head -c 40 logs/access.log; echo
10.0.1.6 - - [14/Sep/2026:06:01:23 +0000
```

Useful for looking at the start of something that may not have lines at all.

**And `tail -f` follows a file as it grows** — lesson 6's transcript with the `inotify` descriptor
was exactly this. `tail -F` is the version that copes with the file being rotated out from under it,
which on a log you are watching for more than a minute is the one you want.

## `cat`, and the two flags that make it worth using

`cat` prints whole files. Its useful options are about seeing what is *not* printable:

```
ana@vm:~/work$ cat -n logs/app.log | head -3
     1	app started
     2	app ready
     3	app handled a request
ana@vm:~/work$ cat -A logs/error.log
could not open data/report.csv$
```

`-n` numbers lines. **`-A` shows the invisible**: `$` for the end of a line, `^I` for a tab, and
`M-BM-` sequences for non-ASCII bytes.

That last one is the reason to know `cat -A` exists. When a config file will not parse, or a script
fails on a line that looks perfect, `cat -A` shows you the trailing space, the tab that should have
been spaces, or the `^M` at the end of every line that means the file came from Windows.

`nl` is `cat -n` with more control over the numbering, and it only numbers non-empty lines by
default:

```
ana@vm:~/work$ nl logs/app.log | head -3
     1	app started
     2	app ready
     3	app handled a request
```

**What `cat` is not for** is feeding one file into a command. `cat file | grep x` works, and
`grep x file` does the same thing with one fewer process. It is a harmless habit and it is worth
dropping, because the version without `cat` is shorter and lets `grep` name the file in its output.

## `less`, for when it does not fit

`less` is a full-screen pager, so there is nothing to paste here — the same property `htop` had in
lesson 6. What matters is the keys:

| | |
|---|---|
| `Space`, `b` | forward and back a page |
| `g`, `G` | first line, last line |
| `/text` | search forward; `n` for the next hit, `N` for the previous |
| `?text` | search backward |
| `-N` | turn line numbers on |
| `F` | follow, like `tail -f`. `Ctrl+C` stops following and leaves you in `less` |
| `q` | quit |

**`less +F` on a log is better than `tail -f`**, because `Ctrl+C` drops you into a pager holding
everything that has scrolled past, instead of ending the command.

`less` is also what `man` uses, which is why those keys work in a man page. And the name is a joke
about `more`, the older pager it replaced, which could only go forward.

## The order to do this in

1. **`head -1`** — what does a line look like?
2. **`wc -l`** — how much is there?
3. **`head -20` or `less`** — is every line that shape?

**Step three is the one people skip**, and it is where you find out that the file has a header, or a
blank line between records, or that fifty lines in the middle are a stack trace. Section 132's
`awk '{print NF}' | sort -u` is the fast version of that check, and on this log it finds four
different field counts on lines that all look the same.
