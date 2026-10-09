---
title: What examples leak
version: 2
---

An example shows the answer, and **the model copies more of it than you meant as answer**. Look at
how one message came back without the examples and with them:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t22
│ {"category": "other", "urgency": "low", "summary": "Customer wants to know if they can use a gift card and a credit card together in one order"}
stop: stop, tokens in 108, out 38, 3.8 s
ana@lab:~/triage$ pl show runs/v3.jsonl t22
│ {"category": "other", "urgency": "low", "summary": "Asks about payment options for a gift card and credit card."}
stop: stop, tokens in 250, out 32, 4.0 s
```

The summary changed voice. Without examples it began *"Customer wants to know"*; with them it
begins *"Asks about"*, because two of the three example summaries begin *Wants* and one *Asks*.
Nothing checks for that and nothing needs to, but it is the first sign of what the next file does
on purpose.

## One field nobody meant

`prompts/v3-leaky.txt` is `v3-examples.txt` with one change. Somebody copied the first example out
of a real ticket and kept the order number. Save it as `prompts/v3-leaky.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

<example>
Message: I paid for express delivery but the order came by normal post.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "order": "4471"}
</example>

<example>
Message: The book came with water damage on every page.
Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book."}
</example>

<example>
Message: Can I change the name on my account?
Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name."}
</example>

Message: {{message}}
```

```
ana@lab:~/triage$ grep -n order prompts/v3-leaky.txt
9:Message: I paid for express delivery but the order came by normal post.
10:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "order": "4471"}
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, llama3.2:3b, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl --failures
check      pass  fail
json         39     1
fields       34     6
labels       34     6
category     30    10
urgency      24    16
all          24    16

t01    fields    unexpected order
t02    urgency   high, expected normal
t07    urgency   high, expected normal
t08    fields    unexpected order
t09    urgency   high, expected normal
t16    fields    unexpected order
t21    fields    unexpected order
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t31    fields    unexpected order
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t37    json      not a JSON object
t39    urgency   low, expected normal
```

Five replies carry a field called `order` that nobody asked for. They are not random: `t01`,
`t08`, `t16`, `t21` and `t31` are all messages about an order or a payment, the ones that look most
like the example that carried it. And look at the value:

```
ana@lab:~/triage$ grep -c 4471 runs/leaky.jsonl
5
ana@lab:~/triage$ pl show runs/leaky.jsonl t16
│ {"category": "billing", "urgency": "normal", "summary": "Wants a refund for the £3 price difference.", "order": "4471"}
stop: stop, tokens in 256, out 36, 4.0 s
```

`grep` counts five replies with `4471` in them, and only one customer, `t01`, ever mentioned order
4471. `t16` is somebody overcharged by three pounds, and the model gave them the example's order
number, because it had a field it was shown and no value of its own to put in it. **Names, dates
and numbers in examples turn up in answers about something else.**



**The check caught it because it is strict.** `fields` fails a reply with a field nobody asked
for. A check that only looked for the fields it needed would have passed all five, and a wrong order
number would have reached whatever reads the JSON next, looking exactly like a right one.

**And a demo would never have shown it.** Try the leaky prompt on one message, *"I can't log in"*,
and the reply is clean. The defect lives in five messages in forty, the ones that resemble the
example, and only a test set is big enough to contain them.

## Keeping examples from teaching the wrong thing

- Vary whatever should vary. The summaries here start with *Wants*, *Wants* and *Asks*, and
  the model's summaries now start the same way.
- Remove what belongs to one customer: names, order numbers, dates, amounts. Replace them with
  values that are obviously examples, or leave them out.
- Make the examples answer exactly what the prompt asks for, field for field. An example is
  the strongest instruction in a prompt, so an example that disagrees with the description wins.
- Check strictly, so that what an example leaks fails a test instead of reaching a reader.
