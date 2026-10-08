---
title: Measuring it, honestly
version: 2
---

Forty messages are a small sample for a change that is supposed to help with the hard cases, so
this measurement uses thirty more: messages held back from everything so far, written to be harder,
with the labels a person gave them. Save them as `cases/holdout.jsonl`:

```
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h02", "message": "The delivery driver left my parcel with a neighbour I don't know. Can you find out who has it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "h04", "message": "I'd like to return the atlas, but the courier you use doesn't collect from my area.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h05", "message": "Can you send the invoice to my work email instead of my personal one?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "h06", "message": "The box arrived empty. The packing slip says three books.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "h07", "message": "How do I update the card saved in my account?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "h08", "message": "I was sent a refund for the wrong amount after my return.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h09", "message": "Your password rules won't let me use a space. Is that deliberate?", "expect": {"category": "account", "urgency": "low"}}
{"id": "h10", "message": "I placed an order as a guest. Can I attach it to my account now?", "expect": {"category": "account", "urgency": "low"}}
{"id": "h11", "message": "The tracking page shows my full home address to anyone with the link. That worries me.", "expect": {"category": "account", "urgency": "high"}}
{"id": "h12", "message": "I paid for gift wrapping and the book came unwrapped.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h13", "message": "The second volume in the set is the wrong edition. Everything else is fine.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h14", "message": "Is the price of the boxed set going down in the sale next week?", "expect": {"category": "other", "urgency": "low"}}
{"id": "h15", "message": "I can't see my order history since the website changed.", "expect": {"category": "account", "urgency": "normal"}}
{"id": "h16", "message": "My order arrived but one book was signed and the other wasn't, though both were listed as signed.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h17", "message": "The courier damaged my gate getting the parcel through.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h18", "message": "I want a refund for my subscription box: the last two arrived damaged.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h19", "message": "Please stop sending me catalogues by post.", "expect": {"category": "account", "urgency": "low"}}
{"id": "h20", "message": "Do you deliver to Portugal, and how much does it cost?", "expect": {"category": "delivery", "urgency": "low"}}
{"id": "h21", "message": "I bought the wrong book by mistake. It hasn't been dispatched yet. Can you cancel it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h22", "message": "My payment failed three times and now the order has disappeared from my account.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "h23", "message": "The ebook download link says it has expired.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h24", "message": "A book I pre-ordered in March still hasn't been dispatched and the release date was last month.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "h25", "message": "I've been charged in euros instead of pounds.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h26", "message": "Can I reserve a book in the shop and pay when I collect it?", "expect": {"category": "other", "urgency": "low"}}
{"id": "h27", "message": "Someone used my gift card balance before I did.", "expect": {"category": "account", "urgency": "high"}}
{"id": "h28", "message": "The reading group discount wasn't applied to my order.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h29", "message": "I sent the book back with the return label but the label had someone else's address.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h30", "message": "Thank you for sorting out the refund so quickly last week.", "expect": {"category": "other", "urgency": "low"}}
```

Join the two sets into one file, which later lessons use too, and run both prompts over all
seventy:

```
ana@lab:~/triage$ cat cases/dev.jsonl cases/holdout.jsonl > cases/all.jsonl
ana@lab:~/triage$ wc -l cases/all.jsonl
70 cases/all.jsonl
ana@lab:~/triage$ pl run prompts/v8-rules.txt cases/all.jsonl --out runs/rules.jsonl
70 calls, prompt 65da61bb, llama3.2:3b, written to runs/rules.jsonl
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/all.jsonl --out runs/guide.jsonl
70 calls, prompt d0591569, llama3.2:3b, written to runs/guide.jsonl
ana@lab:~/triage$ pl check runs/rules.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     52    18
urgency      27    43
all          27    43
ana@lab:~/triage$ pl check runs/guide.jsonl
check      pass  fail
json         68     2
fields       68     2
labels       68     2
category     54    16
urgency      31    39
all          31    39
```

The rules pass 27 and the guide 31. Before reading anything into four messages, compare them case by
case:

```
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl
runs/rules.jsonl         passes 27/70
runs/guide.jsonl         passes 31/70
fixed 6, broken 2
broken: t22 h24
sign test on the 8 that changed: p = 0.289
```

Eight messages changed, six one way and two the other. A fair coin splits eight tosses at least
that unevenly about three times in ten (p = 0.289). **That is not a difference this test set can
detect.** The guide may be better; seventy messages cannot say so.

## What the totals hide

The two prompts are not the same prompt, though. Compare the categories, read without the
verdicts, and eleven differ:

```
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl --answers
70 cases, same answer 59, different answer 11
  t22    billing -> other
  t25    delivery -> account
  t26    account -> returns
  t35    account -> other
  t38    delivery -> None
  t39    delivery -> account
  t40    account -> other
  h19    delivery -> other
  h24    delivery -> None
  h26    account -> other
  h28    billing -> returns
```

And the urgency failures point in opposite directions. Under the rules, 15 messages came back with
an urgency lower than the person's and 10 higher; under the guide, 8 lower and 15 higher. Count them
in the two lists:

```
ana@lab:~/triage$ pl check runs/rules.jsonl --failures
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     52    18
urgency      27    43
all          27    43

t02    urgency   low, expected normal
t03    urgency   low, expected normal
t04    urgency   low, expected high
t07    urgency   low, expected normal
t08    urgency   high, expected normal
t09    urgency   high, expected normal
t12    urgency   low, expected high
t16    urgency   high, expected normal
t18    urgency   low, expected normal
t19    category  delivery, expected account
t24    urgency   low, expected normal
t25    category  delivery, expected account
t26    category  account, expected billing
t32    urgency   low, expected normal
t33    urgency   low, expected normal
t35    category  account, expected other
t37    urgency   low, expected normal
t38    category  delivery, expected returns
t39    category  delivery, expected account
t40    category  account, expected other
h01    category  returns, expected billing
h02    urgency   low, expected normal
h04    urgency   low, expected normal
h05    urgency   high, expected low
h06    category  returns, expected delivery
h07    category  account, expected billing
h08    urgency   high, expected normal
h11    category  delivery, expected account
h12    category  returns, expected billing
h13    urgency   low, expected normal
h15    urgency   low, expected normal
h16    urgency   low, expected normal
h17    urgency   high, expected normal
h18    urgency   high, expected normal
h19    category  delivery, expected account
h21    category  returns, expected delivery
h23    category  delivery, expected returns
h25    urgency   high, expected normal
h26    category  account, expected other
h27    category  billing, expected account
h28    urgency   high, expected normal
h29    urgency   high, expected normal
h30    category  returns, expected other
ana@lab:~/triage$ pl check runs/guide.jsonl --failures
check      pass  fail
json         68     2
fields       68     2
labels       68     2
category     54    16
urgency      31    39
all          31    39

t02    urgency   high, expected normal
t03    urgency   low, expected normal
t07    urgency   high, expected normal
t08    urgency   high, expected normal
t09    urgency   high, expected normal
t16    urgency   high, expected normal
t18    urgency   high, expected normal
t19    category  delivery, expected account
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    urgency   low, expected normal
t26    category  returns, expected billing
t32    urgency   high, expected normal
t33    urgency   low, expected normal
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    urgency   low, expected normal
h01    category  returns, expected billing
h02    urgency   high, expected normal
h04    urgency   low, expected normal
h06    category  returns, expected delivery
h07    category  account, expected billing
h08    urgency   high, expected normal
h11    category  delivery, expected account
h12    category  returns, expected billing
h13    urgency   low, expected normal
h15    urgency   low, expected normal
h16    urgency   low, expected normal
h17    urgency   high, expected normal
h18    urgency   high, expected normal
h19    category  other, expected account
h21    category  returns, expected delivery
h23    category  delivery, expected returns
h24    json      not a JSON object
h25    urgency   high, expected normal
h27    category  billing, expected account
h28    category  returns, expected billing
h29    urgency   high, expected normal
h30    category  returns, expected other
```

Line 12 of the rules, *NEVER mark a question as high urgency*, pulls answers down: `t04`, somebody
who cannot log in, and `t12`, a parcel marked delivered that never came, both went to `low` where a
person said `high`. The guide's *a customer out of pocket ... is high however politely they ask*
pulls them up: `t02`, `t07` and a run of others that a person called `normal` came back `high`.
**Each prompt has a direction it leans in**, and the total of each is the sum of a different set of
mistakes. Two prompts can score within four of each other and be wrong about different customers.

## The case two rules fought over

```
ana@lab:~/triage$ pl show runs/rules.jsonl t22
│ {"category": "billing", "urgency": "low", "summary": "Inquiring about payment options for an order."}
stop: stop, tokens in 233, out 28, 3.5 s
ana@lab:~/triage$ pl show runs/guide.jsonl t22
│ {"category": "other", "urgency": "low", "summary": "Customer wants to know if they can use a gift card and a credit card together on an order."}
stop: stop, tokens in 287, out 39, 4.9 s
```

`t22` came back right under the rules, `billing` and `low`, and wrong under the guide, which called
it `other`. So on the very message the principle was written to settle, the rule list won. That is
one message, and it is the kind of result to report rather than explain away: the argument for the
guide made a prediction about `t22`, and on this model the prediction failed.

## What the measurement is for

So the honest report of this section is **no difference detected on seventy cases**, with two notes
attached: the prompts err in opposite directions on urgency, and the guide lost the case it was
argued from. Not *the guide is better*, and not *the guide does not work*. A claim that explanations
beat rules by some percentage, made without a run like this one, is a claim about somebody else's
model and somebody else's test set, and on yours it is a hypothesis until you run it. Lesson 11 is
about building a test set big enough, and pointed enough, to detect the differences you care about.
