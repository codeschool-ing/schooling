---
title: The first five minutes
version: 1
---

Lesson 13 was Ana's side of pull request #31. This one is Bruno's. Four comments arrived on his change:

- `blocking:` with the field empty, *Order* still submits. Adding `required` would stop that.
- `question:` can a customer pick 03:00, when we are closed?
- `nit:` *Place order* says more than *Order*.
- The heading colour change affects every page. Could it go in its own pull request?

## Do not answer yet

The worst replies to a review are written in the first five minutes. **Read every comment before
answering any of them.** A remark that stings on its own often makes sense next to the others, and the
second comment sometimes answers the question the first one raised.

Then sort them the way the reviewer should have labelled them, and here Ana did: the blocking one first, the
question next, and the nit last. If a reviewer did not say how serious a comment is, ask, or assume it is
blocking until they say otherwise.

## It is about the code

The feeling that a comment is about you is normal, and it is almost always wrong. Ana did not write
*"Bruno forgot the validation"*; she wrote that an empty field submits. Two things help that land:

- **The comment found a bug before a customer did.** That was the whole point of asking for a review. An
  empty order discovered by Ana costs one line; discovered by the bakery at six in the morning it costs a
  customer.
- **Everybody's code gets comments**, including the reviewer's own. Experienced developers get fewer
  blocking comments, not zero, and they get plenty of questions.

If a comment really is about you (*"you always do this"*), that is a problem with the comment, and it is
fair to say so, calmly and away from the pull request, to the person or to whoever runs the team. It is rare.
Much more often, a short comment written in a hurry reads harsher than it was meant.

## Assume the best reading

Text loses tone. *"Why is this here?"* can be curiosity or accusation, and the reader chooses which one to
hear. **Choose the charitable one, and answer it as a question.** If you were wrong, you lost nothing; if you
were right, you answered what was asked.
