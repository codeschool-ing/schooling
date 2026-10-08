---
title: Tone, by rules
version: 2
---

Correctness and format have answers somebody wrote down. Tone does not, and the usual first move is
to give up on measuring it. The other move is to write down the parts of it that **can** be said as
rules. Five rules for a reply to a customer of Folio, as a file the program reads: at most one
exclamation mark, at most eighty words, none of the phrases the shop never uses, no promise from a
short list of patterns, and some acknowledgement of the customer. Save them as `checks/tone.json`:

```json
{
  "max_exclamations": 1,
  "max_words": 80,
  "banned": [
    "\\bdear (sir|madam)\\b",
    "\\bvalued customer\\b",
    "\\bas per\\b"
  ],
  "promises": [
    "\\bwill (process|issue|send) (a |your )?(full )?refund",
    "\\btoday\\b",
    "\\btomorrow\\b",
    "\\bimmediately\\b",
    "\\bguarantee",
    "\\bwithin (the next )?\\d"
  ],
  "acknowledge": [
    "\\bsorry\\b",
    "\\bthank",
    "\\bapologi"
  ]
}
```

Each entry under `banned`, `promises` and `acknowledge` is a regular expression, written the way
lesson 10's `scan.py` wrote its patterns. This program holds each reply to them and says which
rules it breaks. Save it as `tone.py`:

```python
"""tone: hold each reply to the rules in checks/tone.json, and say which it breaks."""
import json
import re
import sys

from pl import read_jsonl

rules = json.load(open("checks/tone.json", encoding="utf-8"))


def broken(text):
    found = []
    if text.count("!") > rules["max_exclamations"]:
        found.append("exclamations")
    if len(text.split()) > rules["max_words"]:
        found.append("length")
    for name in ("banned", "promises"):
        if any(re.search(p, text, re.I) for p in rules[name]):
            found.append(name)
    if not any(re.search(p, text, re.I) for p in rules["acknowledge"]):
        found.append("acknowledge")
    return found


rows = read_jsonl(sys.argv[1])
counts = {}
for r in rows:
    found = broken(r["text"])
    for name in found:
        counts[name] = counts.get(name, 0) + 1
    print("%-4s %-4s %s" % (r["case"], "FAIL" if found else "ok", ", ".join(found)))
print()
for name in ("exclamations", "length", "banned", "promises", "acknowledge"):
    print("%-13s %d of %d fail" % (name, counts.get(name, 0), len(rows)))
```

Lesson 4's `reply.txt` writes replies, so here are forty of `llama3.2:3b`'s, one for each dev
message:

```
ana@lab:~/triage$ pl run prompts/reply.txt cases/dev.jsonl --out runs/replies.jsonl --var shop=Folio --var language=English
40 calls, prompt 13304d8d, llama3.2:3b, written to runs/replies.jsonl
ana@lab:~/triage$ python3 tone.py runs/replies.jsonl
t01  FAIL promises
t02  FAIL promises
t03  ok   
t04  FAIL promises
t05  ok   
t06  FAIL acknowledge
t07  FAIL promises
t08  ok   
t09  FAIL promises, acknowledge
t10  FAIL exclamations, acknowledge
t11  ok   
t12  FAIL promises
t13  FAIL promises, acknowledge
t14  ok   
t15  FAIL exclamations
t16  ok   
t17  ok   
t18  FAIL promises
t19  FAIL promises
t20  FAIL acknowledge
t21  FAIL promises
t22  FAIL acknowledge
t23  FAIL promises
t24  ok   
t25  FAIL promises
t26  FAIL promises
t27  FAIL promises, acknowledge
t28  ok   
t29  ok   
t30  FAIL acknowledge
t31  ok   
t32  FAIL promises
t33  FAIL promises
t34  FAIL acknowledge
t35  ok   
t36  FAIL promises
t37  FAIL promises
t38  FAIL promises
t39  ok   
t40  ok   

exclamations  2 of 40 fail
length        0 of 40 fail
banned        0 of 40 fail
promises      19 of 40 fail
acknowledge   9 of 40 fail
```

Five rules, each a unit test in the sense of lesson 11. Fourteen of the forty replies pass every
rule. Nineteen break `promises` and nine `acknowledge`; none is too long and none uses a banned
phrase.

## What a rule sees

**A rule catches exactly what it names**, and that cuts both ways:

```
ana@lab:~/triage$ pl show runs/replies.jsonl t11
│ "Dear [Customer],
│
│ We're sorry to hear that your card was declined, but the payment still went through. We're investigating this issue and will be in touch with you shortly to discuss further. Please allow 2-3 working days for our team to review the transaction. We'll be in touch to resolve this matter and ensure a smooth shopping experience for you.
│
│ Best regards, Folio Team"
stop: stop, tokens in 92, out 82, 9.9 s
ana@lab:~/triage$ pl show runs/replies.jsonl t33
│ "Sorry to hear that you received someone else's order. Please contact our customer service team immediately so we can assist you in resolving the issue. We will guide you through the next steps to ensure the correct order is sent to you. You can reach us via phone or email, and we will be happy to help. Thank you for bringing this to our attention."
stop: stop, tokens in 94, out 74, 8.6 s
ana@lab:~/triage$ pl show runs/replies.jsonl t06
│ "Dear [Customer],
│
│ We've located your invoice for last month's order. You can find it in the 'Order History' section of your account on our website. Please log in to your account and navigate to this section. If you're having trouble finding it, feel free to contact us and we'll be happy to assist you.
│
│ Best regards, Folio Team"
stop: stop, tokens in 95, out 76, 9.2 s
```

`t11` passes `promises`, and it asks the customer to *allow 2-3 working days*: a date, in a reply
to somebody whose card was charged after it was declined. The rule names *within* a number of days
and this reply wrote *allow* one. `t33` fails `promises` for *immediately*, and the sentence is
*please contact our customer service team immediately*: it asks something of the customer and
promises nothing. `t06` fails `acknowledge` because it neither thanks nor apologises, and it is a
plain, correct answer to a plain question about where an invoice is.

So three replies show both errors of a rule: a promise it missed, and two fine sentences it flagged.
**A rule is a proxy for a judgement**, and its errors are where the judgement and the proxy part
ways. That is not a reason to drop the rules. They are free, they give the same verdict every time,
and on this model the `promises` rule is the most useful line in the file.

## What no rule here sees

`t06` starts *Dear [Customer]*. So do others:

```
ana@lab:~/triage$ grep -c "\[Customer\]" runs/replies.jsonl
11
```

Eleven replies of forty address the customer with a placeholder in square brackets, and every rule
passed them, because nobody thought to write that one. Now somebody has, and it belongs in the file.
None of the five asks either whether the reply is true, whether it answers the question, or whether
it sounds like someone who cares. Tone beyond the rules needs somebody to read a sample, or a model
asked to judge, and lesson 13 measures how far a model judge can be trusted with that.
