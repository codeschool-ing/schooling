---
title: Words that make a stranger ask
version: 1
---

Most of the questions in section 02 were raised by a handful of words. *Some*, *a member*,
*correct*, *successful*: each one is short, each one reads naturally, and **each one is a promise
that the reader already knows what the writer meant**. The writer does, so the word looks finished
from where they sit. The stranger does not, and the word turns into a question or a guess.

The words are predictable enough to look for. A finished case is one that has been read once just
to find them.

## The words, and what replaces them

| word in the case | the stranger asks | what to write instead |
|---|---|---|
| some, a few, several | how many? | `3` |
| a show, any show | which one? | The Little Prince |
| a member, a user, the test account | which account, in what state? | `member@example.org`, confirmed |
| valid, invalid | by which rule? | name `Ana Lima`, which R2 allows |
| correct, right, proper | according to what? | R$ 81,00 |
| check, verify, make sure | check what, where? | the row for The Little Prince reads 197 under Seats left |
| works, successful, OK | what does that look like? | an order is reserved, in the state reserved |
| an error, an appropriate message | which sentence, saying what? | a sentence saying the e-mail already has an account |
| etc., and so on | what else? | list the rest, or delete the word |
| as usual, the normal way | whose usual? | the steps themselves |

Every replacement in the third column is something the stranger can find on a screen or type
into a field. That is the test for a replacement: **it has to be a value or an observation, never
another word that needs explaining.** *Correct price* replaced by *the right total* has moved the
question and kept it.

## Expected results say where to look

The vague words do the most damage in the expected result, because that is where the verdict is
decided. *The page should be correct* asks the stranger to know what correct is. *The booking is
confirmed* asks them to know where a confirmation would appear, and in boxoffice it could mean a
message on the Order page or an e-mail in the Outbox.

**An observable expected result names a place and a thing that should be there.** The Order page,
and the words `State: reserved`. The Shows page, and the number under Seats left. The Outbox, and
an e-mail addressed to `ana@example.org`. A stranger given a place and a thing has nothing to
interpret: it is there or it is not.

Where a result is a number, it is written the way the application writes it. boxoffice prints
`R$ 81,00`, with a comma before the cents, and a case that says *81.00* has handed the stranger one
more thing to translate.

## Steps say what to do, once each

A step that bundles actions hides where the bundle went wrong. *Fill in the form and submit it* is
four actions on boxoffice's booking form, and when the result is wrong, the stranger cannot say
which of the four was the problem. **One action per step**, numbered: type this, choose that,
press the other.

Controls are named by what the stranger sees on them. boxoffice's button says Book, so the step
says *press Book*. The field for the number of tickets shows the words Tickets (1 to 6), so the
step says *the field that reads Tickets (1 to 6)*. Naming the control by
its words, not its position, keeps the case true when the page is rearranged.

## The opposite mistake

Asked to remove every question, some writers go the other way, and that fails the test too.

**Writing what the stranger already knows** buries the steps that matter. *Move the mouse to the
address bar, click it, type the address, press Enter* is four steps the stranger did not need, and
by the time they reach the step that matters they are skimming. The stranger of section 02 can use
a browser, so *open `http://127.0.0.1:8000/book`* is the whole step.

**Writing what the case does not depend on** makes it fail for reasons that are not defects.
*Press the blue Book button at the bottom left of the form* breaks the day the button turns green
or moves to the right, while booking works perfectly. *Press Book* says everything the case needs.

The line between the two is the stranger's description. Anything they could not know goes in;
anything they already know, or anything the verdict does not depend on, stays out. That is why
section 02 described the stranger before writing a word of a case: **a level of detail is only
right or wrong for a particular reader.**
