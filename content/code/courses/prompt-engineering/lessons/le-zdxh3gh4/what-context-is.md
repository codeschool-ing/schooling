---
title: What counts as context
version: 1
---

A common belief about a good model is that it will work out what you meant: that a short request
is enough, and the model fills in the rest sensibly. It does fill in the rest. **What it fills
the gap with is whatever text usually comes next, not the facts of your situation**, because the
prompt is the only thing it has to go on (lesson 1). Contextual prompting is the habit of putting
those facts in the prompt instead of leaving the model to guess them.

## The same request, twice

Café Aurora, the café this course's handbook belongs to, gets an e-mail. Somebody paid R$ 140 by
card for a lemon cake, was handed a chocolate one, and wants the money back, in cash if possible.
The bare request is one line and the message under it:

```
Reply to this customer:

I ordered a lemon cake for a party and was given a chocolate one. I paid R$ 140 by card. I'd like my money back, in cash if possible.
```

The reply below was written by this course as an illustration of what a capable model plausibly
returns to that prompt. It is not a capture:

```localised
Dear customer,

We're so sorry about the mix-up with your cake! Of course we'll refund
you in full. Just pop into the café with your receipt and we'll give you
R$ 140 in cash at the counter. We hope to see you again soon!

Best wishes,
The team
```

It reads well, and **two of its promises break Café Aurora's rules**: the handbook says a refund
goes back to the card that paid, never in cash, and anything above R$ 100 needs the shift
manager's approval. The model did not know either rule. It wrote what refund replies usually say,
which is lesson 5's hallucination in its most ordinary form: no invented fact about the world,
only a plausible policy that happens to be somebody else's.

With the refunds page and four lines about the job in the prompt (the next section shows the whole
prompt), the course's illustration of the reply becomes:

```localised
Hello,

We're sorry you were given the wrong cake. You're entitled to a refund,
and it will go back to the card you paid with: we can't refund a card
payment in cash. Because the amount is over R$ 100, our shift manager
approves it first; we'll confirm by e-mail once that's done.

Café Aurora
```

The model is the same and so is the request. **The difference is four kinds of fact that the
first prompt did not carry.**

## Four kinds of context

| | what it answers | for the refund e-mail |
|---|---|---|
| who the answer is for | the reader, and what they already know | a customer, by e-mail, who has not read the handbook |
| what it is for | what happens to the output next | a draft a member of staff checks and sends |
| constraints | the limits the answer must stay inside | under 100 words; promise nothing the handbook does not cover |
| the data | the material the answer has to be built from | the refunds page and the customer's message |

The first two decide tone and shape. A reply for a customer differs from a note for the shift
manager about the same refund, and a draft somebody will check can say "a member of staff will
reply" where a message sent automatically could not.

The constraints are what you would otherwise correct by hand afterwards. **A limit you did not
write down is a limit the model cannot keep**, however obvious it is to you.

The data is the part people leave out most, because it is in their head or on their screen and
not in the prompt. A model asked "what are our opening hours?" has no "our". It can produce a
typical café's hours with complete fluency, and nothing in the reply will tell you they are
invented.

## What context is not

Context is facts about this task. Two neighbouring techniques put text in the prompt for other
reasons. A system prompt (lesson 22) carries the instructions that hold for a whole conversation
or application; a role (lesson 23) tells the model whose voice to answer in. The facts can travel
with either: the café's system prompt in lesson 22 says where its facts come from, and the handbook
text itself arrives with each question.
**What makes it contextual prompting is the question you ask while writing it: what does the
model need to know about this situation that it cannot know otherwise?**

A useful test is to imagine handing the prompt to a capable stranger, a temp on their first
morning, with no chance to ask questions. Whatever they would need to ask you before writing a
good reply is context the prompt is missing.
