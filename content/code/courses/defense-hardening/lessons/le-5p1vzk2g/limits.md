---
title: What a scanner cannot see
version: 1
---

**Antivirus answers one question: is this file one we recognise as bad?** Everything it does well
follows from that question, and so does everything it misses. A defender who knows the misses can put
other controls where they are, which is the point of the rest of this course.

## Four gaps

**The new.** A signature exists only after somebody has seen the file, judged it and shipped the
description. The first hours of anything new pass before that happens, and so does anything made for
one target that no vendor ever sees. Heuristics narrow this gap and do not close it.

**The changed.** The hash section showed it with one space: an exact description fails on the first
byte of difference. Content rules and heuristics follow variants further, at the cost of the false
positives in their own sections.

**The fileless.** Some intrusions never write a program to disk. They use what is already installed,
a shell, a scripting language, an administrator's tool, and the commands they run live in memory and in
the command line. A file scanner has no file to scan. This is the gap EDR exists for, and lesson 8 is
built on it.

**The legitimate.** An intruder who logs in with a stolen password and runs the firm's own tools does
nothing a scanner can call malicious, because nothing is. The controls for that are the accounts and
access of lessons 1, 6 and 15, and the inventory of lesson 18.

## What that makes antivirus

Not useless: it stops the enormous volume of known, circulating malware cheaply, on every machine, and
that volume is most of what reaches a small firm. **It is a floor, not a wall.** A scanner reporting
"clean" says that the file matches nothing the vendor has described, which is a statement about the
vendor's knowledge as much as about the file.

So it is measured like every other control in this course. Test it with the EICAR file after every
change to the mail gateway or the endpoint policy, the way this lesson did, and watch the age of its
signatures. And place the next layers where its gaps are: a host that runs only what it should (lessons
1 and 12), a record of what programs actually do (lesson 8), and an inventory that knows what belongs
there (lesson 18).
