---
title: When structure pays
version: 1
---

`prompt-engineering` introduced structured output in its lesson 18 and schemas in lesson 19. This
lesson takes them again on purpose, with the question this course asks of every technique: **how
often does the structure actually arrive, and what does the program reading it do when it does
not?**

The idea that has to go first is that JSON is the careful, professional way to ask for an
answer, and prose the sloppy one. **Structure is for a reader that is a program.** The same
message, sorted by the bare prompt and by the one that asks for JSON:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, written to runs/v1.jsonl
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl show runs/v1.jsonl t17
│ Type: Shipping
│ Priority: urgent
│ Summary: Their order was dispatched ten days ago and still hasn't arrived.
stop: end, tokens in 45, out 22
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {
│   "category": "delivery",
│   "urgency": "high",
│   "summary": "Their order was dispatched ten days ago and still hasn't arrived."
│ }
stop: end, tokens in 87, out 38
```

A person on the support team reads the first reply in a second and knows what to do. `Shipping`
and `urgent` are not the shop's words, and a person does not care. A program routing the message to
the warehouse queue cares about nothing else: it needs a field it can find by name and a value it
can compare with `delivery`. **If a person reads the answer, the bare prompt was finished.** Lesson
1 failed it on every check because the reader in this course is a program, and the checks are that
program's needs written down.

## What structure costs

Asking for JSON is more instructions, and JSON is more output, because the quotes, braces and key
names are tokens the model writes:

```
ana@lab:~/triage$ pl tokens prompts/v1-bare.txt
27 tokens, 20 words, 114 characters
ana@lab:~/triage$ pl tokens prompts/v2-json.txt
69 tokens, 46 words, 295 characters
ana@lab:~/triage$ pl latency runs/v1.jsonl
calls 40
p50 840 ms   p95 1015 ms   max 1072 ms
output tokens: mean 22.7, max 36
ana@lab:~/triage$ pl latency runs/v2.jsonl
calls 40
p50 1186 ms   p95 1397 ms   max 1468 ms
output tokens: mean 39.9, max 50
```

The prompt went from 27 tokens to 69, and the mean reply from 22.7 tokens to 39.9. The median call
took 1,186 ms instead of 840, in the lab's computed latencies, because written tokens are the slow
ones. For a router that is a fair price. For a note a person reads, it is paid for nothing.

## What structure constrains

A field holds what the format lets it hold. The summary here is one sentence because the format
says so, and a customer with two problems gets one of them summarised. Prose has room for *"mostly
billing, but they also mention a damaged book"*; a `category` field has room for one word from a
list of five. **Every field you add is a decision taken away from the model.** That is exactly what
you want for a value a program branches on, and exactly what you do not want for something a person
was going to read and judge.

So the rule is about the reader. Ask for structure when a program consumes the answer, and ask for
as much as that program needs, which in this course is two labels and a sentence.
