---
title: What a role cannot do
version: 1
---

The common belief behind "You are a world-class expert" is that the line makes the answers better
in substance: more accurate, more knowledgeable, more authoritative. **A role adds no knowledge and
no authority.** The model knows what it knew before the line, and nothing it says becomes more
true because of the title it was given.

## The expert who does not know your kitchen

A customer asks the café's assistant whether the cinnamon bun is safe for someone with a nut
allergy. The course wrote this prompt as an illustration of a role used for the wrong job:

```localised
You are a world-class food allergy specialist with twenty years
of experience. Answer with authority.

Customer: Is your cinnamon bun nut-free?
```

The model has never seen Café Aurora's kitchen. What a role like this changes is the **tone** of
whatever it writes next: confident, specific, reassuring. If the likely continuation is "Our
cinnamon bun does not contain nuts", the role makes that sentence sound like a specialist's
verdict. The café's handbook says otherwise: the kitchen uses nuts, so no item can be guaranteed
nut-free.

That is the failure of lesson 5 with a costume on. **A role can make a wrong answer more
persuasive, and it cannot make it right.** The facts have to come from somewhere the café controls:
the handbook text sent with the question, as the system prompt of lesson 22 requires, with the
instruction to say "I do not know" when the text has no answer.

## Roles combined with explicit instructions

A role sets the voice; the instructions say what the reply must contain and must never do. Used
together, each does its own job. The course wrote this version as an illustration:

```localised
You are the assistant at Café Aurora's counter: warm, brief, plain.

Answer only from the handbook text below. If it does not settle the
question, say so and suggest asking the kitchen. Never say an item
is free of an allergen.

<handbook>
The kitchen uses nuts, so no item can be guaranteed nut-free.
If a customer asks about an ingredient that is not on the label,
ask the kitchen; never guess.
</handbook>

Customer: Is your cinnamon bun nut-free?
```

The role is one line and the rules are the rest. A test set (lesson 20) can check the rules: the
reply mentions that the kitchen uses nuts, and it never says "nut-free". Nothing can check "be a
world-class specialist", and nothing needs to.

## The role of the audience often matters more

The role people reach for first is the model's: who it should be. The one that changes a reply
most is often the **reader's**: who the reply is for. A model told who it is talking to adjusts
the vocabulary, the length and what it explains, which is most of what a role was wanted for.

The course wrote this pair as an illustration. The same request, aimed at two readers:

```localised
Explain to a new barista, on their first day, why we ask customers
about allergies before recommending a cake.
```

```localised
Explain to the café's insurer why staff ask customers about
allergies before recommending a cake.
```

The first wants short sentences, a reason a newcomer will remember, and what to say at the counter.
The second wants the policy, the risk it manages and the record that it is followed. **No role for
the model was needed in either**: naming the reader set the register, the vocabulary and the angle
at once.

So when a reply comes back pitched wrong, too technical or too vague, too long or too thin, the
first thing to check is whether the prompt said who it is for. "Explain to a new barista" is
specific, it can be judged against a reply, and it describes something real. "You are an expert"
is none of the three.
