---
title: Setting the cap from a measurement
version: 2
---

A cap catches a reply that runs away, and it does that job only if ordinary replies never reach it.
So **the place to start is the longest ordinary reply, measured**:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4-all.jsonl
70 calls, prompt 651820d7, llama3.2:3b, written to runs/v4-all.jsonl
ana@lab:~/triage$ python3 stats.py runs/v4-all.jsonl
runs/v4-all.jsonl, 70 calls
  tokens in    mean  121.3   total   8491
  tokens out   mean   29.1   total   2038   max 38
  seconds      p50   3.4   p95   4.4   total  243.2
```

Over all seventy messages, the development set and the holdout together, the longest reply was 38
tokens and the mean 29.1. A cap of 38 would pass every one of them today. **A cap at exactly the
measured maximum has no headroom**, and the prompt will not stay the same.

## The prompt grows a field

Lesson 21 asks the model how sure it is, in a fourth field. Save its prompt as
`prompts/v9-confidence.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with four fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs
- "confidence": how sure you are of the category, from 0 to 1

<example>
Message: I paid for express delivery but the order came by normal post.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "confidence": 0.9}
</example>

<example>
Message: The book came with water damage on every page.
Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book.", "confidence": 0.95}
</example>

<example>
Message: Can I change the name on my account?
Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name.", "confidence": 0.85}
</example>

Message: {{message}}
```

A fourth field is a change to the contract as well as to the prompt: `judge()` in `pl.py` refuses
any key it does not know, so it would fail every one of these replies on `fields`. Lesson 3 said the
check is the reader's needs written down, and the reader now needs one more key. Allow it with one
edit, which every later lesson relies on:

```sh
sed -i 's/and k != "summary"/and k not in ("summary", "confidence")/' pl.py
```

Now run the new prompt under the old maximum as its cap, 38:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set num_predict=38 --out runs/v9-38.jsonl
40 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-38.jsonl
ana@lab:~/triage$ pl check runs/v9-38.jsonl --failures
check      pass  fail
json         33     7
fields       33     7
labels       33     7
category     28    12
urgency      19    21
all          19    21

t01    json      cut off at num_predict
t02    urgency   high, expected normal
t03    json      cut off at num_predict
t06    json      cut off at num_predict
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t11    json      cut off at num_predict
t17    json      cut off at num_predict
t19    json      cut off at num_predict
t21    json      cut off at num_predict
t22    category  other, expected billing
t23    urgency   normal, expected high
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t28    urgency   high, expected low
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t36    urgency   normal, expected high
t37    category  billing, expected delivery
t39    urgency   low, expected normal
```

**Seven replies are cut**, every one of them a reply that would have passed. The extra field made
replies longer, and nobody adding a field thinks to check the cap. Here is the same prompt with the
cap at twice the old maximum:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set num_predict=76 --out runs/v9-76.jsonl
40 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-76.jsonl
ana@lab:~/triage$ pl check runs/v9-76.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     35     5
urgency      26    14
all          26    14
ana@lab:~/triage$ python3 stats.py runs/v9-76.jsonl
runs/v9-76.jsonl, 40 calls
  tokens in    mean  288.1   total  11526
  tokens out   mean   36.6   total   1463   max 43
  seconds      p50   4.3   p95   4.9   total  172.9
ana@lab:~/triage$ pl compare runs/v9-38.jsonl runs/v9-76.jsonl
runs/v9-38.jsonl         passes 19/40
runs/v9-76.jsonl         passes 26/40
fixed 7, broken 0
sign test on the 7 that changed: p = 0.016
```

With a cap of 76 nothing is cut, the longest reply is now 43 tokens, and the seven come back: fixed
7, broken 0. One extra field moved the maximum from 38 to 43, and a cap that had no room to spare
turned seven right answers into seven exceptions.

Twice the measured maximum, here 76, is this course's habit rather than a law. It costs nothing on
a reply that stops before it, because a model writes, and a provider charges for, the tokens of the
reply and not the cap. The rule underneath the habit: the cap sits so far above every reply you have
measured that **only a reply gone wrong can reach it**, and you measure again whenever the prompt
changes.

## A cut reply is a failure

A reply cut after its last field is one closing brace short of valid JSON. A reader that repairs
replies, adding the missing brace and parsing the result, would accept it, and on that message it
would even get the whole answer. On a reply cut after `"confidence":`, the same repair has no value
to close. On a reply cut inside its summary, like `t01` under the cap of 25, it would accept a
sentence with its end missing, and nothing downstream would know.

`prompt-engineering` repaired invalid output in its lesson 19. A cut reply is the one case where
repair is the wrong tool. **Every reply that stopped at the cap is a failure, whether or not what is
left of it parses.** The reader looks at the stop reason before it parses anything, logs the reply,
and treats it as the harness does: as a reply that did not arrive. Counting those stops is also how
you learn a cap has drifted into ordinary traffic, long before anybody reads a truncated summary.
