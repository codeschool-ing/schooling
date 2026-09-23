---
title: The merge button, which is three buttons
version: 1
---

When a pull request is approved, somebody merges it, and most services offer three ways. They are
three different histories, and each one is something you already know how to do with Git. Here each
is done locally, on a throwaway branch standing in for `main`, which is why Git's messages say
`try-merge` where the website would say `main`.

## Create a merge commit

```
ana@vm:~/site$ git switch -q -c try-merge main
ana@vm:~/site$ git merge --no-ff --no-edit sunday-hours
Merge made by the 'ort' strategy.
 index.html | 2 +-
 menu.html  | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline --graph -6
*   ce087cd Merge branch 'sunday-hours' into try-merge
|\  
| * 77b6507 Mention Sundays on the menu page
| * 4bda868 Write the Sunday time the way the rest of the page does
| * b63efb6 Add Sunday hours to the home page
* | bc108bd Give paragraphs more room
|/  
* 6555c9b Link the menu from the home page
```

`--no-ff` refuses the fast-forward, so there is always a merge commit, even when one was not needed.
**The branch's three commits stay visible as a unit**, side by side with Bruno's, and the merge commit
says where they joined. On a website its message would name the pull request.

## Squash and merge

```
ana@vm:~/site$ git switch -q -c try-squash main
ana@vm:~/site$ git merge --squash sunday-hours
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
ana@vm:~/site$ git commit -qm "Add Sunday hours (#12)"
ana@vm:~/site$ git log --oneline --graph -3
* 9388f37 Add Sunday hours (#12)
* bc108bd Give paragraphs more room
* 6555c9b Link the menu from the home page
```

**`--squash` takes all of the branch's changes and stages them as one change**, without committing and
without recording that a branch was merged. The commit that follows is a single ordinary commit with
the pull request's number in its message. Three commits, including one that fixed a typo in another,
became one line of history.

## Rebase and merge

```
ana@vm:~/site$ git switch -q -c try-rebase sunday-hours
ana@vm:~/site$ git rebase -q main
ana@vm:~/site$ git log --oneline --graph -5
* 64bff07 Mention Sundays on the menu page
* e70f06e Write the Sunday time the way the rest of the page does
* 6e20cd0 Add Sunday hours to the home page
* bc108bd Give paragraphs more room
* 6555c9b Link the menu from the home page
```

The branch's commits, **replayed on top of `main`** as lesson 6 described, and then `main` is
fast-forwarded to them. Three commits, a straight line, new ids.

## Which one

| button | the history | good for |
|---|---|---|
| merge commit | every commit, plus a join | seeing exactly how work happened |
| squash | one commit per pull request | a short main where each line is one change |
| rebase | every commit, in a line | keeping small commits without the joins |

Teams choose one and usually lock the others off in the repository's settings. **Squash is common** on
teams where branch commits are messy — *fix typo*, *oops* — because none of that reaches `main`. Its
cost is that the individual commits are gone from `main`'s history, so a pull request that did three
things becomes one commit that is harder to revert in part. Lesson 11 makes the argument for commits
that are worth keeping.

After the merge, the service offers to **delete the branch**, which is lesson 7's
`git push origin --delete`. Take it: the commits are in `main` now, and the branch name is only
clutter.
