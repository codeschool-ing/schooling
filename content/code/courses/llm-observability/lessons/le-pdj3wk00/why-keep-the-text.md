---
title: Why the text is worth keeping
version: 2
---

`observability` lesson 10 ends with a rule for ordinary services: the body of a request does not go
in a log, because sooner or later it carries everything that must never be there. A model call is
the case where that rule is hardest to follow, because **the body is the thing being observed**.

Look at what lesson 1 could and could not explain. The answer about return postage was wrong, and
the trace said where: the one chunk kept was the right one, and the model contradicted it. That
worked because the question and the reply were on the root span. Take them away, and the trace says
that a request in the `help` feature kept one chunk and got a 14-token reply. Nobody can tell
whether that is a good answer to a good question or a wrong answer to the right one.

The text is needed for three jobs, and each needs a different amount of it:

| job | needs | for how long |
|---|---|---|
| **debugging one bad answer** | the question, the reply, and which sources were used | until the complaint is closed: days |
| **evaluating quality** (lessons 8 to 13) | questions and replies, in quantity, and the sources a judge checks against | until the evaluation has run: days, or a sample kept longer |
| **counting and alerting** (lessons 3 to 5, 16) | no text at all: tokens, times, outcomes, scores | as long as the trend matters: months |

The table is the argument of this lesson. **The text and the numbers have different lives.** A
system that stores both in the same place for the same time has either thrown away its debugging or
kept a year of conversations that nobody needed for more than a week.

## What makes a model call different from an ordinary request

Three things, each of which makes the text more dangerous to keep than the body of a web request.

**People write to it as they would write to a person.** A form asks for an order number in a field.
A chat box gets a paragraph: a name, an address, how the order went wrong, and sometimes why the
book was a present and for whom. The next section counts what Marginalia's customers typed in a
week.

**The prompt carries more than the customer wrote.** It carries the retrieved sources, which in a
system like `rag` lesson 14's can include documents only some staff may read. A trace that keeps
the full prompt keeps a copy of those documents outside the database that enforces who may read
them.

**The reply can repeat any of it.** A model that is told the customer's name will use it, and a
redaction that only looks at the input leaves the output carrying exactly what was removed from it.

None of that says the text must not be kept. It says **what is kept is a decision, made per field,
with a purpose and an end date**, which is what the LGPD asks of any processing of personal data.
The rest of this lesson builds the pieces: knowing what arrives, taking it out before it is written,
a second net behind the first, names instead of identities, and an expiry.