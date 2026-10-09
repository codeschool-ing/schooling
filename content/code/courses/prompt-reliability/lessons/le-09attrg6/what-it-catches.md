---
title: What it catches
version: 2
---

Run the delimited, escaped prompt at temperature 0 and ask the model to check every answer it gave:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6.jsonl
ana@lab:~/triage$ python3 selfcheck.py runs/v6.jsonl
t01    wrong WRONG The answer is not valid JSON because it is missing the nec
t02    right WRONG The reason is that the category "delivery" is not specific
t04    right WRONG The answer is not valid JSON because it is missing the nec
t05    right WRONG The answer is not valid JSON because it is missing the req
t06    wrong WRONG The answer is not valid JSON because it is missing the req
t07    right WRONG The answer is not valid JSON because it is missing a closi
t08    right WRONG The answer is not valid JSON because it is missing the req
t09    right WRONG The reason is that the JSON object is missing a closing br
t11    right WRONG The reason is that the JSON object is missing a closing br
t13    right WRONG The answer is not valid JSON because it is missing the req
t14    right WRONG The reason is that the JSON is missing a closing bracket a
t16    right WRONG The answer is not valid JSON because it is missing a closi
t17    right WRONG The reason is that the JSON object is missing a closing br
t18    right WRONG The answer is not valid JSON because it is missing the req
t19    wrong WRONG The answer is not valid JSON because it is missing the req
t21    right WRONG The reason is that the JSON is missing a closing bracket a
t22    wrong WRONG The answer is not valid JSON because it is missing the req
t23    right WRONG The reason is that the JSON object is missing a closing br
t25    wrong OK
t26    wrong WRONG The answer is not valid JSON because it is missing the req
t27    right WRONG The answer is not valid JSON because it is missing the req
t28    right WRONG The answer is not valid JSON because it is missing the req
t31    wrong WRONG The answer is missing a colon (:) between the key "categor
t32    right WRONG The answer is not valid JSON because it is missing the nec
t36    right WRONG The answer is not valid JSON because it is missing a closi
t37    wrong OK
t38    wrong OK
t39    wrong OK
h01    wrong OK
h02    right WRONG The answer is not valid JSON because it is missing the req
h03    wrong WRONG The answer is not valid JSON because it is missing the req
h05    wrong WRONG The answer is not valid JSON because it is missing the req
h06    wrong OK
h07    wrong WRONG The answer is not valid JSON because it is missing the req
h08    right WRONG The answer is not valid JSON because it is missing the nec
h11    wrong WRONG The reason is that the JSON object is missing a closing br
h12    wrong WRONG The reason is that the JSON answer is missing the "descrip
h13    right WRONG The answer is not valid JSON because it is missing a closi
h15    right WRONG The reason is that the JSON object is missing a closing br
h16    right WRONG The reason is that the JSON answer is missing the "descrip
h17    wrong WRONG The reason is that the JSON object is missing a required k
h18    right WRONG The answer is not valid JSON because it is missing the req
h19    right WRONG The answer is not valid JSON because it is missing the req
h21    wrong OK
h22    wrong WRONG The reason is that the answer is missing the "description"
h23    wrong WRONG The reason is that the JSON object is missing a required k
h24    wrong WRONG The reason is that the category "returns" is not the corre
h25    right WRONG The answer is not valid JSON because it is missing a closi
h26    wrong OK
h27    wrong WRONG The reason is that the JSON is missing a closing bracket a
h28    wrong WRONG The reason is that the category is missing a value. In JSO
h29    right WRONG The reason is that the JSON object is missing a closing br
h30    wrong WRONG The answer is missing the "message" key, which is present 

                 really wrong  really right
flagged                    18            27
not flagged                 8            17
precision 0.40   recall 0.69
```

Of seventy replies, 26 were really wrong. The reviewer flagged 45 replies, and 18 of those were
among the 26.

Two numbers summarise the table. **Precision** asks how many flags were right: 18 of 45, 0.40.
**Recall** asks how many mistakes were flagged: 18 of 26, 0.69. A check with high precision and low
recall is quiet and trustworthy when it speaks; one with the opposite is loud and catches more.
Neither number means anything without the other.

## Against a coin

Those two numbers need a baseline, and the honest one is a check that never reads anything. Flag 45
replies of the seventy at random, and on average the flags land on wrong replies in the same share
as wrong replies have in the whole run: 26 of 70, a precision of 0.37. Recall would be 45 of 70,
0.64. **The reviewer's 0.40 and 0.69 are barely above a check that flips a coin**, which is what
the table says when you read it by columns: it flagged 18 of the 26 wrong replies, 69%, and 27 of
the 44 right ones, 61%.

## What it said

Read the reasons, not only the flags. Almost every one is about the format, and almost every one is
false. Here is `t07`, which the reviewer said was *not valid JSON because it is missing a closing
bracket*:

```
ana@lab:~/triage$ pl show runs/v6.jsonl t07
│ {"category": "delivery", "urgency": "high", "summary": "Customer disputes delivery address"}
stop: stop, tokens in 151, out 23, 2.9 s
```

It parses, it has every field, and its category is right. The reviewer was asked a yes-or-no
question about this text, and it answered with a defect the text does not have. The same sentence,
*missing a closing bracket* or *missing the required field*, appears on most of the 45 flags, right
replies and wrong ones alike. **A flag that comes with a reason is not more trustworthy for having
one**: the reason is generated like everything else, and here it is mostly invented.

And the replies that were really broken? `t38` is not JSON at all, and the reviewer said OK. The
last section of this lesson comes back to it.

## The misses

Eight wrong replies came back OK: `t25`, `t37`, `t38`, `t39`, `h01`, `h06`, `h21` and `h26`. Seven
of them are label mistakes, and the reviewer read the message and the wrong label and agreed. **A
mistake the model would make again is a mistake its own check cannot see**, because the check reads
with the same knowledge the answer was written with.
