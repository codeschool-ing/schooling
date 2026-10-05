---
title: The limit in your own code
version: 1
---

Every limit in sections 03 and 04 is set at somebody else's server, and knows only the money. The
one that knows what the program *meant* to do has to be in the program. ana's sorting has a bug of a
common kind: when the answer is not one of the five labels, it asks again. `lab/budget.py` carries
the bug, and a budget that counts what every response says it used:

```schooling-example
{
  "language": "python",
  "file": "lab/budget.py",
  "parts": [
    {
      "code": "import json\n\nfrom openai import OpenAI\n\n# gpt-5.4-mini's prices from lesson 8's sheet, dollars per million tokens\nPRICE_IN, PRICE_OUT = 0.75, 4.50\nLABELS = {\"order-status\", \"refund\", \"address-change\", \"product-question\", \"other\"}\n\n\n",
      "note": "gpt-5.4-mini's prices from the sheet, and the five labels a reply has to be one of."
    },
    {
      "code": "class Budget:\n    \"\"\"Adds up what each response says it used; refuses the next call once the money is gone.\"\"\"\n\n    def __init__(self, dollars):\n        self.left, self.calls = dollars, 0\n\n    def charge(self, usage):\n        self.calls += 1\n        self.left -= (usage.prompt_tokens * PRICE_IN + usage.completion_tokens * PRICE_OUT) / 1e6\n        if self.left < 0:\n            raise RuntimeError(f\"budget spent after {self.calls} calls\")\n\n\n",
      "note": "The guard. It does not estimate: it adds up what each response's `usage` says was used, at the prices above, and raises once the money is gone. The next call never happens."
    },
    {
      "code": "client = OpenAI()\nbudget = Budget(dollars=0.002)\nprompt = open(\"prompts/triage.txt\").read()\ncases = [json.loads(line) for line in open(\"cases/triage.jsonl\")]\n\n",
      "note": "A budget of $0.002, the lab's number, small enough to be spent in a minute. A real one is set from lesson 4's monthly estimate, with room for a bad day."
    },
    {
      "code": "try:\n    for c in cases:\n        label = None\n        while label not in LABELS:   # the bug: ask again until the answer is a label\n            r = client.chat.completions.create(model=\"standin-small\", temperature=0, messages=[\n                {\"role\": \"system\", \"content\": prompt}, {\"role\": \"user\", \"content\": c[\"text\"]}])\n            budget.charge(r.usage)\n            label = r.choices[0].message.content\n        print(c[\"id\"], label)\n",
      "note": "The bug, in the loop itself: ask again until the answer is a label. At temperature 0 a model that answers `Refund` once answers it every time, and the loop never ends on its own."
    },
    {
      "code": "except RuntimeError as e:\n    print(f\"stopped at {c['id']}, whose last answer was {label!r}: {e}\")\n",
      "note": "What the guard's exception looks like from outside: which case, what it last said, and how many calls it took."
    }
  ]
}
```

```
ana@desk:~/desk$ python lab/budget.py
c01 order-status
stopped at c02, whose last answer was 'Refund': budget spent after 36 calls
```

```
ana@desk:~/desk$ wire --count 200 | grep -c "^POST /v1/chat/completions -> 200"
36
```

`c02` was answered `Refund`, which is not a label. At temperature 0 the model answers the same thing
every time, so the loop asked thirty-five times and would have gone on all night. **The guard
stopped it at two tenths of a cent**, said where and why, and the stand-in's log agrees on the count.

What a night like that costs without one is arithmetic. Lesson 4 section 05 priced ana's drafting
on gpt-5.4-mini at $56.34 a month, 12,000 requests, so about **$0.0047 a request**. A loop that sends
one every three seconds, an assumption about how long a draft takes, makes 1,200 an hour: **$5.63
an hour, and the month's whole estimate in ten**. Nobody has to make a mistake bigger than one
`while` for that to happen, and none of the provider's limits would stop it, because a month's
budget spent in a night is still under the cap.

Four limits, then, and the job of each:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Four limits a request passes on its way to being billed, from the nearest to the farthest: a budget in ana's own program, a credit limit on the key, a spend limit she sets on the account, and the cap of the account's tier. The nearer the limit, the sooner it stops a runaway program and the less it protects against anything but that program.\"><defs><marker id=\"l21layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the request</text><line x1=\"40\" y1=\"44\" x2=\"680\" y2=\"44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"20\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">budget in the code</text><text x=\"97.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per run</text><text x=\"97.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set by ana</text><line x1=\"175\" y1=\"113\" x2=\"195\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"195\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">key credit limit</text><text x=\"272.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per key</text><text x=\"272.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set by ana, at the router</text><line x1=\"350\" y1=\"113\" x2=\"370\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"370\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">account spend limit</text><text x=\"447.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per month</text><text x=\"447.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set by ana, at the provider</text><line x1=\"525\" y1=\"113\" x2=\"545\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"545\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tier cap</text><text x=\"622.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per month</text><text x=\"622.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set by the provider</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nearest: knows the program</text><text x=\"700\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">farthest: knows only the money</text></svg>", "caption": "Four limits, each set by somebody different and each stopping something different. The nearest is the only one that knows what the program meant to do."}
```

- **The budget in the code** is the only one that can stop a run for being wrong rather than for
  being expensive. It counts what the responses report, the `usage` every API in this course
  returns, not an estimate.
- **The key's limit** isolates one program from the others: the sorting key running dry does not
  stop the drafting.
- **The account's spend limit** is the floor under everything ana writes, at the month's estimate
  plus a margin.
- **The tier's cap** is the provider's, and the one never to rely on.

And one thing none of them does: **tell a person.** A limit that is reached at 3 a.m. stops the
spending and also stops the sorting. Where a provider's console offers an alert at a threshold, ana
sets one; the guard in the code can do the same, by logging what it stopped and why where a person
will see it. The order of a morning
after a bad night should be: read the alert, fix the bug, raise nothing.
