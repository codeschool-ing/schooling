---
title: What a message is for
version: 1
---

Here is a week of work, messaged the way people do when nobody asks them not to:

```
ana@vm:~/before$ git log --oneline
db63087 final
11fce14 more changes
b34fabb asdf
9fb788b fixed stuff
3699ea0 wip
4ede6f2 fix
83c90c8 changes
5d69802 update
ec3275a first
```

And the same week of the bakery's site as this course has kept it:

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

Nine commits each. The first log tells you nothing without opening every commit, and opening them
tells you what changed but never why. The second can be read like a list of what happened. **The
message is the only part of a commit that says why**, and the first line is the only part most people
ever see, one line of `git log --oneline` at a time.

## The first line

- **Say what the commit does, as an instruction**: *Add the menu*, *Take rye bread off until the flour
  arrives*. That is the imperative, and it matches Git's own messages, *Merge branch 'sunday'*,
  *Revert "…"*. A useful test: the line should complete the sentence *If applied, this commit will…*
- **Keep it short**, around 50 characters, because it is shown in lists that cut it off. Say the one
  thing; the details go below.
- **No full stop at the end.** It is a title.

*Fix* fails all three. It does not say what was fixed, and the person reading the log is the one who
has to open the commit to find out.

## The body

Leave one blank line after the first line and write as much as the change needs. **The body is for
why**, since the diff already shows what:

```
ana@vm:~/site$ git log -1
commit 3095dd7534445864bf0ed2cd7e304078cac1fe60
Author: Ana Souza <ana@example.com>
Date:   Mon Sep 21 09:00:00 2026 -0300

    Open at half past six from October to March
    
    The first bus from the station now arrives at 06:20, so customers
    waiting at half past five were standing outside for nearly an hour.
    Summer hours stay as they are.
```

The first line says what; the body says what problem it solved and what it deliberately did not
change. Wrap the lines at about 72 characters, because `git log` indents them and does not wrap
anything itself. Most commits need no body at all. A commit whose reason is not obvious from its first
line needs one, and those are exactly the ones somebody will wonder about later.

This is also why lesson 1 set an editor in `core.editor`: `-m` is fine for one line, and the editor is
where a body gets written.

## Who reads it

You, in six months, running `git blame` on a line that looks wrong, which lesson 3 promised leads to a
reason. A reviewer, reading the pull request's commits. Whoever writes the release notes. **A message
is written once and read many times**, so the minute it takes is the cheapest part of the change.
