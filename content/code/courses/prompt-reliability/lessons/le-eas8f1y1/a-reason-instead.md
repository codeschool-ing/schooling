---
title: A reason instead of a rule
version: 2
---

The alternative to a list of rules is an explanation of the job. This prompt asks for the same JSON
with the same labels, and spends its words on what each label is **for**. Save it as
`prompts/v8-guide.txt`:

```
You sort customer messages for Folio, an online bookshop, so that the right
person answers each one and the urgent ones are answered first.

Answer with only a JSON object with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

What the categories mean, because two people answer them:
- billing goes to the accounts desk: money taken, owed or charged wrongly.
- delivery goes to the warehouse: an order on its way, late or lost.
- returns also goes to the warehouse: a book coming back, or a refund for one.
- account goes to whoever runs the website: signing in, settings, personal data.
- other is for anything that needs neither.

Urgency is about harm, not tone. A customer out of pocket, or unable to
reach their account, is high however politely they ask. A question that
can wait a day is low.

The summary is read instead of the message by somebody choosing what to do
next, so it says what the customer needs, without their name.

<message>
{{message|xml}}
</message>
```

Each category is described by who answers it, because that is what the category decides: the
accounts desk, the warehouse, whoever runs the website. Urgency gets one sentence of principle,
*about harm, not tone*, and two instances of it. The summary is described by who reads it and what
they do next, and the rule about names follows from that.

```
ana@lab:~/triage$ python3 lint.py prompts/v8-guide.txt
prompts/v8-guide.txt: nothing found
```

**The linter finds nothing**, and in this case that is more than the absence of a pattern, because
there is nothing of the kind it looks for: no prohibitions in a row, no capitals, no pair of
opposites.

## The conflict, settled by the reason

Take `t22` to the guide instead of the rules. It is a question, about paying, from somebody who has
not paid yet. Nobody is out of pocket, and it can wait a day, so the guide's principle says low,
which is what the person who labelled it said. The guide did not need a rule about questions or a
rule about money. **A principle covers the cases two rules were each written for, and the one where
they collide.** That is the argument; the next section checks it against the model.

## Longer, and not padded

The guide is longer than the rules: 285.3 tokens a call against 231.3, the next section's runs say.
Lesson 2 cut a prompt by 97 tokens and lost nothing, and that is not a contradiction: what lesson 2
cut were lines that decided nothing, said something twice or fought each other. **Every line of
the guide carries a reason a reader can apply to a message**, and the test of a line is whether it
changes an answer, not how short it is. Whether these lines change answers is a measurement, and
the next section makes it.
