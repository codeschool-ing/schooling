---
title: What a longer prompt buys
version: 2
---

A prompt grows the way a policy document grows. Somebody sees one bad answer and adds a line,
somebody else adds the same line in capitals, and nobody deletes anything, because deleting feels
riskier than adding. **The idea underneath is that a longer prompt is a more careful one.** It is
only a longer one, and the length has a price that is paid on every call.

Here is the triage prompt after a few weeks of that kind of care. Save it as
`prompts/v2-long.txt`:

```
You are a helpful, friendly and professional assistant for Folio, an online bookshop.
Your job is to read customer messages and sort them so the support team can answer them.

Keep the summary brief so the team can scan the queue quickly.

Answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": what the customer needs

IMPORTANT: Do not make up information that is not in the message.
Do not add fields that are not listed above.
Never include the customer's name or email in the summary.
IMPORTANT: Do not make up information that is not in the message.

The team reads the summary instead of the message, so describe the problem in full detail.

Message: {{message}}
```

It asks for the same three fields with the same two lists as `v2-json.txt`, the prompt lesson 1
ran when it first asked for JSON. Everything else is a persona, three rules about what not to do
with one of them written twice, and two instructions about the summary that disagree with each
other. The next section is about those two.

## Paid on every call

The prompt is sent whole with every message. **Whatever the instructions cost, you pay it forty
times for forty messages and a million times for a million.** `pl` records the tokens and the
seconds of every call in the run file, and a short program adds them up. Save it as `stats.py`:

```python
"""stats: what each run cost, in tokens and in seconds."""
import statistics
import sys

from pl import read_jsonl


def pct(values, p):
    values = sorted(values)
    return values[min(len(values) - 1, int(p * len(values)))]


for path in sys.argv[1:]:
    rows = read_jsonl(path)
    tin = [r["tokens_in"] for r in rows]
    tout = [r["tokens_out"] for r in rows]
    secs = [r["seconds"] for r in rows]
    print("%s, %d calls" % (path, len(rows)))
    print("  tokens in    mean %6.1f   total %6d" % (statistics.mean(tin), sum(tin)))
    print("  tokens out   mean %6.1f   total %6d   max %d" % (statistics.mean(tout), sum(tout), max(tout)))
    print("  seconds      p50 %5.1f   p95 %5.1f   total %6.1f" % (pct(secs, .5), pct(secs, .95), sum(secs)))
```

It imports `read_jsonl` from `pl.py`, which works because the two files sit in the same
directory. Run both prompts and compare:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v2-long.txt cases/dev.jsonl --out runs/long.jsonl
40 calls, prompt 2b255df5, llama3.2:3b, written to runs/long.jsonl
ana@lab:~/triage$ python3 stats.py runs/v2.jsonl runs/long.jsonl
runs/v2.jsonl, 40 calls
  tokens in    mean  106.2   total   4246
  tokens out   mean   30.6   total   1225   max 38
  seconds      p50   3.3   p95   4.1   total  287.4
runs/long.jsonl, 40 calls
  tokens in    mean  203.2   total   8126
  tokens out   mean   33.6   total   1343   max 46
  seconds      p50   3.8   p95   5.2   total  157.0
```

Input went from 106.2 tokens a call to 203.2. **That gap, 97 tokens, is the extra instructions**,
the same on every message whatever the message says. Output moved much less, from 30.6 to 33.6.

The seconds need one warning. The median call took 3.3 seconds with the short prompt and 3.8 with
the long one, which is the comparison to read. The totals point the other way, 287.4 against 157.0,
because the first run paid for loading the model into memory on its first call and the second did
not. **A total that includes a one-off cost compares the order you ran things in**, not the prompts.

On your own machine the price of a token is time: a model reads every token of the prompt before it
writes a word, and the extra 97 cost about half a second a call here. On a paid API it is money as
well. Providers price input and output tokens separately, so multiply the totals by your provider's
two prices to get what a run cost. The shape is the same whoever sells it: **an instruction that
changes nothing is paid for on every call, for as long as the prompt runs.** Lesson 16 does that
arithmetic for a whole pipeline, and lesson 17 shows how a cache makes the fixed part of a prompt
cheaper.

## What a reader does with length

The model is not the only reader. Here is the prompt again, numbered:

```
ana@lab:~/triage$ cat -n prompts/v2-long.txt
     1	You are a helpful, friendly and professional assistant for Folio, an online bookshop.
     2	Your job is to read customer messages and sort them so the support team can answer them.
     3	
     4	Keep the summary brief so the team can scan the queue quickly.
     5	
     6	Answer in JSON with three fields:
     7	- "category": one of billing, delivery, returns, account, other
     8	- "urgency": one of low, normal, high
     9	- "summary": what the customer needs
    10	
    11	IMPORTANT: Do not make up information that is not in the message.
    12	Do not add fields that are not listed above.
    13	Never include the customer's name or email in the summary.
    14	IMPORTANT: Do not make up information that is not in the message.
    15	
    16	The team reads the summary instead of the message, so describe the problem in full detail.
    17	
    18	Message: {{message}}
```

The person who opens `v2-long.txt` next month to fix a complaint has eighteen lines to hold in
their head, and has to work out which of them still
matter. Line 14 repeats line 11 word for word. Lines 11 and 14 are in capitals, which tells that
person that they matter more than line 13, and nobody decided that. **Every line in a prompt is a
claim that it changes an answer**, and a reader has no way to know which claims are true except
by testing them.
