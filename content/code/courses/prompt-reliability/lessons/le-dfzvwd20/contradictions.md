---
title: Two instructions that disagree
version: 2
---

Two lines of `v2-long.txt` are about how long the summary should be. They were written for
different complaints and both sound reasonable:

```
ana@lab:~/triage$ grep -n -e brief -e detail prompts/v2-long.txt
4:Keep the summary brief so the team can scan the queue quickly.
16:The team reads the summary instead of the message, so describe the problem in full detail.
```

Line 4 wants a summary the team can scan. Line 16, added later by somebody whose complaint was
that the summary left things out, wants the problem in full detail. **Nobody can obey both, so the
model chooses, and you do not get a say in how.**

Here are two messages under the short prompt, which asks for one sentence, and under the long one:

```
ana@lab:~/triage$ grep t17 cases/dev.jsonl
{"id": "t17", "message": "My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.", "expect": {"category": "delivery", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Order has not arrived ten days after dispatch and is needed for a birthday on Saturday"}
stop: stop, tokens in 114, out 35, 3.6 s
ana@lab:~/triage$ pl show runs/long.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Order has not arrived 10 days after dispatch and is needed for a birthday on Saturday"}
stop: stop, tokens in 211, out 36, 4.2 s
ana@lab:~/triage$ pl show runs/v2.jsonl t23
│ {"category": "returns", "urgency": "high", "summary": "Customer is reporting a damaged parcel with ruined books and wants to initiate a return process."}
stop: stop, tokens in 106, out 36, 4.0 s
ana@lab:~/triage$ pl show runs/long.jsonl t23
│ {"category": "returns", "urgency": "high", "summary": "Received damaged parcel with water-soaked books"}
stop: stop, tokens in 203, out 27, 3.2 s
```

`t17` came back almost word for word the same under both prompts. `t23` came back **shorter**
under the prompt that asks for full detail: the short prompt wrote *"Customer is reporting a damaged
parcel with ruined books and wants to initiate a return process"*, the long one *"Received damaged
parcel with water-soaked books"*. On that message line 4 won. Over all forty, the mean reply grew
from 30.6 tokens to 33.6, so on some others line 16 did.

**That is what a contradiction buys: no rule at all.** Which of two conflicting instructions a model
follows depends on the model, on the wording, on where each one sits and on the message in front of
it, and it can change when the model is updated. You cannot read the answer off the prompt, and
you cannot read it off one reply either: `t23` alone says brevity won, the mean says detail did.

## What it costs

The disagreement is settled again on every call, by whatever the model happens to weigh most on
that message, and you pay for it in two ways. The extra output is small here, three tokens a reply,
because the test set's messages are short and full detail adds a clause at most; an inbox with
paragraphs in it would widen the gap. The larger cost is that **a summary's length is no longer
something you decided**, so nothing downstream can rely on it.

The guides Anthropic and OpenAI publish on writing prompts both open on the same advice: be clear
and direct about what you want. A prompt that asks for two incompatible things is the plainest way
of not being clear, and the fix is not a third line saying which one wins. **Either instruction alone
gives you an answer you chose; both together give you one the model chose.** Decide, and delete the
other.
