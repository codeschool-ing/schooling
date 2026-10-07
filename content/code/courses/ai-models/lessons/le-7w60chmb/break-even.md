---
title: When it pays for itself
version: 1
---

A machine is paid for by the hour whether it is busy or not. An API is paid for by the token and
costs nothing when nobody calls it. So the comparison is not "which is cheaper" but **at what
volume do they cost the same**.

First, the size of ana's requests. `volume.py` sends each of the forty cases to the model, through
Anthropic's library and Ollama, and reads the `usage` that comes back, which counts the tokens the
request actually used:

```python
import json

import anthropic

client = anthropic.Anthropic()  # Ollama, through desk.env
system = open("prompts/triage.txt").read()
ins, outs = [], []
for line in open("cases/triage.jsonl"):
    r = client.messages.create(model="llama3.2:3b", max_tokens=10, system=system,
                               messages=[{"role": "user", "content": json.loads(line)["text"]}])
    # the part of the prompt the server had already read is counted apart, as a cache read
    ins.append(r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0))
    outs.append(r.usage.output_tokens)
print(f"{len(ins)} e-mails: {sum(ins) / len(ins):.1f} tokens in, {sum(outs) / len(outs):.1f} out, on average")
```

```
ana@desk:~/desk$ python volume.py
40 e-mails: 81.1 tokens in, 3.9 out, on average
```

About 81 tokens in and four out. The input is the three-line prompt and an e-mail, plus what the
model's chat template wraps around them, lesson 1 section 08's special tokens; the output is a label
of a word or two, and sometimes two labels where the prompt asked for one. **The counts are
Llama's**, made with its own tokenizer: Claude counts the same text with another, so the figure is
an estimate of the size, which is all a break-even needs. The server reports the part of the prompt
it had already read on the previous request as a cache read, and `volume.py` adds the two back
together; lesson 17 is about why an API counts them apart.

`breakeven.py` takes those numbers, 82 in and 5 out, a little above the averages, a model's prices
from the sheet, and the monthly cost of a machine. Lantern Books receives about 400 e-mails a day,
and the machine costs $1,500 a month: both are the course's assumptions, round enough to be read as
such.

```python
import json
import sys

sheet = json.load(open("litellm-21881c57.json"))  # the copy sheet.py keeps, from lesson 2
model, machine = sys.argv[1], float(sys.argv[2])  # the machine's monthly cost is an assumption
tokens_in, tokens_out, per_day = 82, 5, 400  # volume.py, rounded up
price = sheet[model]
per_request = tokens_in * price["input_cost_per_token"] + tokens_out * price["output_cost_per_token"]
print(f"{model}: ${per_request * 1e6:.0f} per million requests")
print(f"  ana's {per_day} a day: ${per_request * per_day * 30:.2f} a month")
print(f"  a ${machine:,.0f} machine pays for itself at {machine / per_request / 30:,.0f} requests a day")
```

```
ana@desk:~/desk$ python breakeven.py claude-haiku-4-5 1500
claude-haiku-4-5: $107 per million requests
  ana's 400 a day: $1.28 a month
  a $1,500 machine pays for itself at 467,290 requests a day
```

**A dollar and twenty-eight cents a month.** At 400 e-mails a day, Lantern Books' whole sorting load
costs less than a coffee on the cheapest model the sheet lists for Anthropic, and a machine would
have to sort **467,290 e-mails a day** to cost the same. Now Claude Opus 5.5, which the sheet prices
at four times as much per token:

```
ana@desk:~/desk$ python breakeven.py claude-opus-5-5 1500
claude-opus-5-5: $428 per million requests
  ana's 400 a day: $5.14 a month
  a $1,500 machine pays for itself at 116,822 requests a day
```

Four times the cost per request, and still **$5.14 a month**. The break-even volume falls to
116,822 a day, which is about 290 times what the shop receives.

## The shape of the answer

The arithmetic here is about a small task: few tokens in, almost none out. Change any of those and
the break-even moves:

- **long prompts or long replies** multiply the cost per request, and the break-even volume falls
  by the same factor;
- **steady, high volume** keeps the machine busy, which is the only way it is cheap per token
  (section 05);
- **a bursty load** needs a machine sized for the peak and paid for at the trough.

For ana, the money answer is not close. **Self-hosting can still be right for her**, but not for
cost, and section 08 lists the reasons that are not about money.
