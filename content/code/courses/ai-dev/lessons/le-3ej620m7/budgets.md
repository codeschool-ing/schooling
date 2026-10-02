---
title: Budgets that are enforced, not hoped for
version: 1
---

A model call is the one line in your codebase whose cost is decided by its input, and its input
often comes from a user. A user can paste a book into the support chat; a bug can loop a request
a thousand times; a new feature can be ten times more popular than the estimate. **A budget is a
check in code that runs before the request is sent**, not a dashboard somebody looks at after the
invoice.

## A guard in front of every call

`lab/budget.py` wraps the call in a function that counts first and refuses two ways: a request too
big on its own, and a user who has used up the day's allowance:

```schooling-example
{
  "language": "python",
  "file": "lab/budget.py",
  "parts": [
    {
      "code": "import anthropic\n\nDAILY_LIMIT = 20_000  # input tokens per user per day\nPER_REQUEST = 4_000\nclient = anthropic.Anthropic()\nspent: dict[str, int] = {}\n\n\nclass OverBudget(Exception):\n    pass\n\n\n",
      "note": "**Two limits, in tokens.** Per request, so one paste cannot cost a fortune; per user and day, so one person cannot spend everybody's share."
    },
    {
      "code": "def ask(user: str, messages: list, max_tokens: int = 300):\n    n = client.messages.count_tokens(model=\"scripted-1\", messages=messages).input_tokens\n    if n + max_tokens > PER_REQUEST:\n        raise OverBudget(f\"{n} input tokens + {max_tokens} out is over {PER_REQUEST} per request\")\n    if spent.get(user, 0) + n > DAILY_LIMIT:\n        raise OverBudget(f\"{user} has used {spent.get(user, 0)} of {DAILY_LIMIT} today\")\n",
      "note": "**Count first, with the provider's own counter**, and refuse before anything is generated. The refusal is an exception with a name, so the caller cannot mistake it for an empty answer."
    },
    {
      "code": "    r = client.messages.create(model=\"scripted-1\", max_tokens=max_tokens, messages=messages)\n    spent[user] = spent.get(user, 0) + r.usage.input_tokens\n    return r\n\n\n",
      "note": "**Charge what was really used**, from `usage`, not the estimate."
    },
    {
      "code": "question = [{\"role\": \"user\", \"content\": \"Explain the shop's shipping rule.\"}]\nhuge = [{\"role\": \"user\", \"content\": open(\"/opt/aidev/share/corpus.txt\").read()[:30_000]}]\nfor user, msgs in [(\"ana\", question), (\"ana\", huge), (\"bea\", question)]:\n    try:\n        r = ask(user, msgs)\n        print(f\"{user}: ok, {r.usage.input_tokens} in, {r.usage.output_tokens} out; spent today {spent[user]}\")\n    except OverBudget as e:\n        print(f\"{user}: refused before sending: {e}\")"
    }
  ]
}
```

Three requests from two users, the second of them a paste of thirty thousand characters:

```
ana@dev:~/shop$ python lab/budget.py
ana: ok, 10 in, 147 out; spent today 10
ana: refused before sending: 7163 input tokens + 300 out is over 4000 per request
bea: ok, 10 in, 147 out; spent today 10
```

**The large request was refused before it was sent**: 7,163 tokens against a limit of 4,000 per
request. It still cost a counting call. labllm's log shows it as request 36, followed by the count and
the request that made the third (a real counting call is free of charge on Anthropic's API, and is
rate-limited):

```
ana@dev:~/shop$ tail -n 3 /var/log/labllm/requests.jsonl | python -c "import json, sys; [print(r[\"n\"], r[\"path\"], r[\"status\"]) for r in map(json.loads, sys.stdin)]"
36 /v1/messages/count_tokens 200
37 /v1/messages/count_tokens 200
38 /v1/messages 200
```

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
