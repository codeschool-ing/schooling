---
title: What counts as context
version: 2
---

A common belief about a good model is that it will work out what you meant: that a short request
is enough, and the model fills in the rest sensibly. It does fill in the rest. **What it fills
the gap with is whatever text usually comes next, not the facts of your situation**, because the
prompt is the only thing it has to go on (lesson 1). Contextual prompting is the habit of putting
those facts in the prompt instead of leaving the model to guess them.

## The same request, twice

Café Aurora, the café this course's handbook belongs to, gets an e-mail. Somebody paid R$ 140 by
card for a lemon cake, was handed a chocolate one, and wants the money back, in cash if possible.
The bare request is one line and the message under it. Save it as `~/pe/bare.txt` and send it:

```
ana@lab:~/pe$ cat bare.txt
Reply to this customer:

I ordered a lemon cake for a party and was given a chocolate one. I paid R$ 140 by card. I'd like my money back, in cash if possible.
ana@lab:~/pe$ ask - --temperature 0 < bare.txt
Dear valued customer,

I apologize for the inconvenience and disappointment caused by the incorrect cake order. I can imagine how frustrating it must be to receive a different cake than what you had ordered.

I'm happy to help resolve this issue for you. I'd like to offer you a full refund of R$ 140, which will be processed back to your original payment method as soon as possible. Unfortunately, I won't be able to provide a cash refund, as our refund policy only allows for credit to the original payment method.

Please allow me a few minutes to process the refund. You should receive the credit back to your account within the next 24-48 hours, depending on your bank's processing time.

If you have any further questions or concerns, please don't hesitate to contact me directly. I apologize again for the mistake and appreciate your patience and understanding.

Thank you for your business, and I hope you have a wonderful party with your guests.

Best regards,
[Your Name]
-- llama3.2:3b, finish: stop, prompt 66 tokens, output 199 tokens
```

It reads well, and it is worth checking line by line against the handbook. It refuses the cash,
which is the café's rule, and it gives a reason, "our refund policy only allows for credit to the
original payment method", that it did not read anywhere: **it guessed the policy, and the guess
happened to be right**. It promises the money in 24 to 48 hours, which nobody decided. It says
nothing about the shift manager, whose approval the handbook requires above R$ 100. And it is
signed `[Your Name]`. That is lesson 5's hallucination in its most ordinary form: no invented fact
about the world, only a plausible policy, right by luck in one place and silent in another.

With the refunds page and four lines about the job in the prompt, `with-context.txt`, which the
next section shows whole:

```
ana@lab:~/pe$ ask - --temperature 0 < with-context.txt
Subject: Refund for Incorrect Order

Dear [Customer],

We apologize for the mistake with your order. We will process a refund for the incorrect lemon cake. The refund amount is R$ 140, which will be returned to your original payment method. Please note that we cannot provide cash refunds for card payments.

Thank you for bringing this to our attention, and we hope you can enjoy the rest of your party.

Best regards,
Café Aurora
-- llama3.2:3b, finish: stop, prompt 244 tokens, output 92 tokens
```

The model is the same and so is the request. The card rule now comes from the handbook, the timeline
is gone, and it is signed by the café. **And the manager's approval is still missing**, though it is
one of the four lines of the refunds page in the prompt: the context made the right answer possible,
and did not make the model use all of it. The reply also says the refund is for "the incorrect lemon
cake", the one the customer never got. A member of staff reads every draft before it is sent, and
the prompt says so, which is exactly why.

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
