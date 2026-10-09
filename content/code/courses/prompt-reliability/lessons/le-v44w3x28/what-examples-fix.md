---
title: What an example fixes
version: 2
---

The first prompt anybody writes describes the task and stops. It is a reasonable sentence, and
**it leaves every decision about the answer's shape to the model**. Save it as
`prompts/v1-bare.txt`:

```
Sort this customer message for the support team. Say what it is about and how urgent it is.

Message: {{message}}
```

Then run it over the forty messages and look at two of the replies:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, llama3.2:3b, written to runs/v1.jsonl
```
```
ana@lab:~/triage$ pl show runs/v1.jsonl t01
│ Here is the sorted customer message:
│
│ **Message:** I was charged twice for order 4471. Please refund the second payment.
│
│ **Category:** Refund Request
│
│ **Urgency:** Medium
│
│ **Reason:** The customer is requesting a refund for a duplicate payment, which is a relatively straightforward issue. However, it's not an emergency situation, and the customer is not experiencing any immediate financial harm. A timely response to resolve the issue would be appreciated, but it's not critical.
stop: stop, tokens in 63, out 99, 34.8 s
ana@lab:~/triage$ pl show runs/v1.jsonl t02
│ Here is the sorted customer message:
│
│ **Message:** My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.
│
│ **Category:** Delivery Issue
│
│ **Urgency:** Medium
│
│ **Reason:** The customer is concerned about the delayed delivery of their parcel, which was expected to arrive on Monday. The tracking information has not updated since Friday, indicating a potential issue with the delivery.
│
│ **Action Required:** The support team should investigate the status of the parcel, check for any updates or notifications from the courier, and provide a resolution or estimated delivery date to the customer.
stop: stop, tokens in 64, out 118, 12.7 s
ana@lab:~/triage$ pl check runs/v1.jsonl
check      pass  fail
json          0    40
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
```

`pl show` prints a reply behind a bar, so you can see exactly where it starts and ends. Both
replies are sensible, and a person would read them happily. A program cannot: they are not JSON,
the labels are the model's own words, *Refund Request* and *Delivery Issue*, the urgency is
*Medium*, which is not on Folio's list, and the second reply added an *Action Required* nobody asked
for. **None of that is a mistake by the model.** The prompt never said JSON, never named a field and
never listed a label, so the model filled each gap with something plausible.

Look at the last number on each reply, too. The first took 34.8 seconds, because it was the first
call after Ollama started and most of that was loading the model into memory. The second took
12.7, and it had no model to load: it was 118 tokens long, and a model on a processor writes
them one at a time. **A reply nobody asked for is also a reply you wait for.**

## Describing the answer

The second version says all three things in words. Save it as `prompts/v2-json.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Message: {{message}}
```

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl check runs/v2.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      22    18
all          22    18

t02    urgency   high, expected normal
t06    category  account, expected billing
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t16    urgency   high, expected normal
t18    urgency   high, expected normal
t19    category  delivery, expected account
t22    category  other, expected billing
t24    urgency   low, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t31    category  returns, expected billing
t32    urgency   high, expected normal
t33    urgency   low, expected normal
t36    category  account, expected billing
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    category  delivery, expected account
ana@lab:~/triage$ pl show runs/v2.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 103, out 22, 2.2 s
```

Thirty-nine of forty replies now parse, and twenty-two pass everything. **The format was the easy
part.** What is left is mostly about labels, and it has a pattern: seven of the eighteen failures
are a message a person called `normal` that the model called `high`. Asked how urgent something
is, with no idea of what the shop means by each word, it leans towards urgent.

The one reply that did not parse is worth a look. The summary of `t38`, a customer whose ebook
*won't* open, stops at *won* and the object closes twice. The model wrote the apostrophe of *won't*
and lost its place. That is not a habit a description can reach: the description never said what to
do with an apostrophe, and nothing could.

## Showing it

The third version keeps the description and adds three examples, each a message and the exact
answer for it. Save it as `prompts/v3-examples.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

<example>
Message: I paid for express delivery but the order came by normal post.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back."}
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
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     35     5
urgency      28    12
all          28    12

t01    urgency   normal, expected high
t02    urgency   high, expected normal
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t37    json      not a JSON object
t39    urgency   low, expected normal
```

Twenty-eight now pass. Two of the urgency inflations are gone, `t16` and `t18`, and so are four
category mistakes, and `t38` parses, though `t37`, which failed on urgency before, now does not
parse at all. The examples show what *normal* means here: a damaged book and an express charge that
was not honoured are both `normal`, and neither is an emergency. Lesson 12 measures the urgency
failures that are left properly.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Forty replies to each of three prompts, sorted by the first check they failed. The bare prompt: all 40 fail on format. Asking for JSON: 1 fails on format, 17 on a label, 22 pass. Three examples: 1 fails on format, 11 on a label, 28 pass.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">40 replies, by the first check each one failed</text><text x=\"158\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bare prompt</text><rect x=\"170.0\" y=\"56\" width=\"500.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"680.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"158\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">asks for JSON</text><rect x=\"170.0\" y=\"108\" width=\"12.5\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"182.5\" y=\"108\" width=\"212.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"395.0\" y=\"108\" width=\"275.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">22</text><text x=\"158\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">three examples</text><rect x=\"170.0\" y=\"160\" width=\"12.5\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"182.5\" y=\"160\" width=\"137.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"320.0\" y=\"160\" width=\"350.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">28</text><rect x=\"170\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"188\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">format</text><rect x=\"340\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"358\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">wrong label</text><rect x=\"510\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"528\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passes all</text></svg>", "caption": "The same forty messages through three prompts, on llama3.2:3b. Asking for JSON fixed the format; what was left was mostly labels, and the examples fixed some of those."}
```

## Was that luck?

Twenty-eight against twenty-two looks like progress, but a count can move for reasons that have
nothing to do with the change. `pl compare` lines the two runs up message by message:

```
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 22/40
runs/v3.jsonl            passes 28/40
fixed 7, broken 1
broken: t01
sign test on the 8 that changed: p = 0.070
```

Only the eight messages whose result changed carry any evidence, and seven went one way. The **sign
test** asks how often a fair coin would split eight tosses at least that unevenly, and the answer is
seven times in a hundred. **That is suggestive, and it is not proof.** By the usual bar of five in a
hundred it is not even significant. With one message broken, as here, it takes eight fixed (p =
0.039) before the count alone clears five in a hundred. Lesson 7 is about reading that number, and
lesson 11 about building a test set big enough to need it less.

The one message the examples broke, `t01`, is the subject of the next section.

## Why it works

The effect is one of the oldest results in the field. The paper that introduced GPT-3, *Language
Models are Few-Shot Learners* (Brown and others, 2020), is named after it: a handful of
demonstrations in the prompt raised the model's accuracy on many tasks without changing a single
weight. A later study, *Rethinking the Role of Demonstrations* (Min and others, 2022), found that
much of the gain came from the examples showing the format and the set of labels. That part of the
gain survived even when the labels in the examples were wrong.

That is the useful way to think of an example: **a description says what you want; an example is
an instance of it**, and an instance leaves less to fill in.
