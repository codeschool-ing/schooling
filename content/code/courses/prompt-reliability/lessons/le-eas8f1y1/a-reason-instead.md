---
title: A reason instead of a rule
version: 1
---

The alternative to a list of rules is an explanation of the job. `v8-guide.txt` asks for the same
JSON with the same labels, and spends its words on what each label is **for**:

```
ana@lab:~/triage$ cat -n prompts/v8-guide.txt
     1	You sort customer messages for Folio, an online bookshop, so that the right
     2	person answers each one and the urgent ones are answered first.
     3	
     4	Answer with only a JSON object with three fields:
     5	- "category": one of billing, delivery, returns, account, other
     6	- "urgency": one of low, normal, high
     7	- "summary": one sentence saying what the customer needs
     8	
     9	What the categories mean, because two people answer them:
    10	- billing goes to the accounts desk: money taken, owed or charged wrongly.
    11	- delivery goes to the warehouse: an order on its way, late or lost.
    12	- returns also goes to the warehouse: a book coming back, or a refund for one.
    13	- account goes to whoever runs the website: signing in, settings, personal data.
    14	- other is for anything that needs neither.
    15	
    16	Urgency is about harm, not tone. A customer out of pocket, or unable to
    17	reach their account, is high however politely they ask. A question that
    18	can wait a day is low.
    19	
    20	The summary is read instead of the message by somebody choosing what to do
    21	next, so it says what the customer needs, without their name.
    22	
    23	<message>
    24	{{message|xml}}
    25	</message>
ana@lab:~/triage$ pl lint prompts/v8-guide.txt
prompts/v8-guide.txt: nothing found
246 tokens
```

Each category is described by who answers it, because that is what the category decides: the
accounts desk, the warehouse, whoever runs the website. Urgency gets one sentence of principle,
*about harm, not tone*, and two instances of it. The summary is described by who reads it and what
they do next, and the rule about names follows from that.

**The linter finds nothing**, and in this case that is more than the absence of a pattern, because
there is nothing of the kind it looks for: no prohibitions in a row, no capitals, no pair of
opposites.

## The conflict, settled by the reason

Take `t22` to the guide instead of the rules. It is a question, about paying, from somebody who has
not paid yet. Nobody is out of pocket, and it can wait a day, so the guide says low, which is what
the person who labelled it said. The guide did not need a rule about questions or a rule about
money. **A principle covers the cases two rules were each written for, and the one where they
collide.**

## Longer, and not padded

```
ana@lab:~/triage$ pl tokens prompts/v8-rules.txt
199 tokens, 152 words, 839 characters
ana@lab:~/triage$ pl tokens prompts/v8-guide.txt
246 tokens, 191 words, 1101 characters
```

The guide is 47 tokens longer. Lesson 2 cut a prompt by 98 tokens and lost nothing, and that is not a
contradiction: what lesson 2 cut were lines that decided nothing, said something twice or fought each
other. **Every line of the guide carries a reason a reader can apply to a message**, and the test of
a line is whether it changes an answer, not how short it is. Whether these lines change answers is
a measurement, and the next section makes it.
