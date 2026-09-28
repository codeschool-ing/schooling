---
title: The question you cannot answer
version: 1
---

Some question will go past what you know. *How would you handle a thousand requests a second?* *What
isolation level does SQLite use?* For a junior this is expected, and the interviewer is often asking
precisely to find the edge. What they are watching is what you do when you reach it.

**Say that you do not know, plainly.** *I don't know* is three words and costs nothing. A confident
guess costs a great deal, because the interviewer usually does know, and a wrong answer delivered with
certainty tells them you will do the same with a production system.

**Then say how you would find out**, which turns the edge into evidence. *I don't know SQLite's isolation
level off-hand. I'd check the documentation, and then I'd test it: two connections, one writing inside a
transaction, and see what the other reads.* That answer shows the thing a team most needs from a junior,
which is not knowing everything but knowing how to learn it safely.

**And, where it helps, reason out loud from what you do know.** *I know SQLite lets one write happen at a
time and checks the unique index on each, so for that one rule I don't depend on the isolation level.* Partial knowledge, labelled as partial, is worth more than a guess and more than
silence.
