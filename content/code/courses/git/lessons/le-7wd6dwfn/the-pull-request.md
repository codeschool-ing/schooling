---
title: A pull request is a branch asking to join
version: 1
---

**A pull request is a request to merge one branch into another**, with a web page for discussing it
first. GitHub and Bitbucket call it a pull request; GitLab calls it a merge request, which is the more
accurate name. Nothing new is stored in Git: the branch is an ordinary branch you pushed, and the page
is the hosting service reading it.

Ana pushed `sunday-hours`, with three commits, and opened a pull request into `main`. The page has a
tab listing its commits. That tab is this:

```
ana@vm:~/site$ git log --oneline main..sunday-hours
77b6507 Mention Sundays on the menu page
4bda868 Write the Sunday time the way the rest of the page does
b63efb6 Add Sunday hours to the home page
```

**`main..sunday-hours` means the commits on `sunday-hours` that are not on `main`.** Those three are
what merging would bring in. Bruno's commit on `main` is not among them, because it is on `main`
already.

The other tab, *files changed*, is a diff. Three dots this time:

```
ana@vm:~/site$ git diff --stat main...sunday-hours
 index.html | 2 +-
 menu.html  | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```

**`main...sunday-hours` compares the branch with the commit where it left `main`**, not with `main` as
it is today. So it shows what Ana changed, and nothing about Bruno's stylesheet commit, which happened
on `main` meanwhile. That is exactly what a reviewer wants: *this* change, not the difference between
two moving targets.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Six steps from left to right: push the branch, open the pull request, checks run and people review, approved, merged into main, branch deleted. A loop returns from the review step to itself: when changes are requested, more commits are pushed to the same branch and the review starts again.\"><defs><marker id=\"pr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"8\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">push</text><text x=\"60\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the branch</text><path d=\"M113 108 L125 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"127\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">open</text><text x=\"179\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the pull request</text><path d=\"M232 108 L244 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"246\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"298\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">checks run</text><text x=\"298\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">people review</text><path d=\"M351 108 L363 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"365\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"417\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">approved</text><path d=\"M470 108 L482 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"484\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"536\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">merged</text><text x=\"536\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">into main</text><path d=\"M589 108 L601 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"603\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"655\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">branch</text><text x=\"655\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">deleted</text><path d=\"M326 78 C336 30 260 30 270 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><text x=\"298\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">changes requested: push more commits to the same branch</text></svg>", "caption": "A pull request is a conversation attached to a branch. The branch keeps moving until the conversation ends."}
```

## The branch keeps moving

A pull request is not a snapshot of the branch when it was opened. **Push another commit to the same
branch and the pull request shows it** — commits, diff and all — because the page reads the branch as
it is now. That is how review works in practice: a reviewer asks for a change, the author commits it
and pushes, and the conversation carries on in the same place.

Two more things every service has:

- **Draft** pull requests, opened early to show work in progress and get early comments, marked as not
  ready to merge.
- **Checks**, which are programs the service runs on every push to the branch: the tests, a linter, a
  build. They show as passed or failed next to the merge button, and a team can refuse to merge while
  one is red. Lesson 17 is about what they are for.
