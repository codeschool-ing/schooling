---
title: From a branch to a pull request
version: 1
---

## Start from the newest main

The branch starts from `main`, and it should be **today's** `main`, not the one on Ana's laptop from last
week. So the first two commands are always the same:

```
ana@vm:~/site$ git switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
ana@vm:~/site$ git pull
remote: Enumerating objects: 1, done.
remote: Counting objects: 100% (1/1), done.
remote: Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (1/1), 239 bytes | 239.00 KiB/s, done.
From /home/ana/remotes/site
   6555c9b..3b844fa  main       -> origin/main
Updating 6555c9b..3b844fa
Fast-forward
 menu.html | 1 +
 1 file changed, 1 insertion(+)
ana@vm:~/site$ git switch -c 23-holiday-notice
Switched to a new branch '23-holiday-notice'
```

Look at the second line. `Your branch is up to date with 'origin/main'`, and one command later `git pull`
brings in a commit Ana did not have: Bruno's rye bread, merged yesterday. The message is only as fresh as
the last time Git asked the server, which is lesson 7's point about `fetch`. Starting from a stale `main`
costs nothing at first, and then turns into conflicts that were never necessary.

**The branch's name starts with the ticket's number.** `23-holiday-notice` says which ticket this is and,
in two words, what it is about. Some teams add a prefix such as `fix/` or their initials; what matters is
that everybody does the same thing, and lesson 9 said where to write that down.

## Commit, and point back

Ana makes the change in two commits, and each message ends with a line saying which ticket it is for:

```
ana@vm:~/site$ git log --oneline main..
9376574 Make the holiday notice stand out
0b46e2a Say the bakery closes on public holidays
ana@vm:~/site$ git push -u origin 23-holiday-notice
Enumerating objects: 10, done.
Counting objects: 100% (10/10), done.
Delta compression using up to 4 threads
Compressing objects: 100% (7/7), done.
Writing objects: 100% (7/7), 825 bytes | 825.00 KiB/s, done.
Total 7 (delta 1), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      23-holiday-notice -> 23-holiday-notice
branch '23-holiday-notice' set up to track 'origin/23-holiday-notice'.
```

`git log main..` lists the commits on this branch that `main` does not have yet, which is exactly what the pull
request will contain. `Refs #23` in the body turns into a link on the hosting site, and the ticket's page
then lists both commits. `Refs` is a convention, not a keyword: it links without closing anything.

## Open the pull request

The pull request is where the ticket meets the code. Its title says what it does; its description says
what a reviewer needs to know before reading the diff:

> **Say the bakery closes on public holidays**
>
> Closes #23
>
> Adds a notice under the opening hours, in bold so it stands out.
> To check: open index.html; the notice is the last line.

Two details carry weight here. **`Closes #23`** is a keyword this time: when the pull request is merged, the
hosting service closes ticket 23 by itself. And the pull request got number 24, not 1: GitHub and GitLab
number tickets and pull requests from one shared counter, so `#24` is unambiguous anywhere in the project.

If you want early eyes on work that is not finished, open it as a **draft**: it runs the checks and
accepts comments but cannot be merged until you say it is ready.
