---
title: A report from the counter
version: 1
---

**On a Monday, Célia came to Lia with a complaint she had heard on Sunday.** A family of four, two
adults and two children, had bought tickets on the website for the new 9:30 session, the cinema's first
ever morning screening, put on for a children's film. At the counter they would have paid R$ 84,00. The
website had charged them R$ 108,00. They wanted the difference back, and Célia wanted to know whether it
would happen again next Sunday.

That is a typical defect report from outside the team: **true, important, and almost useless for
finding the cause.** It says something went wrong. It does not say what.

## First, the evidence that already exists

Before running anything, Lia wrote down what was known, separating what was observed from what was
inferred:

- **observed:** four tickets, Sunday, 9:30 session, two adults, two children aged 8 and 10, R$ 108,00
  charged;
- **observed:** the box office price would have been R$ 84,00. Two adults at the matinée price of
  R$ 28,00, two children at half of that;
- **inferred, not yet checked:** the website and the box office use the same rules.

The arithmetic is worth doing, because it is evidence too. R$ 108,00 is exactly two times R$ 36,00 plus
two times R$ 18,00: **the evening price, with the children's discount applied.** That one subtraction
already rules things out. The children were recognised as children. What failed was the session.

## Then, the hypotheses

With the evidence on paper, Lia listed every explanation she could think of that fitted it, before
testing any of them:

1. the shop treats **Sunday** differently from other days;
2. the shop treats any session **before a certain hour** as an evening session, because nobody expected a
   morning one;
3. the **time** reached the price rule written in a way it does not understand;
4. the family chose the 19:00 session by mistake and the website was right.

Listing them first matters. A tester who tests the first idea that comes to mind and finds it plausible
stops there, which is confirmation bias again, from the other side. Four hypotheses, each capable of
being wrong, can be put against each other by experiments.

The fourth is the cheapest to check and does not need the program at all: the order record said 9:30.
The family was right. Three left.

## What makes a hypothesis worth testing first

Not all three cost the same to settle, and they are not equally likely. A useful order is: **the one
whose experiment is cheapest and whose result rules out the most.** One run of the price for an adult at
a Sunday afternoon session settles the first, and a few runs at different morning hours separate the
second from the third. The next section runs them.

Notice what Lia has not done yet. She has not opened `tickets.py`, has not guessed at a line of code,
and has not told Rafael anything except that there is a report she is looking into. **She is building
evidence that will survive being shown to the person who wrote the code**, which is the only kind of
evidence that gets a defect fixed rather than argued about.
