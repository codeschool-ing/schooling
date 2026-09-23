---
title: Reading the log
version: 1
---

Lesson 1 showed the log once. This is how you actually use it: the default format, the short one,
and the filters that turn a long history into the three commits you were looking for.

## The two formats you will use most

With no options, `git log` prints every commit, newest first, in full. Limit it with a number:

```
ana@vm:~/site$ git log -2
commit 6555c9b314e48ad30e5c97a2ec1c8657347caa91
Author: Ana Souza <ana@example.com>
Date:   Fri Sep 18 15:30:00 2026 -0300

    Link the menu from the home page

commit eadf99876ab90aa5308943f849d4eef920bc363f
Author: Bruno Lima <bruno@example.com>
Date:   Fri Sep 18 08:50:00 2026 -0300

    Take rye bread off until the flour arrives
```

That is the format for reading carefully. For looking around, the one-line form fits a week of work
on one screen:

```
ana@vm:~/site$ git log --oneline
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
31a6298 Add cheese rolls
1b2d576 Put the prices up for September
8577a83 Open at half past five
95e3b9d Add rye bread to the menu
c3e07c2 Add the menu
5d6d04f Give the heading its colour
6abda31 Add the home page
```

Nine commits, two people, one week. **Each line is a short id and the first line of the message**,
which is why lesson 11 spends time on what that first line says: it is the only part most people
will ever read.

## What a commit touched

`--stat` adds the files each commit changed. Here it is on one commit, picked with `HEAD~3`:

```
ana@vm:~/site$ git log --stat -1 HEAD~3
commit 1b2d576126103b29221b62bff65378012554c501
Author: Bruno Lima <bruno@example.com>
Date:   Wed Sep 16 16:25:00 2026 -0300

    Put the prices up for September

 menu.html | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

**`HEAD` is the commit you are on, and `HEAD~3` is three commits before it** — follow `parent`
three times. You can use a short id instead, `1b2d576`, and anything that names a commit is accepted
wherever Git wants one. The stat line says `menu.html | 4 ++--`: four lines touched in one file, two
added and two removed, which is what changing two prices looks like.

## Filters

A history of a few hundred commits is ordinary, and nobody reads it from the top. Four filters do
most of the narrowing:

```
ana@vm:~/site$ git log --oneline --author=Bruno
eadf998 Take rye bread off until the flour arrives
1b2d576 Put the prices up for September
95e3b9d Add rye bread to the menu
ana@vm:~/site$ git log --oneline -- index.html
6555c9b Link the menu from the home page
8577a83 Open at half past five
6abda31 Add the home page
ana@vm:~/site$ git log --oneline --since=2026-09-17
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
ana@vm:~/site$ git log --oneline --grep=price
1b2d576 Put the prices up for September
```

- `--author=Bruno` keeps the commits whose author matches. It is a pattern, so a first name is
  enough.
- `-- index.html` keeps the commits that changed that file. The `--` separates file names from
  everything else, and it is a good habit even when Git could guess.
- `--since=2026-09-17` keeps what happened on or after a date. `--until` is the other end, and both
  accept `"2 weeks ago"` as well as a date.
- `--grep=price` searches the messages. It found *prices* too, because it matches a pattern and not
  a whole word.

**They combine.** `git log --oneline --author=Bruno -- menu.html` is every change Bruno made to the
menu, and it is usually faster to type that than to scroll.

One more thing the log does quietly: **it stops at the first screen and waits** when the output is
longer than the terminal, the way `less` does. Space moves on and `q` leaves. The transcripts in
this lesson were captured without that, which is why they end where the output ends.
