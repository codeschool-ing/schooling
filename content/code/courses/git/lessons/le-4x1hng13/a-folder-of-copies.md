---
title: The folder everybody starts with
version: 1
---

Everybody has version control before they have heard the word. It is a folder, and it looks like
this:

```
ana@vm:~/report$ ls -l
total 20
-rw-r--r-- 1 ana ana 109 Sep  9 08:47 report-FINAL.txt
-rw-r--r-- 1 ana ana 115 Sep  8 15:22 report-v2-final-bruno.txt
-rw-r--r-- 1 ana ana 109 Sep  8 11:05 report-v2-final.txt
-rw-r--r-- 1 ana ana  93 Sep  3 17:40 report-v2.txt
-rw-r--r-- 1 ana ana  93 Sep  1 09:12 report.txt
```

Five copies of one report, written over nine days by two people. Nobody planned it. Ana saved a
copy before a risky edit, then another before sending it to Bruno, then Bruno sent one back with
his name on it, and then somebody decided this one was final.

**The common picture is that version control is this folder done tidily** — copies with better
names, kept somewhere safe. It is not, and the folder is the best way to see why. Copies keep old
versions. What they lose is everything *about* the versions, and that turns out to be the part a
team needs.

## What the folder cannot tell you

Try to answer five questions from that listing.

**Which one is current?** `report-FINAL.txt` is the newest, so probably that one. But Bruno's copy
is from the day before and has changes of its own. Is FINAL the version that includes them?

**What changed?** You can find out, if you have both copies and know which two to compare:

```
ana@vm:~/report$ diff report-v2-final.txt report-FINAL.txt
2c2
< Sales rose 6% against the last quarter.
---
> Sales rose 5% against the last quarter.
```

**Why did it change?** Somebody turned 6% into 5%. Was 6% a typo, or did finance send a new figure,
or is FINAL the copy that is wrong? The file does not say, and in a month nobody will remember.

**Who changed it?** The owner column says `ana` for all five, because they are all on Ana's
machine. Bruno's name is on one of them only because he typed it into the filename.

**What changed together?** A report is one file. A website is forty, and a change to one page is
often a change to the stylesheet and the menu as well. Copying one file keeps one file. It does not
keep **the state of the whole project at a moment**, which is what you need when you want to go
back to "the version that worked on Tuesday".

## Two people make it worse

Compare Bruno's copy with the one he started from:

```
ana@vm:~/report$ diff report-v2-final.txt report-v2-final-bruno.txt
3c3
< The north region missed its target.
---
> The north region missed its target by 2%.
```

Now look at the two diffs together. FINAL changed line 2 and Bruno changed line 3. **Neither copy
has both changes.** Whoever sends FINAL to the board sends it without Bruno's figure, and nothing in
the folder warns them. Every name in that listing was chosen by somebody who believed it was clear.

This is the problem version control exists for. A backup answers *"can I get the old one back?"*
Version control answers the five questions above, for every file at once, and it can tell when two
people changed the same thing at the same time. The next section is what it keeps in order to do
that.
