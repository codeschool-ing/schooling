---
title: Quality as the whole team's job, and what the tester does in it
version: 1
---

**"Quality is everybody's responsibility" is a slogan that, said on its own, makes quality nobody's.**
It becomes true only when the team agrees what each person does about it, and when somebody's job is to
make that easier. Lisa Crispin and Janet Gregory, whose book *Agile Testing* (2009) gave this its name,
call it the **whole-team approach**: the team, not a department, owns quality, and testers bring a
particular skill to that ownership rather than holding it alone.

## What changes for everybody

Under the whole-team approach the jobs overlap on purpose:

- **developers** test their own work before anybody else sees it, and write the automated checks that
  keep it working. Lesson 15 is about the most disciplined form of that, writing the test first;
- **the product owner** writes requirements that can be checked, with examples, and answers questions
  about them quickly. Lesson 2's four questions and lesson 17's acceptance tests are the tools;
- **the tester** brings the questions nobody else is asking, explores what nobody scripted, and makes the
  risks visible early enough to act on.

No role disappears. The difference is that a defect is everybody's concern from the first conversation,
and the tester is somebody the others go to for help rather than a door they have to pass.

## A week at Cine Aurora

What Lia actually did in her third week shows the shape of the job better than a description:

| day | what Lia did | who it helped |
|---|---|---|
| Monday | sat with Joana while she wrote next sprint's rules, and asked what "under 12" means for a child turning twelve on the day | Joana, before anything was built |
| Tuesday | paired with Rafael for an hour on the coupon feature, suggesting inputs while he wrote tests | Rafael, while the code was being written |
| Wednesday | explored the seat map for ninety minutes with no script, taking notes; found that a refresh lost the selected seats | the whole team, with a finding nobody had planned to look for |
| Thursday | wrote the information for the release decision, including what was not tested | Joana, who decided |
| Friday | showed Célia how to report a problem with the order number and the time, so the next report from the counter starts with evidence | Célia, and every future investigation |

Count the hours spent checking finished work. Thursday's report rests on it, and it is a minority of
the week. Most of the value came before code existed, or while it was being written, or from teaching
somebody else to see problems. **That is what makes a tester a multiplier rather than a gate**: each hour
spent improving how others work is repaid every time they work.

## The tester as a coach

The word that keeps appearing for this role in modern teams is **coach**, and it is easily
misunderstood as "a tester who no longer tests". It means a tester whose testing knowledge is spread
through the team: developers who ask "what about sixty exactly?" without being prompted, a product owner
who writes "60 or over" the first time, a box office manager whose reports arrive with times and order
numbers.

The goal is not to make the tester unnecessary. It is to point their attention at the problems that
only somebody with their particular habit of doubt would find, because the easy ones are being caught
by everybody else.

## What does not change

Some things stay the tester's, whatever the team calls its approach. Somebody has to hold the overall
picture of what has been tested and what has not; somebody has to bring an outsider's eye to work they
did not do; somebody has to be the person who says, at a planning meeting, *we have never tested what
happens when two people buy the last seat at the same moment*. In a whole-team approach those are still
the tester's, and they are more valuable for not being buried under the checks everybody else can do.
