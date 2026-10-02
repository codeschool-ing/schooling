---
title: Two instructions that disagree
version: 1
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

The stand-in's way of choosing is written in its opening comment: between an instruction to be
brief and one to be thorough, the one written last wins. Line 16 comes after line 4, so it
decides every summary. A message with two sentences shows it:

```
ana@lab:~/triage$ grep t17 cases/dev.jsonl
{"id": "t17", "message": "My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.", "expect": {"category": "delivery", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {
│   "category": "delivery",
│   "urgency": "high",
│   "summary": "Their order was dispatched ten days ago and still hasn't arrived."
│ }
stop: end, tokens in 87, out 38
ana@lab:~/triage$ pl show runs/long.jsonl t17
│ {
│   "category": "delivery",
│   "urgency": "high",
│   "summary": "Their order was dispatched ten days ago and still hasn't arrived. They need it for a birthday on Saturday."
│ }
stop: end, tokens in 185, out 47
```

Under `v2-json.txt`, which asks for one sentence, the summary is the first sentence of the
message. Under the long prompt it is the whole message, moved into the third person. Line 16 gave
a reason, that the team reads the summary instead of the message. **The summary it produced is
the message**, so the team now reads it twice, and the queue line 4 wanted to keep scannable is
as long as the inbox.

## What it costs

The longer summaries are paid for as output, and output is what the model writes one token at a
time:

```
ana@lab:~/triage$ pl latency runs/v2.jsonl
calls 40
p50 1186 ms   p95 1397 ms   max 1468 ms
output tokens: mean 39.9, max 50
ana@lab:~/triage$ pl latency runs/long.jsonl
calls 40
p50 1306 ms   p95 1475 ms   max 1504 ms
output tokens: mean 42.7, max 54
```

The mean reply grew from 39.9 tokens to 42.7, and the longest from 50 to 54. The median call took
1,306 ms instead of 1,186. Those gaps are small because the test set's messages are short, one or
two sentences each, so full detail adds a sentence at most. An inbox with paragraphs in it would widen them. The lab's latencies are the course's numbers,
computed rather than timed. The
direction is the point: **a contradiction is not settled once, it is settled again on every call,
and paid for each time.**

## On a real model

A real model has no written rule like the stand-in's. Which of two conflicting instructions it
follows depends on the model, on the wording, and on where each one sits, and it can change when
the provider updates the model. That is a practitioner's observation rather than a measured rate,
and it is the reason a contradiction is worse than either of its halves. **Either instruction
alone gives you an answer you chose; both together give you one the model chose**, and you find
out which by reading replies.

The guides Anthropic and OpenAI publish on writing prompts both open on the same advice: be clear
and direct about what you want. A prompt that asks for two incompatible things is the plainest
way of not being clear, and the fix is not a third line saying which one wins. It is deciding,
and deleting the other.
