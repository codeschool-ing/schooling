---
title: The editing pass
version: 1
---

**Clear writing is mostly rewriting.** Nobody produces the pyramid, the precise numbers and the
economy in a first draft, and trying to makes the first draft slower without making it better.
Write the draft to find out what you think, then edit it for the reader in separate passes, each
looking for one thing.

## Six passes, in this order

The order matters: there is no point polishing sentences in a paragraph the structural pass is
about to delete.

1. **The point in one sentence.** Before touching the draft, write what it is for in a single
   sentence, without looking. If you cannot, the document is not ready to edit; it is ready to be
   thought about. If you can, compare it with the draft's first lines.
2. **The skim.** Read only the title, the headings and the first sentence of each paragraph. Does
   that alone carry the argument? If a paragraph's claim is in its fourth sentence, move it up.
3. **The cut.** Go paragraph by paragraph asking what the reader would lose if it disappeared. Then
   sentence by sentence, then the five kinds of empty word from the last section.
4. **The facts.** Check every number, name, date and link against its source. This is the pass a
   reader will hold against you: a wrong figure in an otherwise excellent document is what they
   remember, and it makes them doubt the rest.
5. **Aloud.** Read it out, or at least move your lips. A sentence you run out of breath in is too
   long; a sentence you stumble on is ambiguous. The ear catches what the eye forgives.
6. **One real reader.** Give it to one person like the intended reader and ask them a single
   question: "What do you think I am asking you to do?" If their answer is not your sentence from
   pass 1, the document failed, however well it reads.

## How long it takes

For a page, the six passes take Lívia about as long as the first draft did. That feels expensive
until the arithmetic from the first section of this lesson is done again: a page read by thirty
people is worth the half hour.

For a chat message, the passes collapse into one question asked before pressing enter: **is the
point in the first line?** For an incident update, lesson 14 replaces them with a fixed template,
because under pressure nobody edits.

## A worked example

Lívia's first draft of a message to the seven tech leads:

> Hi all! Hope everyone had a good weekend. So, following on from the discussions last week about
> various things, I've been thinking a lot about how we handle database access across the teams,
> and there are some things I'd like us to consider going forward, especially given what happened
> on Friday, which I think a lot of you saw. Basically I'd like each team to look at their
> connection usage. Could you do that sometime this week or next? Let me know if questions.

Pass 1, the point in one sentence: *every team should report its peak database connections by
Friday so we can set limits per service.* The draft never says the second half.

Passes 2 and 3 move that sentence to the top and cut the greeting, "various things", "a lot" and
"basically". Pass 4 finds that "what happened on Friday" needs a link, because two of the seven
leads were on holiday. Pass 5 breaks the long second sentence. Pass 6 is Bruna, who reads it and
says, correctly, "you want a number from each of us by Friday".

> Please send me your team's peak connections to the orders database by Friday 13 March. I will use
> them to propose a limit per service, so that one team's batch job cannot take checkout down, as
> happened last Friday (the incident notes are attached). If you do not know where to find the number, reply
> and I will pair with you on it; it takes about ten minutes.

The final message is the same length as the draft. **It is better because each sentence now does a
job**: the ask, the reason, the evidence, and help for the reader who is stuck.
