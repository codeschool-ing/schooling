---
title: A course of decisions, and the cinema they are made in
version: 1
---

**This course is about deciding what is worth checking, and when.** The courses after it in the `qa`
track teach the techniques: how to write a test case, how to automate a browser, how to load a server
until it bends. Every one of them assumes a vocabulary and a way of thinking that come first: what
quality is, where defects come from, why one found in March costs less than the same one found in
June, and how a tester fits into a team that ships every two weeks. That is what is learnt here.

## The twenty-two lessons

| lessons | the question they answer |
|---|---|
| 1 and 2 | What is quality assurance, and is quality a property of the product or of the way it was made? |
| 3 | Why is a defect found early cheaper, and by how much, honestly? |
| 4 and 5 | How does a tester think, and what is the tester for on a team? |
| 6 to 8 | Should you test from the outside, from the code, or from somewhere in between? |
| 9 to 14 | Where does testing sit in waterfall, the V model, the spiral, agile, Scrum, Kanban, XP and SAFe? |
| 15 to 17 | What changes when the test is written before the code: TDD, BDD and ATDD? |
| 18 | When a defect escapes, how do you find out why, rather than who? |
| 19 | How do you know a result is correct, when nobody wrote the right answer down? |
| 20 and 21 | With too little time, where do you start, and when have you tested enough? |
| 22 | Which numbers help a team, and which ones turn into theatre? |

Lessons 1 to 8 are about the tester: the thinking, the role, the angles from which a system can be
examined. Lessons 9 to 17 are about the process around them, from the oldest lifecycle models to the
practices where the test comes first. Lessons 18 to 22 are about judgement under pressure, which is
most of the job.

**Two of them argue more than they teach.** Lesson 5 is about the tester who believes their job is to
stop releases, and why that belief makes software worse. Lesson 22 is about the numbers a team reports
on quality, and how most of them stop meaning anything the moment somebody is judged by them. Read
those two as positions you are free to disagree with; the rest of the course is easier to apply if you
hold them.

## Cine Aurora

Every example happens at one place, so that the examples add up. **Cine Aurora** is a three-screen
cinema in Belo Horizonte, with an online ticket shop. It does not exist. Four people appear, and the
course never needs more:

- **Lia** has just joined as the cinema's first tester. She is the one typing, and the name in every
  transcript;
- **Rafael** is one of the two developers, and wrote most of the ticket shop;
- **Joana** is the product owner: she decides what the shop does and writes the rules down;
- **Célia** runs the box office, has sold tickets for twenty years, and knows every rule the software
  is trying to follow.

The system under test is small on purpose: a price rule of about forty lines that this lesson prints,
and the pieces later lessons build around it. A small system lets every defect in the course be one you
can find yourself, and every claim about one be checked on your own machine.

## What it does not teach

The edges of this course are the start of other ones, and a lesson that reaches one says so and stops:

- writing test cases, and the techniques for choosing them, such as equivalence partitioning and
  boundary values, are `manual-testing`, the next course in the track;
- reporting a defect well, and the tools teams track them in, are `manual-testing` too;
- automating a browser is `web-automation`; load, performance and security testing are
  `non-functional-testing`;
- running tests in a pipeline, and measuring code coverage in one, are `testing-cicd`.

**The course is short on tools and long on judgement.** The one tool it installs is there for two
lessons. What it asks of you everywhere else is to look at a program, a requirement or a plan and ask
the question that would find the problem before anybody else does.
