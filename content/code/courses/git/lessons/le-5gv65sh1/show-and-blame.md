---
title: Show, blame, and finding the commit
version: 1
---

The log tells you a commit exists. Three more commands take you from *somewhere in this file* to *the
exact commit, and its reason*.

## git show: one commit, whole

```
ana@vm:~/site$ git show HEAD~3
commit 1b2d576126103b29221b62bff65378012554c501
Author: Bruno Lima <bruno@example.com>
Date:   Wed Sep 16 16:25:00 2026 -0300

    Put the prices up for September

diff --git a/menu.html b/menu.html
index 88e1ab8..ca66507 100644
--- a/menu.html
+++ b/menu.html
@@ -1,3 +1,3 @@
 <h1>Menu</h1>
-<p>French bread, 0.80</p>
-<p>Rye bread, 1.20</p>
+<p>French bread, 0.90</p>
+<p>Rye bread, 1.35</p>
```

**`git show` is a commit's log entry followed by its diff** against its parent. Two prices went up,
each shown as a line removed and a line added, with Bruno's name and his reason above them. This is
what you open when somebody says *"the September price change"* and you want to see it.

Put a path after the commit, separated by a colon, and you get the file as it was at that commit
instead:

```
ana@vm:~/site$ git show HEAD~3:menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Rye bread, 1.35</p>
```

That is the menu on Wednesday evening, rye bread and all. Nothing on the disk changed: `git show`
only prints. Lesson 4 is how to bring an old version back.

## git blame: who wrote each line

```
ana@vm:~/site$ git blame menu.html
c3e07c2c (Ana Souza  2026-09-14 14:10:00 -0300 1) <h1>Menu</h1>
1b2d5761 (Bruno Lima 2026-09-16 16:25:00 -0300 2) <p>French bread, 0.90</p>
31a6298b (Ana Souza  2026-09-17 10:15:00 -0300 3) <p>Cheese roll, 2.50</p>
```

**Every line of the file, with the commit that last changed it**, its author and when. Line 2 is
Bruno's, from the price change; line 3 is Ana's, from the day cheese rolls were added. Take any of
those short ids to `git show` and you have the message that explains it.

The name is the worst thing about the command. Its real use is the opposite of blaming: you find a
line that looks wrong, and blame leads you to the commit, which usually says why it is right, or at
least who to ask. `-L 2,3` limits it to a range of lines, which matters in a file of a thousand.

## git log -S: when the line is gone

Blame only sees lines that exist now. Rye bread is not on the menu, so blame cannot say where it went.
**`-S` searches the history for commits that added or removed a piece of text**:

```
ana@vm:~/site$ git log -S "Rye" --oneline
eadf998 Take rye bread off until the flour arrives
95e3b9d Add rye bread to the menu
```

Two commits: the one that put *Rye* in, and the one that took it out, with the reason in the message.
It is the quickest way to answer *"when did this disappear?"*, and people call it the pickaxe.

Those four — `log`, `diff`, `show` and `blame` — with `-S` for what is no longer there, answer
nearly every question a history can be asked.
