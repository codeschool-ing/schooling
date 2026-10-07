---
title: Budgets that are enforced, not hoped for
version: 2
---

A model call is the one line in your codebase whose cost is decided by its input, and its input
often comes from a user. A user can paste a book into the support chat; a bug can loop a request
a thousand times; a new feature can be ten times more popular than the estimate. **A budget is a
check in code that runs before the request is sent**, not a dashboard somebody looks at after the
invoice.

## A guard in front of every call

`~/shop/scratch/budget.py` wraps the call in a function that estimates first and refuses two ways:
a request too big on its own, and a user who has used up the day's allowance:

```schooling-example
{
  "language": "python",
  "file": "scratch/budget.py",
  "parts": [
    {
      "code": "import anthropic\nimport tiktoken\n\nDAILY_LIMIT = 20_000  # input tokens per user per day\nPER_REQUEST = 3_000\nMARGIN = 1.2  # tiktoken is not this model's tokenizer, so the estimate gets room\nclient = anthropic.Anthropic()\nenc = tiktoken.get_encoding(\"o200k_base\")\nspent: dict[str, int] = {}\n\n\nclass OverBudget(Exception):\n    pass\n\n\n",
      "note": "**Two limits, in tokens.** Per request, so one paste cannot cost a fortune; per user and day, so one person cannot spend everybody's share. `MARGIN` is there because the estimate comes from a tokenizer that is not this model's."
    },
    {
      "code": "def ask(user: str, messages: list, max_tokens: int = 300):\n    n = int(sum(len(enc.encode(m[\"content\"])) for m in messages) * MARGIN)\n    if n + max_tokens > PER_REQUEST:\n        raise OverBudget(f\"about {n} input tokens + {max_tokens} out is over {PER_REQUEST} per request\")\n    if spent.get(user, 0) + n > DAILY_LIMIT:\n        raise OverBudget(f\"{user} has used {spent.get(user, 0)} of {DAILY_LIMIT} today\")\n",
      "note": "**Estimate first, on your own machine**, and refuse before anything is sent. The refusal is an exception with a name, so the caller cannot mistake it for an empty answer."
    },
    {
      "code": "    r = client.messages.create(model=\"llama3.2:3b\", max_tokens=max_tokens, messages=messages)\n    used = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)\n    spent[user] = spent.get(user, 0) + used\n    return r, used\n\n\n",
      "note": "**Charge what was really used**, from `usage`, not the estimate."
    },
    {
      "code": "code = open(\"shop/cart.py\").read()\nquestion = [{\"role\": \"user\", \"content\": code + \"\\nExplain the shipping rule above.\"}]\nhuge = [{\"role\": \"user\", \"content\": open(\"CONVENTIONS.md\").read() * 8}]\nfor user, msgs in [(\"ana\", question), (\"ana\", huge), (\"bea\", question)]:\n    try:\n        r, used = ask(user, msgs)\n        print(f\"{user}: ok, {used} in, {r.usage.output_tokens} out; spent today {spent[user]}\")\n    except OverBudget as e:\n        print(f\"{user}: refused before sending: {e}\")\n"
    }
  ]
}
```

Three requests from two users, the second of them eight copies of `CONVENTIONS.md` pasted into a
question:

```
ana@dev:~/shop$ python scratch/budget.py
ana: ok, 299 in, 141 out; spent today 299
ana: refused before sending: about 3590 input tokens + 300 out is over 3000 per request
bea: ok, 299 in, 139 out; spent today 299
```

**The large request was refused before it was sent**: about 3,590 tokens by the estimate, against
a limit of 3,000 per request. It cost nothing at all, not even a call, because the estimate was
made on this machine. That is the trade against the provider's counting call of lesson 2 section
03: an exact number for a network round trip, or an estimate with a margin for free. A guard like
this one is the place for the estimate; the bill is the place for the exact number, and `usage` is
where it comes from.

## Where the limits come from

- **Per request**: the size of the biggest legitimate request, plus a margin. The window of lesson
  2 section 02 is the hard limit; your budget is a lower one you chose.
- **Per user, per day**: from the cost estimate of lesson 2 section 05 and how much of it one
  person may spend. Kept in a database, not in a dictionary in memory as here, so it survives a
  restart and is shared between servers.
- **For the whole account**: the providers' consoles offer spending limits or alerts, or
  both. Set them on the first day, low, and raise them on purpose. They are the last line, not
  the only one: they stop the money, and they stop the feature for everybody with it.

**Refuse with a message a person can act on.** "This message is too long to process; send a
shorter excerpt" lets the user fix it. A generic error after a 400 from the provider does not, and
it has already cost the counting call and the time.
