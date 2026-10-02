---
title: What an example fixes
version: 1
---

The first prompt anybody writes describes the task and stops. It is a reasonable sentence, and
**it leaves every decision about the answer's shape to the model**:

```
ana@lab:~/triage$ cat prompts/v1-bare.txt
Sort this customer message for the support team. Say what it is about and how urgent it is.

Message: {{message}}
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, written to runs/v1.jsonl
ana@lab:~/triage$ pl show runs/v1.jsonl t01
│ Sure! Here is the triage for this message.
│
│ Type: Payment
│ Priority: urgent
│ Summary: They were charged twice for order 4471.
stop: end, tokens in 36, out 26
ana@lab:~/triage$ pl check runs/v1.jsonl
check      pass  fail
json          0    40
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
```

`pl show` prints a reply behind a bar, so you can see exactly where it starts and ends. The reply
to `t01` is right, and a person would read it happily. A program cannot: it is not JSON, the
fields are called `Type` and `Priority`, and the values are the model's own words for the
categories, `Payment` and `urgent`. **None of that is a mistake by the model.** The prompt never
said JSON, never named a field and never listed a label, so the model filled each gap with
something plausible.

## Describing the answer

The second version says all three things in words:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl check runs/v2.jsonl
check      pass  fail
json         27    13
fields       27    13
labels       27    13
category     27    13
urgency      24    16
all          24    16
ana@lab:~/triage$ pl show runs/v2.jsonl t03
│ ```json
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "The book arrived with the cover torn."
│ }
│ ```
stop: end, tokens in 81, out 39
ana@lab:~/triage$ pl show runs/v2.jsonl t06
│ Here is the JSON you asked for:
│
│ {
│   "category": "billing",
│   "urgency": "low",
│   "summary": "Asks: where can I find a copy of my invoice for last month's order?"
│ }
stop: end, tokens in 80, out 50
```

Twenty-four of forty now pass everything. The thirteen that fail `json` have the right content in
the wrong wrapping: `t03` is inside a Markdown code fence, `t06` has a sentence in front of it.
Both are habits a description does not reach, because the description never said what may come
**around** the JSON.

## Showing it

The third version keeps the description and adds three examples, each a message and the exact
answer for it:

```
ana@lab:~/triage$ cat prompts/v3-examples.txt
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
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     39     1
urgency      36     4
all          36     4

t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
t37    category  billing, expected delivery
```

**Every reply parses.** The four that still fail are arguments about a label, which is a
different problem with different fixes, and lesson 12 is where they are measured properly.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Forty replies to each of three prompts, sorted by the first check they failed. The bare prompt: all 40 fail on format. Asking for JSON: 13 fail on format, 3 on a label, 24 pass. Three examples: none fail on format, 4 on a label, 36 pass.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">40 replies, by the first check each one failed</text><text x=\"158\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bare prompt</text><rect x=\"170\" y=\"56\" width=\"500.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"680.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"158\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">asks for JSON</text><rect x=\"170\" y=\"108\" width=\"162.5\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"332.5\" y=\"108\" width=\"37.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"370.0\" y=\"108\" width=\"300.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">24</text><text x=\"158\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">three examples</text><rect x=\"170.0\" y=\"160\" width=\"50.0\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"220.0\" y=\"160\" width=\"450.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">36</text><rect x=\"170\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"188\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">format</text><rect x=\"340\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"358\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">wrong label</text><rect x=\"510\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"528\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passes all</text></svg>", "caption": "The same forty messages through three prompts. Asking for JSON fixed most of the format; the examples fixed the rest of it, and the four failures left are disagreements about a label."}
```

## Was that luck?

Thirty-six against twenty-four looks decisive, but a count can move for reasons that have nothing
to do with the change. `pl compare` lines the two runs up message by message:

```
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 24/40
runs/v3.jsonl            passes 36/40
fixed 13, broken 1, still passing 23, still failing 3
broken: t37
sign test on the 14 that changed: p = 0.002
```

Only the fourteen messages whose result changed carry any evidence, and thirteen went one way.
The **sign test** asks how often a fair coin would split fourteen tosses at least that unevenly,
and the answer is two times in a thousand. Lesson 7 uses the same test on a change that turns out
to be noise, which is the case it is for.

The one it broke, `t37`, is the subject of the next section.

## Why it works

In the stand-in the mechanism is written down: with an example in the prompt, it **copies the
shape of the first example's answer** and fills in its own values. For real models the effect is
one of the oldest results in the field. The paper that introduced GPT-3, *Language Models are
Few-Shot Learners* (Brown and others, 2020), is named after it: a handful of demonstrations in the
prompt raised the model's accuracy on many tasks without changing a single weight. A later study,
*Rethinking the Role of Demonstrations* (Min and others, 2022), found that much of the gain came
from the examples showing the format and the set of labels, and survived even when the labels in
the examples were wrong.

That is the useful way to think of an example: **a description says what you want; an example is
an instance of it**, and an instance leaves less to fill in.
