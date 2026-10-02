---
title: What a reason gives the next reader
version: 1
---

The measurement could not separate the two prompts. The argument for the guide does not rest on it
alone, because a prompt has two readers, and the second is a person.

## A case nobody listed

Here is a message from the holdout that neither prompt was written for:

```
ana@lab:~/triage$ grep h01 cases/all.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
ana@lab:~/triage$ grep -n refund prompts/v8-rules.txt
16:- Do not mention refunds unless the customer does.
17:- A refund is billing.
18:- A refund for a returned book is returns.
ana@lab:~/triage$ pl check runs/rules.jsonl --failures | grep h01
h01    category  returns, expected billing
```

Read as written, line 18 settles it: a refund for a returned book is returns. The person who
labelled it said billing, because the refund went to the wrong card, and only the accounts desk can
put money back on a card. **The rule list gives a confident wrong answer** to the first case its
authors did not think of, and adding a fourteenth rule for it would only move the edge to the next
case.

The guide does not mention this case either. What it gives is a question to ask of any case:

```
ana@lab:~/triage$ grep -n "goes to" prompts/v8-guide.txt
10:- billing goes to the accounts desk: money taken, owed or charged wrongly.
11:- delivery goes to the warehouse: an order on its way, late or lost.
12:- returns also goes to the warehouse: a book coming back, or a refund for one.
13:- account goes to whoever runs the website: signing in, settings, personal data.
```

Who can fix a refund paid to the wrong card? Not the warehouse. Line 10 says money charged wrongly
goes to the accounts desk. **A rule with its reason can be applied to a case nobody listed**; a rule
without one can only be matched against the cases it names. In the stand-in `h01` comes back as
returns under the guide too, because the stand-in does not read reasons, which is the previous
section's point and not a verdict on this one.

## Which rule may go

The second reader is whoever maintains the prompt. Take line 19 of the rules, *Do not use the word
"customer" in the summary*. Somebody had a reason. Nobody now knows it, so nobody dares delete the
line, and the prompt keeps growing in the one direction lesson 2 warned about. **A reason written
beside a rule is what lets the next person decide it no longer applies**, and delete it with a
test instead of a guess.

The guide's line about names has its reason attached: the summary is read by somebody choosing what
to do next, and the name does not help them choose. If the team one day wants names in the summary,
the reason says what changed and the line can go.

## What the vendors say

Anthropic's prompt engineering documentation for Claude recommends exactly this: give the model the
context and the motivation behind an instruction, and say what to do rather than only what not to
do. It presents that as guidance, not as a measured gain, and it is the hypothesis the previous section
showed you how to test on your own cases.

Not every line needs a reason. The label lists and the JSON shape are contracts, as lesson 3 put it,
and a contract is stated, not argued. **Reasons belong where the reader has to use judgement**:
which desk, how urgent, what the summary is for.
