---
title: Writing to a client
version: 1
---

**A client reads every sentence as a commitment, so a message to a client says only what you are
sure of, what it means for them, and what happens next.** Inside Marola, a wrong guess in a chat
thread is corrected in the next message. Sent to Boa Praça, the same guess may be quoted back in a
contract review six months later.

## What changes when the reader is outside

Four things are different when the reader is a client:

1. **Commitments are binding.** "It will be fixed by Monday" is a promise with a date. If you are
   not sure, say what you will do by Monday, not what will be true by then.
2. **Do not speculate about causes.** "We think it might be the database" becomes, in Tânia's
   inbox, "Marola told us it was the database". Say what you know: what happened, and when you will
   know more.
3. **No internal names, no blame.** Tânia does not know who Paulo is and should not learn it from an
   incident message. "A scheduled job on our side" is accurate and complete.
4. **One voice.** Boa Praça has one person at Marola who owns the relationship, and everything goes
   through or past them. Two engineers writing to the same client separately produce two versions
   of the truth.

## A message, rewritten

A logistics engineer drafted this to Tânia after deliveries to three Boa Praça stores were late on a
Tuesday morning:

> Hi Tânia, sorry about this morning!! We had a problem where the zone recalculation job that Paulo
> runs didn't finish in time because the DB was overloaded, I think because of the new replica
> config, so the routes were generated late. Should be fine tomorrow, we're looking into it.

Every sentence carries a risk: a colleague named, a cause guessed, a technology that means nothing
to her, and "should be fine tomorrow", which is a promise nobody can keep for certain. What Lívia
sent instead:

> Tânia, this morning deliveries to three of your stores (Boa Viagem, Casa Forte and Olinda)
> arrived between 40 and 70 minutes late. The cause was a delay in our route planning, which is
> now running normally. We are checking why it happened and will send you what we found, and what
> we are changing, by Thursday at 12:00. If tomorrow's deliveries are affected in any way, I will
> call you before 7:00. — Lívia

What it does: **the effect on her** first, with the stores and the size of the delay; the cause at
the level that is known for certain; a commitment Lívia can keep (to send findings by a time, not to
guarantee an outcome); and what Tânia will hear if it happens again, before her stores open.

## What does not go to a client

- **Other clients.** Never "we had the same issue with another chain last month".
- **Security detail.** If an incident involves access or data, the message goes through whoever owns
  security communication at Marola, and says what the client needs to do, nothing about how.
- **Internal disagreements.** "Engineering wanted to fix this last quarter but product didn't
  prioritise it" may be true and is never the client's business.
- **Apologies that admit what is not established.** "We are sorry the deliveries were late" is a
  fact and a courtesy. "We are sorry our negligence caused…" is a legal statement.
