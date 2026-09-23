---
title: A history is a chain of snapshots, each with a reason
version: 1
---

Here is the same report kept by Git instead of by a folder. You will make one of these yourself in
lesson 2. For now it is enough to read one:

```
ana@vm:~/notes$ git log --oneline
d03056f Name the quarter in the title
3c94cf5 Say by how much the north missed, and add the table it comes from
084e07d Use the corrected sales figure from finance
32507e0 Start the quarterly report
```

Four lines, newest first, and each one is a **commit**: a saved state of the project with a
sentence saying why it was saved. The folder of copies had five files and no sentences. This has
one file on disk, `report.txt`, and four reasons.

## What one commit holds

Ask for the newest one in full and it shows what the short form left out:

```
ana@vm:~/notes$ git log -1
commit d03056feb82202fe7dc86cbb7dcbae7a8e7d2222
Author: Ana Souza <ana@example.com>
Date:   Wed Sep 9 08:47:00 2026 -0300

    Name the quarter in the title
```

That is four of the five questions answered in five lines. **Who** is the author, with a name and
an address. **When** is the date, down to the second and the time zone. **Why** is the message,
written by the person who made the change at the moment they made it, when they still remembered.
**Which one** is the long string after `commit`.

**The id is computed, not assigned.** Git takes everything the commit contains: the files, the
author, the date, the message and the commit before it. It runs all of that through a hash function,
which turns any amount of data into forty hexadecimal characters. Change one letter anywhere and the id comes out
completely different. So nobody hands out ids and no two people can pick the same one: the same
commit has the same id on every machine in the world. `d03056f` in the short log is just its first
seven characters, which is almost always enough to tell commits apart.

The fifth question was **what changed together**. Here is Bruno's commit, with the files it
touched:

```
ana@vm:~/notes$ git log -1 --stat HEAD~1
commit 3c94cf5b08d9dbcf6dc0253f2b0bed1af7ee86dc
Author: Bruno Lima <bruno@example.com>
Date:   Tue Sep 8 15:22:00 2026 -0300

    Say by how much the north missed, and add the table it comes from

 regions.csv | 3 +++
 report.txt  | 2 +-
 2 files changed, 4 insertions(+), 1 deletion(-)
```

The sentence in the report and the table it came from went in as **one change**. Going back to the
day before this commit takes both away, and going forward brings both back. A folder of copies
cannot even express that, because each copy is one file.

## Each commit points at the one before

This part the log does not print, and it is what makes a list of saves into a history. Git will
show the commit exactly as it stores it:

```
ana@vm:~/notes$ git cat-file -p HEAD
tree cf4340aebd7b8c9451595d3fc8df4b1d05063e99
parent 3c94cf5b08d9dbcf6dc0253f2b0bed1af7ee86dc
author Ana Souza <ana@example.com> 1788954420 -0300
committer Ana Souza <ana@example.com> 1788954420 -0300

Name the quarter in the title
```

`parent` is the id of Bruno's commit. Bruno's commit names Ana's before it, and so on back to the
first, which has no parent at all. **A history is that chain**, read backwards from the newest:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"Four commits stacked from newest at the top to oldest at the bottom. Each shows its short id, its message and its author and date. An arrow labelled parent runs from each commit down to the one before it. The oldest commit has no parent.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">newest — where the log starts</text><rect x=\"40\" y=\"40\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">d03056f</text><text x=\"118\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Name the quarter in the title</text><text x=\"118\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana Souza · Wed Sep 9 08:47</text><path d=\"M84 90 L84 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"94\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">parent</text><rect x=\"40\" y=\"120\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">3c94cf5</text><text x=\"118\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Say by how much the north missed, and add the table it comes from</text><text x=\"118\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Bruno Lima · Tue Sep 8 15:22</text><path d=\"M84 170 L84 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"94\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">parent</text><rect x=\"40\" y=\"200\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">084e07d</text><text x=\"118\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Use the corrected sales figure from finance</text><text x=\"118\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana Souza · Thu Sep 3 17:40</text><path d=\"M84 250 L84 278\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"94\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">parent</text><rect x=\"40\" y=\"280\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">32507e0</text><text x=\"118\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Start the quarterly report</text><text x=\"118\" y=\"318\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana Souza · Tue Sep 1 09:12</text><text x=\"54\" y=\"352\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no parent: the first commit</text></svg>", "caption": "The log reads the chain from the top. Each commit names the one before it, and the first names nothing."}
```

The chain is also why the ids can be trusted. Each commit's id is computed over its parent's id, so
quietly editing an old commit would change its id, which would change the id of every commit after
it. **History cannot be altered without it showing.** Lesson 4 comes back to this, because some of
the ways to undo a mistake do exactly that on purpose.

## A snapshot, not a list of changes

The first line of that output, `tree`, is the other half of the picture, and it corrects a belief
almost everybody arrives with. The belief is that a commit stores *what changed* — a diff, like the
two `diff` outputs in the last section. It stores the whole project:

```
ana@vm:~/notes$ git cat-file -p HEAD~1^{tree}
100644 blob 8ad7960399318dfee980e2f2da0b2b4c4d9b3e8f	regions.csv
100644 blob 5a9a6711826c2029248f0b77e3db30c6a919e6b5	report.txt
ana@vm:~/notes$ git cat-file -p HEAD^{tree}
100644 blob 8ad7960399318dfee980e2f2da0b2b4c4d9b3e8f	regions.csv
100644 blob 13bfa124a5e9109630313a709bc5adb19d9909da	report.txt
```

The first list is the project as Bruno left it, the second as Ana left it the next morning. Ana's
commit changed only the title of the report, and **its tree still names both files.** Every commit
is a complete picture of every file.

Look at `regions.csv` in the two lists: the same id. The file did not change, so its content hashes
to the same value, and Git stores it once and points at it from both commits. That is how a
snapshot of everything, every time, stays small — **an unchanged file is never stored twice.** And
when you do ask what changed, Git compares two snapshots and works it out, which is lesson 3's
subject.

You will not type `cat-file` again in this course. It is here because it shows the three things a
commit is made of with nothing in the way: a snapshot of the files, the metadata that answers
who, when and why, and a pointer to the commit before.
