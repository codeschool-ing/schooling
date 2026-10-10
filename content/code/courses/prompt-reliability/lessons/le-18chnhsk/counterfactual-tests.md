---
title: Counterfactual tests
version: 2
---

The biases so far came from the prompt. Some come from the message: a name, a dialect, a country, a
way of writing that tells the model something about the customer that has nothing to do with the
problem. **A counterfactual test changes only that detail** and checks that nothing else moves.

Here are eight messages, each signed by the same customer. Save them as `cases/names-a.jsonl`:

```
{"id": "n01", "message": "Maria Souza here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "n02", "message": "Hi, it's Maria Souza. My parcel still hasn't arrived after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "n03", "message": "Maria Souza again: the book came with a torn cover, can I return it?", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "n04", "message": "This is Maria Souza. I can't log in since yesterday.", "expect": {"category": "account", "urgency": "high"}}
{"id": "n05", "message": "My name is Maria Souza and I'd like to know if you have signed copies.", "expect": {"category": "other", "urgency": "low"}}
{"id": "n06", "message": "Maria Souza writing. Where can I find my invoice?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "n07", "message": "Hello, Maria Souza here. The courier lost my order.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "n08", "message": "Maria Souza speaking: please delete my account.", "expect": {"category": "account", "urgency": "normal"}}
```

The second set is made from the first with one substitution, so the two can never differ in
anything else:

```
ana@lab:~/triage$ sed 's/Maria Souza/John Smith/' cases/names-a.jsonl > cases/names-b.jsonl
ana@lab:~/triage$ head -n 1 cases/names-a.jsonl cases/names-b.jsonl
==> cases/names-a.jsonl <==
{"id": "n01", "message": "Maria Souza here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}

==> cases/names-b.jsonl <==
{"id": "n01", "message": "John Smith here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}
```

Run the triage prompt over both:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-a.jsonl --out runs/names-a.jsonl
8 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/names-a.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-b.jsonl --out runs/names-b.jsonl
8 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/names-b.jsonl
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl --answers
8 cases, same answer 6, different answer 2
  n02    returns -> delivery
  n07    returns -> delivery
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl
runs/names-a.jsonl       passes 3/8
runs/names-b.jsonl       passes 5/8
fixed 2, broken 0
sign test on the 2 that changed: p = 0.500
```

**Two answers changed when only the name did.** Here they are:

```
ana@lab:~/triage$ pl show runs/names-a.jsonl n02
│ {"category": "returns", "urgency": "high", "summary": "Customer is reporting a delayed parcel"}
stop: stop, tokens in 152, out 25, 2.6 s
ana@lab:~/triage$ pl show runs/names-b.jsonl n02
│ {"category": "delivery", "urgency": "high", "summary": "Customer is concerned about delayed parcel arrival"}
stop: stop, tokens in 151, out 26, 2.8 s
ana@lab:~/triage$ pl show runs/names-a.jsonl n07
│ {"category": "returns", "urgency": "high", "summary": "Customer reports lost order"}
stop: stop, tokens in 147, out 23, 2.4 s
ana@lab:~/triage$ pl show runs/names-b.jsonl n07
│ {"category": "delivery", "urgency": "high", "summary": "Customer reports lost order"}
stop: stop, tokens in 146, out 23, 2.3 s
```

`n02`, a parcel a week late, and `n07`, an order the courier lost: `returns` when Maria Souza wrote,
`delivery` when John Smith did, with the same urgency and nearly the same summary. Both are
delivery, so the change fixed two.

Two in eight does not show that the model treats one name worse than the other. Lesson 8 showed
replies at temperature 0 flipping on a difference far smaller than a name, and a near tie between
`returns` and `delivery` can fall either way on any change at all. **What it shows is that the name
reached the label**, and that is the thing a counterfactual test exists to catch. To say more you
need many pairs and many names, compared with the sign test, and the rule for reading them is the
one lesson 7 gave: report the moves, not only the totals.

## Building them

- **Change one attribute and nothing else.** A `sed` is the safest editor, because it cannot
  rephrase anything by accident.
- **Use attributes the task must ignore**: names, places, polite or blunt wording, spelling. A
  message about a lost parcel is about a lost parcel whoever sent it.
- **Keep the pairs in the test sets**, and run them through the gate with everything else. A bias
  that a later prompt reintroduces should fail a check, not wait for a customer to notice.
