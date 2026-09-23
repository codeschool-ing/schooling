---
title: One change per commit
version: 1
---

A good message is easy to write for a commit that does one thing, and impossible for one that does
five. *"Fix the opening days, raise the price of bread, and rename the stylesheet"* is a sign the commit
should have been three. The habit that produces good messages is **one change per commit**:
something that could be reverted on its own without undoing anything else.

## Staging part of your work

Ana has two changes waiting, for two different reasons: the opening days on the home page, and the
price of French bread. She wants a commit for the first only. `git add -p`, *patch*, shows each change
and asks about it:

```
ana@vm:~/site$ git diff --stat
 index.html | 2 +-
 menu.html  | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
ana@vm:~/site$ git add -p
diff --git a/index.html b/index.html
index 7835499..641de19 100644
--- a/index.html
+++ b/index.html
@@ -1,3 +1,3 @@
 <h1>Padaria Sol</h1>
-<p>Bread from half past six.</p>
+<p>Bread from half past six, Monday to Saturday.</p>
 <p><a href="menu.html">See the menu</a></p>
(1/1) Stage this hunk [y,n,q,a,d,e,?]? y

diff --git a/menu.html b/menu.html
index a359181..ec5fc26 100644
--- a/menu.html
+++ b/menu.html
@@ -1,4 +1,4 @@
 <h1>Menu</h1>
-<p>French bread, 0.90</p>
+<p>French bread, 0.95</p>
 <p>Cheese roll, 2.60</p>
 <p>Carrot cake, 3.00</p>
(1/1) Stage this hunk [y,n,q,a,d,e,?]? n

ana@vm:~/site$ git commit -qm "fix(home): say which days we open"
ana@vm:~/site$ git status --short
 M menu.html
```

Each block is a **hunk**, lesson 3's word, and Git asks whether to stage it: `y` for yes, `n` for no.
The home page's hunk went in, the menu's did not, and after the commit `git status` still shows
`menu.html` modified, waiting for a commit of its own with its own reason. The other letters are
worth knowing too: `q` stops, `a` stages the rest of the file, and `?` explains every one of them.

When two changes are in the same file, far enough apart, they are separate hunks and `add -p` picks
between them exactly the same way. This is the tool lesson 2 promised for the typo fix sitting in the
same file as an unfinished paragraph. When they are on neighbouring lines, Git offers them as one
hunk, and then it is quicker to commit them separately by editing in two steps.

## Why it matters beyond the message

- **Reverting is precise.** Lesson 4's `git revert` undoes a whole commit. If the price rise and the
  opening days are one commit, undoing the price undoes the days too.
- **Review is easier.** A pull request of five commits, each one change with its own message, can be
  read commit by commit.
- **`git blame` and `git log -S` land on something meaningful**, instead of a commit whose message
  explains a different line.

It is not a rule about size. A one-line typo fix and a two-hundred-line new page can both be one
change. The question is whether the commit's message can honestly say *this* and nothing else.
