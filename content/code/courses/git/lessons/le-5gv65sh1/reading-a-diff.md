---
title: Reading a diff
version: 1
---

A diff is how Git answers *what changed*. Lesson 1 said a commit stores a snapshot and not a list of
changes; **a diff is computed when you ask, by comparing two snapshots**, and the only thing to decide
is which two.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"Four boxes in a row: an older commit, the last commit, the staging area and the working tree. Below them, three brackets show what each diff compares: git diff compares the staging area with the working tree, git diff --staged compares the last commit with the staging area, and git diff with two commits compares any two commits.\"><defs><marker id=\"df-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"97.5\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">an older commit</text><text x=\"97.5\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">HEAD~3</text><rect x=\"195\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272.5\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the last commit</text><text x=\"272.5\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">HEAD</text><rect x=\"370\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.5\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">staging area</text><rect x=\"545\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622.5\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">working tree</text><path d=\"M447 92 L447 112 L622 112 L622 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"534.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git diff</text><path d=\"M272 92 L272 150 L447 150 L447 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"359.5\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git diff --staged</text><path d=\"M97 92 L97 188 L272 188 L272 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"184.5\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git diff HEAD~3 HEAD</text></svg>", "caption": "Every diff compares exactly two snapshots. Which two is decided by what you type after git diff."}
```

## One change, line by line

Here the price of the cheese roll has been edited and not yet staged, so plain `git diff` shows it:

```
ana@vm:~/site$ git diff
diff --git a/menu.html b/menu.html
index ee9e6e3..28fc426 100644
--- a/menu.html
+++ b/menu.html
@@ -1,3 +1,3 @@
 <h1>Menu</h1>
 <p>French bread, 0.90</p>
-<p>Cheese roll, 2.50</p>
+<p>Cheese roll, 2.80</p>
```

The first four lines are a header. `diff --git a/menu.html b/menu.html` names the file on both
sides: `a` is the old side and `b` the new one. The `index` line gives the two versions' blob ids,
the same ids lesson 1 found in a tree. `---` and `+++` repeat which side is which.

Then comes the part that matters, the **hunk**. `@@ -1,3 +1,3 @@` means *from line 1, three lines,
in the old file; from line 1, three lines, in the new one*. Below it, every line starts with one of
three characters:

- a space is **context**, unchanged, shown so you can see where you are;
- `-` is a line that exists only on the old side;
- `+` is a line that exists only on the new side.

**Diffs have no idea of "changed".** A changed line is shown as the old one removed and the new one
added, `-…2.50` and `+…2.80`. A long file changed in three places gives three hunks, each with a
few lines of context around it.

## Between two commits

Name two commits and Git compares those snapshots. Adding `-- menu.html` limits it to one file:

```
ana@vm:~/site$ git diff HEAD~3 HEAD -- menu.html
diff --git a/menu.html b/menu.html
index ca66507..ee9e6e3 100644
--- a/menu.html
+++ b/menu.html
@@ -1,3 +1,3 @@
 <h1>Menu</h1>
 <p>French bread, 0.90</p>
-<p>Rye bread, 1.35</p>
+<p>Cheese roll, 2.50</p>
```

Look at what it says and what it does not. Three commits separate `HEAD~3` from `HEAD`: rye bread
removed, cheese rolls added, a link on the home page. **The diff shows the difference between the two
ends, not the steps between them.** Rye went and cheese came, and the diff shows exactly that, with
no sign that they were separate commits by different people on different days. When you want the
steps, you want the log.

`--stat` gives the same comparison as a summary, which is often enough to know whether to look
closer:

```
ana@vm:~/site$ git diff --stat HEAD~3 HEAD
 index.html | 1 +
 menu.html  | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
```
