---
title: Asking it to check
version: 2
---

Self-evaluation is the step that sends a model's answer back to it with a question: is this right?
It sounds like a second opinion. **It is the same opinion asked for twice**, and what it can add
depends entirely on what differs between the first reading and the second.

This review prompt shows the model the customer's message and the answer it gave, and asks for a
verdict. Save it as `prompts/review.txt`:

```
You check answers given by a triage assistant for Folio, an online bookshop.

<message>
{{message|xml}}
</message>

<answer>
{{answer|xml}}
</answer>

Is the answer valid JSON with the right category? Reply OK, or WRONG and the reason.
```

Both values go through `|xml`, as every outside value has since lesson 4: the answer is text the
model wrote, and the message is text a customer wrote. The prompt asks about the format and the
category, and not about the urgency, so a reply counts as wrong here when it fails `json`, `fields`,
`labels` or `category`.

## Measuring a check

A check is a classifier like the triage prompt, and it is measured the same way: against labels a
person gave. This program sends every reply in a run through `review.txt`, one more call per reply,
and holds each verdict against what `pl` already knows about the reply. It prints every reply that
was flagged or was really wrong, with the start of what the reviewer said, and then a table. Save it
as `selfcheck.py`:

```python
"""selfcheck: ask the model to check each triage answer with prompts/review.txt,
and measure the check against the person's labels."""
import sys

from pl import DEFAULTS, call, judge, read_jsonl, read_prompt, render

params, template = read_prompt("prompts/review.txt")
params = {**DEFAULTS, **params}
rows = read_jsonl(sys.argv[1])
cases = {c["id"]: c for c in read_jsonl(rows[0]["cases"])}
table = {(f, w): 0 for f in (True, False) for w in (True, False)}
for row in rows:
    case = cases[row["case"]]
    check, _ = judge(row, case["expect"])
    wrong = check in ("json", "fields", "labels", "category")
    said = call(render(template, {"message": case["message"], "answer": row["text"]}),
                params)["text"].strip()
    flagged = not said.upper().startswith("OK")
    table[flagged, wrong] += 1
    if flagged or wrong:
        tag = row["case"] + ("#%d" % row["sample"] if row["sample"] else "")
        print("%-6s %-5s %s" % (tag, "wrong" if wrong else "right", " ".join(said.split())[:64]))
print("\n%15s %13s %13s" % ("", "really wrong", "really right"))
print("%-15s %13d %13d" % ("flagged", table[True, True], table[True, False]))
print("%-15s %13d %13d" % ("not flagged", table[False, True], table[False, False]))
flags, mistakes = table[True, True] + table[True, False], table[True, True] + table[False, True]
print("precision %.2f   recall %.2f" % (table[True, True] / flags if flags else 0,
                                         table[True, True] / mistakes if mistakes else 0))
```

`judge` is the function `pl check` uses, so *really wrong* means exactly what it means everywhere
else in the course. A verdict that does not start with `OK` is a flag. That is the same
measurement lesson 13 made of a model judging two replies, and it has the same reference point.
**A check is only as good as its agreement with the labels a person gave**, and the next section
reads that agreement as a table.
