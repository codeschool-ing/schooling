---
title: Counterfactual tests
version: 1
---

The three tests so far changed the prompt. The bias that matters most to a customer is in the
other place: **an answer that changes with something about the person** that should not matter to
it, such as a name, the way they write, or where they seem to be from. You cannot read that bias
off a prompt, because it is not in the prompt.

The test for it has a name, and a simple shape. Take messages, make a copy of each that differs
**only** in the attribute that must not matter, run both, and compare the answers. If the
attribute does not matter, nothing moves.

```
ana@lab:~/triage$ head -n 1 cases/names-a.jsonl cases/names-b.jsonl
==> cases/names-a.jsonl <==
{"id": "n01", "message": "Maria Souza here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}

==> cases/names-b.jsonl <==
{"id": "n01", "message": "John Smith here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}
```

`names-a` and `names-b` are the same eight messages, signed by Maria Souza in one file and by John
Smith in the other. Nothing else differs, and the labels a person gave them are the same in both.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-a.jsonl --out runs/names-a.jsonl
8 calls, prompt fbc4c9b1, written to runs/names-a.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-b.jsonl --out runs/names-b.jsonl
8 calls, prompt fbc4c9b1, written to runs/names-b.jsonl
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl --answers
8 cases, same answer 8, different answer 0
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl
runs/names-a.jsonl       passes 4/8
runs/names-b.jsonl       passes 4/8
fixed 0, broken 0, still passing 4, still failing 4
sign test on the 0 that changed: p = 1.000
```

No answer moved. The comparison of passes, which counts urgency as well as category, agrees:
nothing fixed, nothing broken.

## What that proves

**In this lab, nothing at all.** The stand-in sorts by keywords, and no name is a keyword, so it has
no way to treat Maria differently from John. The test came out clean because the stand-in cannot
fail it, and a test that cannot fail tells you nothing about the thing being tested.

On a real model the same eight pairs could come out differently, and you would not know until you
ran them. That is the point of the section: **the test is how you would find out**, and it is the
same three commands whatever the model is.

## One reply did move

Look closer at one pair:

```
ana@lab:~/triage$ pl show runs/names-a.jsonl n06
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "Maria Souza writing."
│ }
stop: end, tokens in 117, out 28
ana@lab:~/triage$ pl show runs/names-b.jsonl n06
│ Here is the JSON you asked for:
│
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "John Smith writing."
│ }
stop: end, tokens in 117, out 36
```

Same category, same urgency, and John's reply has a sentence in front of its JSON. The stand-in
rolls its formatting habits from the exact text it is given, so a different name is a different
roll. That is noise, and it happens to depend on the name.

It is the reason a counterfactual test needs a **noise floor**. Run the same file twice and compare;
whatever differs between those two runs differs for no reason at all, and a difference between
Maria and John only counts above it. In the stand-in at temperature 0 the floor is zero. On a real
model it is not guaranteed to be.

## Building a counterfactual set

- **Change one thing.** A `diff` of the two files should show the attribute and nothing else, as
  it would here.
- **Use more than two values.** Maria and John are one comparison; a bias against one group shows
  up only when the group is in the set.
- **Look for a direction, not only a count.** Two answers moving in opposite directions is noise.
  Six urgencies that are higher for one name than for the other is a finding.
- **Use enough pairs.** Eight is a demonstration. With few pairs, the sign test from lesson 7 says
  how little a small difference proves.

The answer a customer gets should depend on what they wrote, never on who they are. **A
counterfactual set is the only one of these tests that checks that directly**, and it costs one
extra copy of a file you already have.
