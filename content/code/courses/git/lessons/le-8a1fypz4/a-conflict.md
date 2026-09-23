---
title: When both sides changed the same lines
version: 1
---

Lesson 5 merged two branches that had changed different files, and Git combined them without asking.
Here Ana's branch `sunday` and Bruno's commit on `main` both changed the second line of `index.html`:

```
ana@vm:~/site$ git merge sunday
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.
ana@vm:~/site$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   index.html

no changes added to commit (use "git add" and/or "git commit -a")
```

**`CONFLICT (content)` means Git combined everything it could and stopped at one place it could not.**
No commit was made. The merge is paused, and `git status` says so in its own words: *you have unmerged
paths*, and `index.html` is *both modified*. It also names the two ways forward, which are the two
sections that follow: fix the conflicts and commit, or abort.

A conflict is not an error, and it is not a sign that anybody did something wrong. It means two
people made different decisions about the same thing, and **Git refuses to pick one for you.** Half
past five or half past six is a fact about the bakery, and only somebody who knows the bakery can
answer it.

## Reading the markers

Git wrote both versions into the file, fenced by three kinds of marker:

```schooling-example
{"language": "html", "file": "index.html", "parts": [{"code": "<h1>Padaria Sol</h1>", "note": "Outside the markers, nothing is in dispute: both sides agree on this line."}, {"code": "<<<<<<< HEAD\n<p>Bread from half past six.</p>", "note": "From here to the equals signs is the branch you are on, main, which HEAD names: Bruno's winter hours."}, {"code": "=======\n<p>Bread from half past five; Sundays from seven.</p>\n>>>>>>> sunday", "note": "From the equals signs to the arrows is the branch being merged in, which the last line names: Ana's Sunday hours."}, {"code": "<p><a href=\"menu.html\">See the menu</a></p>", "note": "Outside again. Git merged everything it could and marked only the one line it could not decide."}]}
```

Everything between `<<<<<<<` and `=======` is **your side**, the branch you were on when you typed
`git merge`. Everything between `=======` and `>>>>>>>` is **their side**, the branch being merged in,
named on the last marker. The lines outside the markers were merged without trouble.

**The file as it stands is not valid for anything.** A browser would show the markers as text, a
program would not run, and a commit would record the markers as if they were content. The next
section is how to turn it into the one version you actually want.

## Why it happened here and not in lesson 5

Git merges by comparing each side with the commit they both grew from. Where only one side changed
something, it takes that side. Where both changed **different** lines, it takes both. Only where both
changed **the same** lines, or lines right next to each other, does it need a decision. The more often
branches are merged, the fewer of those there are, which is one of the arguments of lesson 9.
