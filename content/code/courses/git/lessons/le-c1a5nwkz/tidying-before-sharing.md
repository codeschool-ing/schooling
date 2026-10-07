---
title: Tidying commits before anybody sees them
version: 2
---

Work does not arrive in tidy commits. You commit a feature, then a stylesheet change, then notice the
feature's text is missing an exclamation mark. The honest history is three commits, one of which fixes
the first. **Before the branch is shared, you can make it the history you would have written if you had
got it right the first time.** Lesson 4's `--amend` does this for the last commit. For an older one,
here are the feature, the stylesheet, and the missing mark, not yet committed:

```bash
printf '<p>Seasonal cakes: ask at the counter.</p>\n' >> menu.html
git commit -qam 'feat(menu): mention seasonal cakes'
printf 'h1 { color: darkorange; }\np { line-height: 1.5; }\n' > style.css
git commit -qam 'style: give paragraphs more room'
sed -i 's/ask at the counter/ask at the counter!/' menu.html
```


```
ana@vm:~/site$ git commit -qa --fixup HEAD~1
ana@vm:~/site$ git log --oneline -3
d33e297 fixup! feat(menu): mention seasonal cakes
e7080e4 style: give paragraphs more room
2428cdb feat(menu): mention seasonal cakes
ana@vm:~/site$ git rebase -q -i --autosquash HEAD~3
ana@vm:~/site$ git log --oneline -2
9387491 style: give paragraphs more room
9dbb545 feat(menu): mention seasonal cakes
```

`git commit --fixup HEAD~1` made a commit whose message is `fixup! ` followed by the message of the
commit it corrects. Nothing else about it is special; it is a note to your future self saying *this
belongs with that one*.

`git rebase -i --autosquash` then does the tidying. `-i` is an **interactive rebase**, which replays
commits the way lesson 6 described but lets you reorder, combine or reword them on the way, from a
plan Git writes into your editor. `--autosquash` fills the plan in for you: it moves every `fixup!`
commit to just after the commit it names and folds it in. Here the plan was accepted unchanged,
which in your editor means saving it as it is and closing, and the result is two commits: the
seasonal cakes with the exclamation mark included, and the stylesheet change. **The fix no longer
exists as a separate commit**, because it never should have needed to.

## The rule, one more time

Every command in this section **rewrites commits**, which gives them new ids: compare the ids before and
after. That makes it lesson 6's rule again, the same one lesson 4 gave for `reset`: **only before the
commits are shared.** Tidy your branch, then push it and open the pull request. Once a reviewer has
seen the commits, add new ones for what the review asks, and let the merge button of lesson 8 decide
what `main` ends up with.

## What tidy means

The aim is not a history with no mistakes. It is a history where **each commit is one change with a
message that explains it**, which is what makes the last three sections worth anything: a reviewer can
read it, a revert can target it, and `git blame` lands on a reason. Commits that exist only because the
first try missed something add nothing to that, and folding them in before you share is a courtesy to
everybody who reads the branch after you.
