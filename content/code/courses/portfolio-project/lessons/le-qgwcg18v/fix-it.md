---
title: Fixing what you found
version: 1
---

What a self-review finds is fixed on the same branch, before anybody else sees it, and lesson 9's tools
keep the history clean while you do it. The two slips were removed and the correction folded into the
commit it corrects:

```
ana@laptop:~/loanbook$ git commit -q -a --fixup HEAD
ana@laptop:~/loanbook$ GIT_SEQUENCE_EDITOR=true git rebase -q -i --autosquash main
ana@laptop:~/loanbook$ git diff main... | grep -cE '^\+.*(console\.log|TODO|print\(|debugger)'
0
ana@laptop:~/loanbook$ git log --oneline main..
58c3a3f Say what to do when there is nothing to lend
```

`grep -c` counts the matching lines, and the answer is now `0`. The branch holds one commit, whose
diff is the empty state and nothing else. Nobody reading the pull request will know there was a
`console.log`, and nobody needs to.

The injection problem is different, and the difference matters. It is **not a slip in this change**:
it was already in the code this change touched. The honest move is not to widen this pull request
into a rewrite of the page, but to **open a card for it**, lesson 8, and fix it in its own change,
where a reviewer can see it as the decision it is. A pull request that quietly fixes three unrelated
things is harder to review than three that each fix one.

Two tests of a self-review being finished. **You would be comfortable if the diff were printed and
pinned to a wall with your name on it.** And **you can say in one sentence what the change does**,
which is also its subject line.
