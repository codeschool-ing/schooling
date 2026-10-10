---
title: What no quiz here can grade
version: 1
---

The questions at the end of this lesson can check a great deal. They can ask whether *some* is a
vague word, whether a precondition is missing, whether a step hides two actions, and they can mark
the answer. **They cannot check whether a case you wrote can be run by a stranger**, and that is
the skill this lesson is about. Nothing in this course can mark it, and this section says so
plainly rather than hide it behind questions about case design.

The reason is in the definition. A case passes the stranger test when a stranger runs it and does
not have to ask anything. The only instrument that measures that is a stranger. A question has a
key, written in advance, and your case did not exist when the key was written. A machine reading
your case could find *some* and *correct*, the way section 03's table does. It could not tell you
that *the usual account* is clear to you and to nobody else, because it does not know what you
know.

So the check is yours to run. It takes an hour and one other person, and it is the most useful
hour in this lesson.

## Hand it to somebody

**Write the cases.** Take two scenarios lesson 2 did not cover and write a case for each, in the
shape of TC-BOOK-04: a student booking two tickets for Hamlet pays half (R5), and cancelling a
reserved order gives its seats back (R6). Work out every expected result from the requirements
before you run anything. Then run each one yourself, from the page, as section 05 did.

**Find a stranger.** Somebody who has never seen boxoffice: a friend, somebody you live with, a
colleague from another team. They do not need to know anything about testing, and it is better if
they do not, because a tester fills gaps from habit. A video call with your screen shared works as
well as a chair beside you.

**Give them the case and nothing else.** Restart boxoffice so the precondition holds, open the
browser on your computer or theirs, and hand over the case. Do not explain what it is for, do not
summarise it, and do not show them how the form works.

**Then say nothing.** This is the hard part. When they hesitate, when they ask, when they do
something you did not mean, write it down and do not answer. If they are stuck, tell them to do
whatever they think the case means, and write that down too. Every answer you give out loud is a
hole in the case that you just hid from yourself.

**Compare.** When they finish, ask for their verdict, passed or failed, and compare it with yours.
Then compare what they did with what you meant: the show they chose, the number they typed, where
they looked for the result.

## What to do with what you wrote down

**Every question they asked is a defect in the case**, and so is every place they did something
other than what you meant, even if the verdict came out the same. Fix them in the case, never in an
explanation. Then give the fixed case to a **different** stranger, because the first one now knows
the answers and can no longer find the holes.

Two cases with no questions from a stranger who had never seen boxoffice is the finish line. Most
first attempts get three or four questions each, and the questions repeat: the same vague word, the
same missing state. That repetition is the useful part. It is a list of your own habits, and the
next case you write will be read with that list in mind.

## When there is nobody to hand it to

There is a weaker check for the days when nobody is around: **the cold read**. Put the case away
for three or four days, long enough to forget the details. Then restart boxoffice, close the
requirements, and run the case doing exactly what each line says and nothing it does not say.
Wherever you have to stop and think about what you meant, the stranger would have asked.

It is weaker because you cannot forget everything you know, and the words that are clear only to
you are exactly the ones that stay clear. It is still far better than reading a case over
straight after writing it, which checks nothing: at that moment every word means what you meant.

## Why this lesson carries so much weight

The `qa` track is judged on this skill more than on any other. A defect report, the subject of
lesson 15, is a case somebody else must run to see the failure. An acceptance test, lesson 12, is
a case the client runs. And the automation courses that follow this one turn cases into programs,
where the stranger is a script that cannot ask and cannot guess. A case that survives a person who
has never seen the application is a case that can be turned into a program, handed to a client, or
attached to a report. **The quiz below grades whether you recognise the faults. The stranger
grades whether you can avoid them**, and only the stranger's mark is the one that counts.
