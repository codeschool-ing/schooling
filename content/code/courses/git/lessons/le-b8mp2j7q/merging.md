---
title: Merging: fast-forward, or a commit with two parents
version: 1
---

Work on a branch is finished when it joins `main`. **`git merge name` brings the named branch into
the one you are on**, and depending on what happened on each side, it does one of two different
things.

## When main has not moved: fast-forward

Since `opening-hours` was made, nobody committed to `main`. So `main` is simply behind:

```
ana@vm:~/site$ git merge opening-hours
Updating 6555c9b..9677eef
Fast-forward
 index.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline -3
9677eef Open on Sundays from seven
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
```

`Fast-forward` means Git **moved `main` forward to the other branch's commit** and did nothing else.
No new commit was made, because none was needed: every commit on `opening-hours` already follows
`main`'s, so pointing `main` at the newest one is the whole merge. The log shows a straight line.

## When both sides moved: a merge commit

Now the ordinary case. A branch for the new price of French bread, and meanwhile a commit on `main`
about paragraph spacing:

```
ana@vm:~/site$ git switch -c menu-prices
Switched to a new branch 'menu-prices'
ana@vm:~/site$ git commit -qam "Charge 0.95 for French bread"
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ git commit -qam "Give paragraphs more room"
ana@vm:~/site$ git log --oneline --graph --all -4
* 68491c4 Give paragraphs more room
| * 59ec506 Charge 0.95 for French bread
|/  
* 9677eef Open on Sundays from seven
* 6555c9b Link the menu from the home page
```

`--graph` draws the shape the one-line log was hiding. The two commits sit side by side, each on its
own line of the drawing, and both grew from `9677eef`. **The history has forked.** No pointer can move
forward to include both, because neither contains the other.

```
ana@vm:~/site$ git merge --no-edit menu-prices
Merge made by the 'ort' strategy.
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline --graph -5
*   d340360 Merge branch 'menu-prices'
|\  
| * 59ec506 Charge 0.95 for French bread
* | 68491c4 Give paragraphs more room
|/  
* 9677eef Open on Sundays from seven
* 6555c9b Link the menu from the home page
ana@vm:~/site$ git cat-file -p HEAD
tree 8a50de9e8a8d84b76058c336a553b557e91cd480
parent 68491c428c34de228b3f8f1b1b87d0897fe28834
parent 59ec50622bb677f0ee952bbd07f001cd2c77b671
author Ana Souza <ana@example.com> 1790002800 -0300
committer Ana Souza <ana@example.com> 1790002800 -0300

Merge branch 'menu-prices'
```

**Git wrote a new commit whose job is to join the two**, `d340360`, and its `cat-file` shows what makes
it a merge: two `parent` lines, one for each side. Its tree combines both changes, the new price from
`menu-prices` and the spacing from `main`. The drawing now closes the fork again. `ort` in the first
line of the output is the name of the method Git used to combine them, and you will not need to choose
another.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Two cases. In the first, main has no commits of its own since the branch was made, so merging just moves main forward to the branch&#x27;s commit. In the second, main and menu-prices each have a new commit, so merging creates a new commit, d340360, whose two parents are the two branch tips.\"><defs><marker id=\"mg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">fast-forward: main had not moved</text><path d=\"M209 80 L93 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><circle cx=\"80\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6555c9b</text><circle cx=\"220\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9677eef</text><rect x=\"197.0\" y=\"38\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M220 58 L220 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"46\" y=\"38\" width=\"68\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"80\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main</text><path d=\"M116 48 C150 40 170 40 184 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"280\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">main slides forward; no new commit</text><path d=\"M20 130 L700 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">diverged: both sides have new commits</text><path d=\"M209 210 C150.0 210 150.0 250 93 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><path d=\"M209 290 C150.0 290 150.0 250 93 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><path d=\"M369 250 C300.0 250 300.0 210 233 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><path d=\"M369 250 C300.0 250 300.0 290 233 290\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><circle cx=\"80\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9677eef</text><circle cx=\"220\" cy=\"210\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">68491c4</text><circle cx=\"220\" cy=\"290\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">59ec506</text><circle cx=\"380\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"380\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">d340360</text><rect x=\"357.0\" y=\"204\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M380 224 L380 238\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"220\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main</text><text x=\"220\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">menu-prices</text><text x=\"430\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a merge commit with two parents</text></svg>", "caption": "Git fast-forwards when it can, and writes a merge commit when both sides moved."}
```

Git could combine these automatically because the two sides changed different files. When both
sides change the same lines, it cannot decide which is right, and stops to ask: that is a conflict,
and lesson 6 is about it.

**Which of the two you get is not your choice by default, it is the history's.** Some teams prefer a
merge commit even when a fast-forward was possible, so that every piece of work is visible as a unit
in the log; `git merge --no-ff` does that. Lesson 9 is where that preference is argued.
