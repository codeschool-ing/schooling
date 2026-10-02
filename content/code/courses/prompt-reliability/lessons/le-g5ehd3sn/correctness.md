---
title: Correctness, one mistake at a time
version: 1
---

Accuracy is the first number anybody reports and the one that says least. It counts the right
answers and treats every wrong one as the same wrong. **A confusion matrix keeps every mistake
apart**: one row for each label a person gave, one column for each label the reply gave.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6-all.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6-all.jsonl
ana@lab:~/triage$ pl confusion runs/v6-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing          13        1        1        0        0        1   0.81
delivery          0       13        0        0        1        0   0.93
returns           0        1       13        0        2        0   0.81
account           1        2        0        9        1        1   0.64
other             1        1        0        0        8        0   0.80
precision      0.87     0.72     0.93     1.00     0.67

accuracy 56/70 = 0.80
```

`cases/all.jsonl` is the forty dev messages and the thirty holdout ones together. The diagonal is
the replies that were right, 56 of 70. Every other cell is one particular mistake: row `account`,
column `delivery`, 2, means two account messages were sorted as delivery. `(bad)` holds replies with
no usable label at all, which the next section counts as format.

## Recall and precision

The two numbers at the edges answer different questions.

**Recall reads along a row**: of the messages that really were account, what share did the prompt
call account? Nine of fourteen, 0.64. Five account messages went somewhere else, and the account
team will never see them unless somebody forwards them.

**Precision reads down a column**: of the messages the prompt called delivery, what share were
delivery? Thirteen of eighteen, 0.72. Five of the delivery team's tickets belong to someone else.
Account has the opposite shape, precision 1.00: when the prompt says account it is right, and it
says account too rarely.

A prompt can raise one by lowering the other. Calling everything account would take account recall
to 1.00 and its precision to the floor. That is why the two are reported together, per label.

## Which mistakes cost more

The cells do not cost the same. Urgency shows it best:

```
ana@lab:~/triage$ grep h03 cases/all.jsonl
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v6-all.jsonl h03
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "Their account shows an order they never placed and their card has been charged for it."
│ }
stop: end, tokens in 123, out 41
ana@lab:~/triage$ pl confusion runs/v6-all.jsonl --field urgency
expected        low   normal     high    (bad)   recall
low              17        7        0        0   0.71
normal            1       27        0        2   0.90
high              0        6       10        0   0.62
precision      0.94     0.68     1.00

accuracy 54/70 = 0.77
```

`h03` is a card charged for an order the customer never placed, which may mean somebody else is
using their card. The category is right and the urgency is normal, so it waits in the ordinary
queue. It is one of six high messages sorted normal: recall for high is 0.62. Precision for high is
1.00, so nothing was escalated that should not have been.

Urgency accuracy is 54 of 70, and that number counts `h03` exactly like the seven low-urgency
messages sorted normal, whose only cost is being answered a little sooner than they needed. **A missed urgent message and a false
alarm are both one wrong answer, and they do not cost the same.** Decide what each kind of mistake
costs before you read the matrix, and report the expensive cells by name: *six high sorted normal*
is a sentence somebody acts on, and *0.77* is not.
