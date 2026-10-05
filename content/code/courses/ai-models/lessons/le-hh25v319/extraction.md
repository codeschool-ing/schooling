---
title: A second task, a different winner
version: 1
---

Lesson 4 section 04 said one model can pass one task and fail another, and that is why each task is
evaluated on its own. The extraction task, on the same forty e-mails, with `prompts/extract.txt`:

```
ana@desk:~/desk$ python lab/evalkit.py run extract runs/extract.jsonl 0 standin-large standin-small standin-local
```

```
ana@desk:~/desk$ python lab/evalkit.py report runs/extract.jsonl
model           strict   loose     loose, 95%  p50 s  $ per 1k
standin-large    40/40   40/40     91% to 100%   0.87    0.2946
standin-small    35/40   39/40     87% to 100%   0.27    0.0256
standin-local    37/40   37/40     80% to  97%   1.40    0.0000
```

standin-large gets all forty. standin-small finds the right order number 39 times and **writes valid
JSON only 35 times**; standin-local gets 37 right, all of them clean. On sorting, standin-small beat
standin-local on loose score. On extraction, the program that calls `json.loads` would rather have
standin-local's 37.

The failures say why:

```
ana@desk:~/desk$ python lab/evalkit.py errors runs/extract.jsonl
standin-small  c03 loose ok  expected LB-20452        got 'Here is the JSON you asked for: {"order": "LB-20452"}'
standin-small  c11 loose ok  expected LB-20329        got 'Here is the JSON you asked for: {"order": "LB-20329"}'
standin-small  c18 loose ok  expected LB-20493        got 'Here is the JSON you asked for: {"order": "LB-20493"}'
standin-small  c27 loose ok  expected LB-20497        got 'Here is the JSON you asked for: {"order": "LB-20497"}'
standin-small  c37 wrong     expected None            got '{"order": "LB-unknown"}'
standin-local  c10 wrong     expected LB-20377        got '{"order": "20377"}'
standin-local  c21 wrong     expected LB-20440        got '{"order": "LB-20404"}'
standin-local  c40 wrong     expected LB-20474        got '{"order": null}'
```

**standin-small wraps the JSON in a sentence** four times. The number inside is right, and the
program crashes. That is a format failure, and it has a format fix: a structured-output feature
that constrains the reply to a schema (lesson 4's `S` column), or a tidying step that extracts the
`{...}`. With either, standin-small's strict score would become its loose one.

**c37 is the interesting one.** It asks to change the address on a standing order and names no
order. The right answer is `null`; standin-small invented `LB-unknown`. A program that looks that up
finds nothing, which is the safe way to fail, but an invented value that happened to look like a real
order number would not be safe at all. **Cases whose right answer is "there is none" are where
invention shows**, and section 03 kept fifteen of them for this reason.

**standin-local's three are content errors**: `20377` without the prefix, `LB-20404` for an order
written `LB-20440`, and `null` for an e-mail that names its order plainly. No format feature fixes
those. The transposed digits are the dangerous kind: valid JSON, a plausible number, the wrong
customer.

## Per task, then

| | sorting, loose | extraction, strict | dangerous extraction errors |
|---|---|---|---|
| standin-large | 38 | 40 | 0 |
| standin-small | 34 | 35 | 0, if invented placeholders are caught |
| standin-local | 32 | 37 | 1, a transposed order number |

The question for each row is no longer "which is best" but **"which mistakes can the shop live
with, at what price"**. Section 10 answers it.
