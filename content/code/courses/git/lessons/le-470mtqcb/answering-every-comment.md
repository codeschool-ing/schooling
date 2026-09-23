---
title: Answering every comment
version: 1
---

**Every comment gets an answer**, even if the answer is one word. A reviewer who comes back to four comments
and finds two replies does not know whether the other two were done, missed or ignored.

## The blocking one: fix it

Bruno fixes the empty field, and while he is in that line he answers the question too: the opening hours go
into the input as `min` and `max`:

```
bruno@vm:~/site$ git diff
diff --git a/order.html b/order.html
index 49c300b..3a0bdcf 100644
--- a/order.html
+++ b/order.html
@@ -1,5 +1,5 @@
 <h1>Order ahead</h1>
 <form class="order">
-  <label>Pickup time <input name="pickup" type="time"></label>
+  <label>Pickup time <input name="pickup" type="time" min="06:00" max="19:00" required></label>
   <button>Order</button>
 </form>
bruno@vm:~/site$ git commit -qam 'Require a pickup time within opening hours' -m 'Refs #30'
```

**The fix is a new commit on the same branch.** Lesson 11 said why not to rewrite commits somebody has
already reviewed: Ana would have to read all of them again to find what changed. As a new commit, "what
changed since I looked" is exactly one commit. Many teams squash when merging anyway (lesson 8), so the extra
commits never reach `main` as clutter.

## The out-of-scope one: move it

The colour change comes out of this branch, again as a new commit, and leaves `style.css` with only the rule
the form needs:

```
bruno@vm:~/site$ git commit -qam 'Leave the heading colour for its own pull request' -m 'Refs #30'
bruno@vm:~/site$ git diff main... -- style.css
diff --git a/style.css b/style.css
index 773418d..588dd5d 100644
--- a/style.css
+++ b/style.css
@@ -1 +1,2 @@
 h1 { color: darkorange; }
+.order label { display: block; }
```

Then everything goes up at once:

```
bruno@vm:~/site$ git log --oneline main..
809c6c8 Leave the heading colour for its own pull request
2ff9efa Require a pickup time within opening hours
8b19b3c Style the order form
4156a0f Let customers choose a pickup time
bruno@vm:~/site$ git push
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 4 threads
Compressing objects: 100% (6/6), done.
Writing objects: 100% (6/6), 719 bytes | 719.00 KiB/s, done.
Total 6 (delta 2), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
   8b19b3c..809c6c8  30-pickup-times -> 30-pickup-times
```

The server here is the folder from lesson 7, standing in for GitHub. The pull request now shows four commits,
and a reviewer can look at the last two alone. The colour idea is not lost: it gets its own ticket, #32, and its
own branch, started from `main` so it carries nothing of #31:

```
bruno@vm:~/site$ git switch -c 32-heading-colour main
Switched to a new branch '32-heading-colour'
bruno@vm:~/site$ git commit -qam 'Darken the heading colour' -m 'Refs #32'
bruno@vm:~/site$ git push -u origin 32-heading-colour
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 294 bytes | 294.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      32-heading-colour -> 32-heading-colour
branch '32-heading-colour' set up to track 'origin/32-heading-colour'.
```

It became pull request #33, and it will be reviewed, and merged or not, on its own merits.

## The replies

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The round trip of pull request 31 between two lanes, Bruno above and Ana below. On 24 September Bruno opens 31 with two commits, and Ana reviews it with four comments. On 25 September Bruno answers all four and pushes two commits; Ana re-reads and approves; Bruno merges, and 31 closes ticket 30.\"><defs><marker id=\"rd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Bruno</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><path d=\"M70 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M70 170 L700 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"84\" y=\"48\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">opens #31</text><text x=\"140\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">two commits</text><path d=\"M180 92 L225 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"209\" y=\"148\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">reviews</text><text x=\"265\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 comments</text><path d=\"M305 148 L350 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"334\" y=\"48\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">answers all 4</text><text x=\"390\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pushes 2 commits</text><path d=\"M430 92 L475 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"459\" y=\"148\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"515\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">re-reads</text><text x=\"515\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">approves</text><path d=\"M555 148 L600 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"584\" y=\"48\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">merges</text><text x=\"640\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">#31 closes #30</text><path d=\"M327 26 L327 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"320\" y=\"30\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24 September</text><text x=\"334\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">25 September</text></svg>", "caption": "One round of comments and one of answers. Every comment got a reply, and nothing was rewritten: the fixes are new commits."}
```

Bruno's four replies, one on each thread:

- *"Fixed in 2ff9efa, thanks, good catch."*
- *"Good question: now limited to 06:00–19:00 in the same commit."*
- *"I kept Order so it matches the heading, Order ahead. Happy to change it if you feel strongly."*
- *"Moved to #33."*

Each one points at what changed, and the third one declines a nit with a reason, which is exactly what a nit
allows. Some teams let the author press *Resolve conversation* after answering; others leave that to the
reviewer, who knows whether the answer satisfied them. Either works if everybody does the same.
