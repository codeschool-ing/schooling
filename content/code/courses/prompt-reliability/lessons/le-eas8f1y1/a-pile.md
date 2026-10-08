---
title: A pile of rules
version: 2
---

A prompt in production collects rules the way lesson 2's prompt collected lines. A summary comes
back with a name in it, so somebody adds *Do not put the customer's name in the summary*. An urgent
refund is marked normal, so somebody adds a rule about money. **Each rule fixes the answer that
prompted it**, and nobody reads the list again as a whole. Here is what thirteen of them look like.
Save it as `prompts/v8-rules.txt`:

```
You sort customer messages for Folio, an online bookshop.

Answer with only a JSON object with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Rules:
- Keep the summary short.
- Do not use the category other unless you have to.
- Do not guess.
- NEVER mark a question as high urgency.
- ALWAYS mark a message about money as high urgency.
- Do not put the customer's name in the summary.
- Do not repeat the message word for word.
- Do not mention refunds unless the customer does.
- A refund is billing.
- A refund for a returned book is returns.
- Do not use the word "customer" in the summary.
- Include every detail the customer gives in the summary.
- Do not add fields.

<message>
{{message|xml}}
</message>
```

`cat -n prompts/v8-rules.txt` prints it with its lines numbered, and the rest of this lesson
refers to them by number.

Read it as the model would, top to bottom, with a message in hand, and see how much of it helps you
decide anything. Eight of the thirteen say only what not to do. Two are in capitals. Line 9 wants
the summary short and line 20 wants every detail in it. The linter from lesson 2 finds most of
that:

```
ana@lab:~/triage$ python3 lint.py prompts/v8-rules.txt
prompts/v8-rules.txt:9: 13 separate rules; a reader keeps fewer
prompts/v8-rules.txt:10: 8 rules say only what not to do: lines 10,11,12,14,15,16,19,21
prompts/v8-rules.txt:12: 2 lines shout: 12,13
```

## What a "do not" leaves open

A prohibition tells the reader one thing that is wrong, and nothing about what is right. *Do not use
the category other unless you have to* says that `other` is suspect. It does not say when you have
to, or which category to use instead. *Do not guess* forbids something every answer to an ambiguous
message has to do. **Eight rules of that kind mark out what to avoid and leave the target
unstated**, and the reader, model or person, fills the gap with whatever seems reasonable.

## The contradiction the linter did not see

Lines 12 and 13 are both rules about urgency, and the linter reported them only as shouting. Here is
a message they both apply to:

```
ana@lab:~/triage$ grep t22 cases/dev.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
```

It is a question, so line 12 says it can never be high. It is about money, so line 13 says it must
always be high. **Both rules are absolute and they cannot both hold**, and nothing in the prompt says
which one gives way. The person who labelled the case said low, for a reason neither rule
mentions: nobody has lost anything yet, and the answer can wait a day. The linter missed the
conflict for the reason lesson 2 gave: it matches words, and *never* and *always* are not on
its list of opposites.

Lines 17 and 18 have the same shape in a quieter form. A refund is billing; a refund for a returned
book is returns. A refund for a returned book that went to the wrong card is both, and the last
section of this lesson comes back to it.
