---
title: A subject, a blank line, a reason
version: 1
---

A commit message has two parts, and git treats them differently. The **subject** is the first line:
it is what `git log --oneline` shows, what a pull request takes as its title, what a reviewer scans.
Then **a blank line**, and then the **body**, as long as it needs to be, for the reader who opens the
commit.

```
Refuse to lend an item that is already out

Two people could lend the same projector from two browsers, and the
list then showed it twice. A partial unique index allows one open loan
per item, so the database refuses the second one even when both
requests arrive together. The handler turns that refusal into a 409
with a sentence the page shows.

Closes #3
```

That is commit 2fb7c61, and it follows the conventions most projects use:

| part | convention | why |
|---|---|---|
| subject | about 50 characters, imperative, no full stop | it fits in every tool that shows one line |
| blank line | always | tools use it to tell the subject from the body |
| body | wrapped at about 72 columns | it reads in a terminal and in an e-mail |
| body content | **why**, and what was considered | the diff already says what |
| last line | *Closes #N* or *refs #N* | lesson 8 |

The rule that matters most is the fourth. **The diff shows what changed; only the message can say
why.** *Add unique index on loans* repeats the diff. *A partial unique index allows one open loan per
item, so the database refuses the second one even when both requests arrive together* says why it is
there and why there, and nobody reading the diff alone could reconstruct it.

Not every commit needs a body. *Fit the table on a phone* has two lines and needs no more. A body is
for the commits where a reader would otherwise ask *why?*, and those are exactly the ones a reviewer
opens.
