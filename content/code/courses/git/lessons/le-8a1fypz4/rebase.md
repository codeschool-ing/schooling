---
title: Rebase: replaying commits on a new base
version: 1
---

Merge joins two histories and keeps both shapes. **Rebase takes the commits of your branch and makes
them again, one by one, on top of another branch**, as if you had started your work later than you
did.

Here `cheese` grew from an older `main`, and `main` has moved on since:

```
ana@vm:~/site$ git switch cheese
Switched to branch 'cheese'
ana@vm:~/site$ git log --oneline --graph --all -4
* 3a0003a Give paragraphs more room
| * 788a11d Charge 2.60 for cheese rolls
|/  
*   56eb01e Merge branch 'sunday'
|\  
| * 9677eef Open on Sundays from seven
```

The same fork lesson 5 merged. This time, on `cheese`:

```
ana@vm:~/site$ git rebase main
Successfully rebased and updated refs/heads/cheese.
ana@vm:~/site$ git log --oneline --graph --all -4
* 6e29a2d Charge 2.60 for cheese rolls
* 3a0003a Give paragraphs more room
*   56eb01e Merge branch 'sunday'
|\  
| * 9677eef Open on Sundays from seven
```

The fork is gone. `Charge 2.60 for cheese rolls` now sits directly on top of `Give paragraphs more
room`, in one straight line. And look at its id: **`788a11d` became `6e29a2d`.** Same change, same
message, same author, but a different parent, and lesson 1 said a different parent means a different
id. Rebase did not move the commit. It made a new one and moved the branch to it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Before: main has moved on to 3a0003a, and the branch cheese holds one commit, 788a11d, that grew from the older 56eb01e. After rebasing cheese onto main, the same change is a new commit, 6e29a2d, whose parent is 3a0003a; the old commit 788a11d is left behind on no branch.\"><defs><marker id=\"rb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">before: cheese grew from an older main</text><path d=\"M209 70 C150.0 70 150.0 90 93 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><path d=\"M209 120 C150.0 120 150.0 90 93 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><circle cx=\"80\" cy=\"90\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">56eb01e</text><circle cx=\"220\" cy=\"70\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3a0003a</text><circle cx=\"220\" cy=\"120\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">788a11d</text><text x=\"275\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main</text><text x=\"275\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheese</text><path d=\"M20 165 L700 165\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"192\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">after git rebase main: the same change, replayed on top</text><path d=\"M209 250 L93 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><path d=\"M349 250 L233 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><circle cx=\"80\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">56eb01e</text><circle cx=\"220\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3a0003a</text><circle cx=\"360\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6e29a2d</text><text x=\"415\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheese</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a new commit with a new id</text><circle cx=\"220\" cy=\"300\" r=\"10\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></circle><path d=\"M209 300 C150 300 150 250 93 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"240\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">788a11d · left behind, on no branch</text></svg>", "caption": "Rebase does not move commits. It makes new ones with the same changes on a new base, and moves the branch to them."}
```

## Then the merge is a fast-forward

```
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ git merge cheese
Updating 3a0003a..6e29a2d
Fast-forward
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Because `cheese` now starts where `main` ends, merging it only slides `main` forward. **No merge
commit, and a history that reads as a single line**, which is the reason people rebase: a log where
each piece of work appears in order, one after another, is easier to read than one with a fork and a
join for every branch.

## A conflict during a rebase

Rebase replays commits one at a time, so it can stop at any of them with a conflict:

```
ana@vm:~/site$ git rebase main
Auto-merging menu.html
CONFLICT (content): Merge conflict in menu.html
error: could not apply 5999428... Charge 2.70 for cheese rolls
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
Could not apply 5999428... Charge 2.70 for cheese rolls
ana@vm:~/site$ cat menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Cheese roll, 2.70</p>
ana@vm:~/site$ git add menu.html
ana@vm:~/site$ git rebase --continue
[detached HEAD 1b5684f] Charge 2.70 for cheese rolls
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/rolls.
ana@vm:~/site$ git log --oneline -3
1b5684f Charge 2.70 for cheese rolls
f30c3fb Round cheese rolls up to 2.75
6e29a2d Charge 2.60 for cheese rolls
```

The steps are the ones you already know, with one word changed: resolve the file, `git add` it, and
then **`git rebase --continue`** instead of `git commit`, so the rebase can go on to the next commit.
`git rebase --abort` is the way back, exactly like `git merge --abort`. The `[detached HEAD 1b5684f]`
line is the replayed commit being made while the rebase is still running, before the branch is moved
to it at the end.
