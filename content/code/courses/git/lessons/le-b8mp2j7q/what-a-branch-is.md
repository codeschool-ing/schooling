---
title: What a branch is: a name for a commit
version: 1
---

**The usual picture of a branch is a copy of the project**, a parallel folder where you can work
without disturbing the original. That picture predicts that making a branch takes a while, uses
space, and duplicates the files. None of that happens:

```
ana@vm:~/site$ git branch
* main
ana@vm:~/site$ cat .git/HEAD
ref: refs/heads/main
ana@vm:~/site$ cat .git/refs/heads/main
6555c9b314e48ad30e5c97a2ec1c8657347caa91
ana@vm:~/site$ git branch opening-hours
ana@vm:~/site$ git branch
* main
  opening-hours
ana@vm:~/site$ cat .git/refs/heads/opening-hours
6555c9b314e48ad30e5c97a2ec1c8657347caa91
```

`git branch` lists the branches and stars the one you are on. There is one, `main`, and the file
behind it holds forty characters: **the id of the commit the branch points at**, `6555c9b`, the
newest commit of lesson 3's week. `git branch opening-hours` made a second branch, and its file holds
the same forty characters. That is the whole of it. A branch is a name for one commit, kept in a file
of 41 bytes.

## HEAD is how Git knows where you are

The other file, `.git/HEAD`, does not hold a commit id. It says `ref: refs/heads/main`: **you are on
`main`**. That is what `HEAD` has meant in every command so far. It names the branch you are on, and
through the branch, a commit.

That indirection is what makes a branch move. **When you commit, Git makes the new commit and moves
the branch that `HEAD` names onto it.** Every other branch stays exactly where it was. Two branches
made from the same commit look identical until the first commit on either of them, and then they
simply point at different places.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Three commits in a line. The branch main points at the middle one, 6555c9b. The branch opening-hours points at the newest, 9677eef, which was made on it. HEAD points at opening-hours, which is how Git knows which branch the next commit moves.\"><defs><marker id=\"bp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M289 130 L153 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bp-ah)\"></path><path d=\"M449 130 L313 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bp-ah)\"></path><circle cx=\"140\" cy=\"130\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"140\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eadf998</text><circle cx=\"300\" cy=\"130\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"300\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6555c9b</text><circle cx=\"460\" cy=\"130\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"460\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9677eef</text><rect x=\"277.0\" y=\"80\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M300 100 L300 118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"401.0\" y=\"80\" width=\"118\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">opening-hours</text><path d=\"M460 100 L460 118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"425\" y=\"22\" width=\"70\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HEAD</text><path d=\"M460 42 L460 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bp-ah)\"></path><text x=\"505\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HEAD names the branch you are on</text><text x=\"40\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a branch is a name</text><text x=\"40\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">for one commit</text></svg>", "caption": "Nothing is copied when a branch is made. A branch is a pointer, and a commit moves the pointer HEAD names."}
```

## Why this matters for how you work

Because a branch costs nothing, it is used for everything. The habit on most teams is **one branch
per piece of work**: the Sunday opening hours on one, the new prices on another, an experiment with
colours on a third. Each can be committed to, left half-finished, and returned to, without the other
two noticing. `main` holds only what is finished, and work joins it by merging, which is the third
section of this lesson.

The names are free text. `opening-hours` and `menu-prices` say what the work is; lesson 12 shows the
convention of putting the ticket's number in the name as well, so a branch can be traced back to why
it exists.
