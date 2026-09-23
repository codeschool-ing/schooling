---
title: Fetch and pull: nothing happens on its own
version: 1
---

Bruno changes a price and pushes it:

```
ana@vm:~/bruno/site$ git commit -qam "Charge 2.60 for cheese rolls"
ana@vm:~/bruno/site$ git push
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 347 bytes | 347.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
   6555c9b..eab2026  main -> main
```

`6555c9b..eab2026  main -> main`: `origin`'s `main` moved from the old commit to Bruno's new one. Now
Ana, in her own copy, asks where she stands:

```
ana@vm:~/site$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

**Up to date, says Git, and it is wrong.** Not broken: it answered a different question from the one
it seems to answer. `git status` compared Ana's `main` with `origin/main` — her bookmark of where
`origin` was the last time she talked to it. Nobody told her copy about Bruno's push, because
**Git never contacts a remote unless you run a command that does.** No background checks, no
notifications.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Your repository holds two names: main, your branch, and origin/main, your record of where the shared repository&#x27;s main was the last time you asked. The shared repository, origin, holds its own main. git fetch copies new commits from origin and moves origin/main. git pull does that and then brings origin/main into main. git push sends main to origin and moves both.\"><defs><marker id=\"rm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"300\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"170\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">your repository</text><rect x=\"50\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><rect x=\"180\" y=\"70\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">origin/main</text><text x=\"240\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your record of where</text><text x=\"240\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">origin&#x27;s main was</text><rect x=\"440\" y=\"30\" width=\"260\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"570\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">origin — the shared repository</text><rect x=\"515\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><path d=\"M513 80 C420 70 380 70 302 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rm-ah)\"></path><text x=\"408\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fetch</text><path d=\"M178 92 L162 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rm-ah)\"></path><path d=\"M105 102 L105 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M105 150 C105 196 570 196 570 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M570 150 L570 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rm-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"338\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">push</text><text x=\"20\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">git fetch updates the record</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">git pull = fetch, then bring it into main</text><text x=\"380\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">git push sends main, and updates both</text></svg>", "caption": "origin/main is a bookmark, updated only when you talk to the shared repository. Between those moments it can be wrong, and git status believes it."}
```

## Fetch: ask, and change nothing of yours

```
ana@vm:~/site$ git fetch
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), 327 bytes | 327.00 KiB/s, done.
From /home/ana/remotes/site
   6555c9b..eab2026  main       -> origin/main
ana@vm:~/site$ git status
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
ana@vm:~/site$ git log --oneline --all -3
eab2026 Charge 2.60 for cheese rolls
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
```

`git fetch` copied Bruno's commit into Ana's repository and moved her bookmark: `6555c9b..eab2026
main -> origin/main`. **Her own `main` did not move, and no file changed.** Now `git status` tells the
truth: *behind 'origin/main' by 1 commit, and can be fast-forwarded*. The log with `--all` shows the
bookmark one commit ahead of her branch.

That makes fetch the safe way to look. It is always harmless, and it answers *what have the others
done?* without touching anything you are working on.

## Pull: fetch, then bring it in

```
ana@vm:~/site$ git pull
Updating 6555c9b..eab2026
Fast-forward
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

**`git pull` is `git fetch` followed by bringing `origin/main` into `main`.** Here that is the
fast-forward of lesson 5, because Ana had nothing new of her own: her `main` simply slid forward to
Bruno's commit. When both of them have new commits, pull has more to decide, and the next section is
what happens then.

A habit worth taking from this: **fetch or pull before you start work, and before you push.** The
further your copy drifts from the shared one, the larger the eventual reconciliation.
