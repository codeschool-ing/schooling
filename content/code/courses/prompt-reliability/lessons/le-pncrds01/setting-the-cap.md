---
title: Setting the cap from a measurement
version: 1
---

A cap catches a reply that runs away, and it does that job only if ordinary replies never reach it.
So **the place to start is the longest ordinary reply, measured**:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4-all.jsonl
70 calls, prompt 651820d7, written to runs/v4-all.jsonl
ana@lab:~/triage$ pl latency runs/v4-all.jsonl
calls 70
p50 1159 ms   p95 1390 ms   max 1473 ms
output tokens: mean 38.0, max 50
```

Over all seventy messages, the development set and the holdout together, the longest reply was 50
tokens and the mean 38.0. A cap of 50 would pass every one of them today. **A cap at exactly the
measured maximum has no headroom**, and the prompt will not stay the same. Lesson 21's version asks
for a fourth field, a confidence score, and here it is under a cap of 50:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set max_tokens=50 --out runs/v9-50.jsonl
40 calls, prompt c31bed19, written to runs/v9-50.jsonl
ana@lab:~/triage$ pl check runs/v9-50.jsonl --failures
check      pass  fail
json         38     2
fields       38     2
labels       38     2
category     38     2
urgency      36     4
all          36     4

t14    urgency   normal, expected low
t24    json      cut off at max_tokens
t28    urgency   normal, expected low
t37    json      cut off at max_tokens
ana@lab:~/triage$ pl show runs/v9-50.jsonl t37
│ {"category": "billing", "urgency": "normal", "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week.", "confidence":
stop: max_tokens, tokens in 287, out 50
ana@lab:~/triage$ pl show runs/v9-50.jsonl t24
│ {"category": "delivery", "urgency": "low", "summary": "Asks: is it possible to change the delivery address on an order I placed an hour ago?", "confidence": 0.97
stop: max_tokens, tokens in 282, out 50
```

Two replies are cut. Now look at the `all` line: 36, and below, with the cap at 100, it is 36 again.
Both cut replies were already wrong for another reason, `t37` on its category and `t24` on its
urgency, so **the total did not move and the cut was hidden inside it**. Only the `json` line and the
stop reasons show it. The day somebody fixes the urgency rule, `t24` becomes right and stays failed,
and the fix looks smaller than it was.

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set max_tokens=100 --out runs/v9-100.jsonl
40 calls, prompt c31bed19, written to runs/v9-100.jsonl
ana@lab:~/triage$ pl check runs/v9-100.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     39     1
urgency      36     4
all          36     4
ana@lab:~/triage$ pl latency runs/v9-100.jsonl
calls 40
p50 1413 ms   p95 1532 ms   max 1591 ms
output tokens: mean 45.4, max 54
```

With a cap of 100 nothing is cut, and the longest reply is now 54 tokens. One extra field moved the
maximum from 50 to 54, and nobody adding a field thinks to check the cap. Twice the measured maximum,
here 100, is this course's habit rather than a law. It costs nothing on a reply that stops before it,
because what a provider charges for is the tokens written, and `pl cost` adds up the same thing. The
rule underneath the habit: the cap sits so far above every reply you have measured that **only a
reply gone wrong can reach it**, and you measure again whenever the prompt changes.

## A cut reply is a failure

`t24` is one closing brace short of valid JSON. A reader that repairs replies, adding the missing
brace and parsing the result, would accept it, and on that message it would even get the whole
answer. On `t37`, cut after `"confidence":`, the same repair has no value to close. On a reply cut
inside its summary, like `t01` under the cap of thirty, it would accept a sentence with its end
missing, and nothing downstream would know.

`prompt-engineering` repaired invalid output in its lesson 19. A cut reply is the one case where
repair is the wrong tool. **Every reply that stopped at `max_tokens` is a failure, whether or not what
is left of it parses.** The reader looks at the stop reason before it parses anything, logs the
reply, and treats it as the harness does: as a reply that did not arrive. Counting those stops is
also how you learn a cap has drifted into ordinary traffic, long before anybody reads a truncated
summary.
