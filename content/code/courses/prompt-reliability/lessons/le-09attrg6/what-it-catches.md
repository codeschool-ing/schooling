---
title: What it catches
version: 1
---

Run the delimited, escaped prompt at temperature 0 and ask the stand-in to check every answer:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl selfcheck runs/v6.jsonl
t26  wrong  WRONG: the answer is not valid JSON
t37  right  WRONG: it could also be other
t39  wrong  WRONG: the answer is not valid JSON
h01  wrong  OK
h04  wrong  OK
h07  right  WRONG: it could also be account
h11  wrong  OK
h13  wrong  WRONG: it could also be billing
h14  wrong  OK
h15  wrong  WRONG: it could also be other
h16  wrong  WRONG: it could also be delivery
h19  wrong  WRONG: it could also be billing
h20  wrong  WRONG: it could also be billing
h26  wrong  OK
h27  wrong  OK
h28  wrong  WRONG: it could also be other
h30  right  WRONG: it could also be billing

               really wrong  really right
flagged                   8             3
not flagged               6            53
precision 0.73   recall 0.57
```

`pl selfcheck` lists every reply that was flagged or was wrong, then the table. Of seventy replies,
fourteen were really wrong. The check flagged eleven, and eight of those were among the fourteen.

Two numbers summarise the table. **Precision** asks how many flags were right: 8 of 11, 0.73.
**Recall** asks how many mistakes were flagged: 8 of 14, 0.57. A check with high precision and low
recall is quiet and trustworthy when it speaks; one with the opposite is loud and catches more.
Neither number means anything without the other.

## Reading the table

Two of the eight catches are `t26` and `t39`, replies that are not JSON. Any program could have
found those, and the last section of this lesson does.

The other six are label mistakes, and every one of them was caught the same way, with *it could
also be*. The reviewer doubted those answers because its two best labels were close. Look at what
it suggested instead, against what the person said:

```
ana@lab:~/triage$ grep -E '"(h13|h15|h16|h19|h20|h28)"' cases/all.jsonl | grep -o '"category": "[a-z]*"'
"category": "returns"
"category": "account"
"category": "returns"
"category": "account"
"category": "delivery"
"category": "billing"
```

Returns, account, returns, account, delivery, billing. The reviewer suggested billing, other,
delivery, billing, billing and other. **Not one of its six alternatives is the person's label.** It
knew the answer was shaky and did not know what it should be, which is a useful flag and a useless
correction.

## The misses

Six wrong answers came back OK. Here is one:

```
ana@lab:~/triage$ grep h27 cases/all.jsonl
{"id": "h27", "message": "Someone used my gift card balance before I did.", "expect": {"category": "account", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v6.jsonl h27
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "Someone used their gift card balance before they did."
│ }
stop: end, tokens in 116, out 34
```

A stranger spent the customer's gift card balance. The person who labelled it called that an
account problem, someone else getting into what is theirs. The stand-in reads `card`, a billing
word, and says billing. Asked to check, it reads `card` again and agrees with itself. **A mistake
the model would make again is a mistake its own check cannot see**, and every one of the six misses
is one of those.

The three false alarms are the same mechanism from the other side: `t37`, `h07` and `h30` were
answered correctly, and on close calls, so the reviewer doubted them anyway. A flag here means
*this was a close call*. That is worth knowing, as long as nobody reads it as *this is wrong*.
