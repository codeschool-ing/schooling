---
title: Search and substitute, which is `sed` with a view
version: 1
---

## Searching

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│/timeout                                              4,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`/timeout` then Enter. The cursor is on line 4 and the bottom line shows what you
searched for.

| | |
|---|---|
| `/text` | search forward |
| `?text` | search backward |
| `n` | next match, same direction |
| `N` | previous match |
| `*` | search forward for the **word under the cursor** |
| `#` | the same, backwards |

**`*` is the one to learn.** Put the cursor on an identifier, press `*`, and you
are walking through every occurrence of it with `n` — no typing, no spelling
mistakes.

## It wraps, and it tells you

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│search hit BOTTOM, continuing at TOP                  4,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

That is `G` — go to the last line — and then `/timeout`. There is nothing below
line 6, so the search wrapped round to the top and landed on line 4.

**`search hit BOTTOM, continuing at TOP` is vim telling you there was nothing
below where you were.** It is easy to read past, and it is the difference between
"there is one match, behind me" and "there are matches ahead".

`:set nowrapscan` turns the wrapping off and makes the search fail instead, which
some people prefer for exactly that reason.

## The patterns are regular expressions

Section 125's syntax, with vim's own dialect on top:

```sh
/^listen              # lines starting with listen
/log_.*info           # log_ then anything then info
/\<log\>              # the whole word log, not log_level
/30$                  # 30 at the end of a line
```

**`\<` and `\>` are word boundaries** and are vim's spelling of `\b`. And by
default vim's "magic" level means `+`, `?`, `(` and `|` need backslashes, which
is why you will see `\(` and `\|` in other people's patterns.

`\v` at the start of a pattern turns on "very magic" and makes it behave like the
extended regular expressions of section 125: `/\v(listen|timeout)` rather than
`/listen\|timeout`.

## Case

| | |
|---|---|
| default | case **sensitive** |
| `:set ignorecase` | case insensitive |
| `:set ignorecase smartcase` | insensitive, unless your pattern has a capital in it |

**`ignorecase` plus `smartcase` is what almost everybody wants**, and it is in
the next section's `.vimrc`.

## Substitute

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│LOG_level info                                                          │
│LOG_file /var/LOG/app.LOG                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│4 substitutions on 2 lines                            6,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`:%s/log/LOG/g`, and vim says **`4 substitutions on 2 lines`**.

**Read that number.** Four, on two lines. If you expected one, you have just
learned something before you saved rather than after.

The shape is the same as `sed`'s from section 131, with a range on the front:

```
:[range]s/pattern/replacement/[flags]
```

| range | |
|---|---|
| nothing | this line only |
| `%` | the whole file |
| `1,10` | lines 1 to 10 |
| `.,$` | from here to the end |
| `'<,'>` | the visual selection — vim types this for you |

| flag | |
|---|---|
| `g` | **every** match on each line, not just the first |
| `c` | **confirm** each one |
| `i` | ignore case for this substitution |
| `n` | count the matches and change nothing |

**`g` is not the default**, exactly as in `sed`, and for exactly the same
reason — and it is the same bug, appearing only on lines where the thing occurs
twice.

Two flags are worth more than they look.

**`:%s/old/new/gc`** asks about each match, with `y`, `n`, `a` for all the rest,
`q` to stop, and `l` for this one and then stop. On a file you did not write, it
is the difference between a change and an accident.

**`:%s/pattern//gn`** changes nothing and reports how many matches there are.
It is `grep -c` without leaving the editor, and it is the right thing to run
*before* the substitution rather than after it.

## The separator is what you type

`s#…#…#` and `s|…|…|` work the same way, which matters for the same reason as in
section 131: a path full of slashes inside `s/…/…/` needs every one escaped.

```sh
:%s#/usr/local#/opt#g        # readable
:%s/\/usr\/local/\/opt/g     # the same, and nobody can check it by eye
```

## When to use `.` instead

`:%s` changes everything at once and reports a number. `.` from section 198
changes one at a time and you watch each one.

**For a file you understand, `:%s/…/…/g`.** For a file somebody else wrote, or a
pattern you are not sure of, `/pattern` then `ciwnew<Esc>` then `n` and `.` —
slower, and you see what you are doing.
