---
title: Reading the change
version: 1
---

Bruno's pull request is #31, for ticket #30: *customers want to choose when to pick up their order*. The
hosting site shows the diff, and for a small change that is enough. For anything you want to **run**, bring
the branch to your own machine:

```
ana@vm:~/site$ git fetch
remote: Enumerating objects: 10, done.
remote: Counting objects: 100% (10/10), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 7 (delta 2), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (7/7), 794 bytes | 794.00 KiB/s, done.
From /home/ana/remotes/site
 * [new branch]      30-pickup-times -> origin/30-pickup-times
ana@vm:~/site$ git switch 30-pickup-times
Switched to a new branch '30-pickup-times'
branch '30-pickup-times' set up to track 'origin/30-pickup-times'.
ana@vm:~/site$ git log --oneline main..
8b19b3c Style the order form
4156a0f Let customers choose a pickup time
```

`git switch` finds `origin/30-pickup-times` and makes a local branch that tracks it, which lesson 7
showed. The two commits are the whole pull request. Before reading any line, get the shape:

```
ana@vm:~/site$ git diff --stat main...
 index.html | 1 +
 order.html | 5 +++++
 style.css  | 3 ++-
 3 files changed, 8 insertions(+), 1 deletion(-)
```

Three files and eight lines. That already says something: a ticket about ordering touched `style.css`,
and only by a few lines. Now the lines themselves:

```
ana@vm:~/site$ git diff main...
diff --git a/index.html b/index.html
index f1e3c9f..40fee17 100644
--- a/index.html
+++ b/index.html
@@ -1,3 +1,4 @@
 <h1>Padaria Sol</h1>
 <p>Bread from half past five.</p>
 <p><a href="menu.html">See the menu</a></p>
+<p><a href="order.html">Order ahead</a></p>
diff --git a/order.html b/order.html
new file mode 100644
index 0000000..49c300b
--- /dev/null
+++ b/order.html
@@ -0,0 +1,5 @@
+<h1>Order ahead</h1>
+<form class="order">
+  <label>Pickup time <input name="pickup" type="time"></label>
+  <button>Order</button>
+</form>
diff --git a/style.css b/style.css
index 773418d..3b5e278 100644
--- a/style.css
+++ b/style.css
@@ -1 +1,2 @@
-h1 { color: darkorange; }
+h1 { color: saddlebrown; }
+.order label { display: block; }
```

Walk it with the four questions:

1. **Does it do what the ticket asked?** Yes: a page with a time field, linked from the home page.
2. **Does it work?** Open `order.html` in a browser and press *Order* with the field empty. It submits.
   Nothing stops a customer ordering for no time at all, or for three in the morning. That is the important
   finding, and reading alone might have missed it; running it made it obvious.
3. **Can the next person understand it?** It is five lines, and yes.
4. **Is it consistent?** The heading colour changed from `darkorange` to `saddlebrown` on every page of the
   site. That has nothing to do with ticket #30.

`main...` with three dots compares the branch with **the point where it left `main`**, so it shows only
Bruno's work even if `main` has moved on since. With two dots it would also show, reversed, whatever
landed on `main` in the meantime.

## When the change is too big to review

A pull request of two thousand lines cannot be read with the attention these four questions need, and
everybody knows it gets approved anyway. It is fair, and useful, to say so: ask whether it can be split, or
ask the author for a short walk through it. A review that pretends to have read something it skimmed is
worse than one that says it could not.
