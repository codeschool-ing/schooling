---
title: Review, merge and release
version: 1
---

## Review is a conversation

Bruno reviews it. He asks for the notice to stand out, so Ana adds a second commit to **the same branch** and
pushes again; the pull request updates by itself, with no new one to open. Lessons 13 and 14 are about both
sides of that conversation, what to comment on and how to take a comment. For the life of the task, what
matters is that the loop can go round several times, and that each round is more commits on the branch.

When Bruno approves and the checks are green, the pull request is merged with the button, and two things
happen on the server: the merge commit lands on `main`, and ticket 23 closes. Ana's laptop knows about
neither yet:

```
ana@vm:~/site$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
ana@vm:~/site$ git pull
remote: Enumerating objects: 1, done.
remote: Counting objects: 100% (1/1), done.
remote: Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (1/1), 246 bytes | 246.00 KiB/s, done.
From /home/ana/remotes/site
   3b844fa..1a4fffb  main       -> origin/main
Updating 3b844fa..1a4fffb
Fast-forward
 index.html | 1 +
 style.css  | 1 +
 2 files changed, 2 insertions(+)
ana@vm:~/site$ git branch -d 23-holiday-notice
Deleted branch 23-holiday-notice (was 9376574).
ana@vm:~/site$ git log --oneline --graph -7
*   1a4fffb Merge pull request #24 from ana/23-holiday-notice
|\  
| * 9376574 Make the holiday notice stand out
| * 0b46e2a Say the bakery closes on public holidays
|/  
*   3b844fa Merge pull request #22 from bruno/21-rye-bread-back
|\  
| * 214a5e3 Put rye bread back on the menu
|/  
* 6555c9b Link the menu from the home page
* eadf998 Take rye bread off until the flour arrives
```

`git branch -d` deletes the branch without complaint because its commits are now in `main`; lesson 5 showed
it refusing when they are not. The graph shows the week as two short-lived branches, each merged by a pull
request whose number is in the message.

## The release

The change is merged, and the customers still see the old page, because merged is not the same as
**released**. How a release happens depends on the team: some deploy every merge automatically, the
bakery tags a version and publishes it by hand. Either way, the tag marks what went out:

```
ana@vm:~/site$ git tag -a v1.1 -m 'Holiday notice, rye bread back'
ana@vm:~/site$ git push origin v1.1
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 174 bytes | 174.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new tag]         v1.1 -> v1.1
ana@vm:~/site$ git log --oneline --no-merges v1.0..v1.1
9376574 Make the holiday notice stand out
0b46e2a Say the bakery closes on public holidays
214a5e3 Put rye bread back on the menu
```

`--no-merges v1.0..v1.1` lists the commits in `v1.1` and not in `v1.0`, leaving out the merge commits. That
is the raw material for the **release notes**, and it reads well only because each message was written for a
reader (lesson 11).

## Is it live yet?

A week later a customer asks whether the holiday notice is on the site now. The question is really *which
release contains the commit?*, and Git can answer it:

```
ana@vm:~/site$ git log --oneline --grep "#23"
9376574 Make the holiday notice stand out
0b46e2a Say the bakery closes on public holidays
ana@vm:~/site$ git tag --contains 0b46e2a
v1.1
```

The ticket's number finds the commits, and `git tag --contains` names every tag whose history includes them.
If `v1.1` is what is running, the answer is yes.

## Closed is not done

Ticket 23 closed when the pull request was merged, a day before anybody outside the team could see the
notice. Most teams treat that gap deliberately: the ticket moves to *done* only when the change is released
and somebody has looked at it where customers see it. Lesson 17 calls that the **definition of done**, and it
is the difference between "I merged it" and "it works".
