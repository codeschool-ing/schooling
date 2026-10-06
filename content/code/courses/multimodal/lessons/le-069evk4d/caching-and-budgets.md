---
title: Never pay twice, and check before the call
version: 1
---

The cheapest request is the one never sent. A shop asks the same questions of the same pictures more often than it expects: a retry after a timeout, two people opening one invoice, a batch run again after a fix elsewhere. A cache keyed by **everything that shapes the reply** answers those from disk:

```schooling-example
{
  "language": "python",
  "file": "cached.py",
  "parts": [
    {
      "code": "\"\"\"Ask about a picture once; the second time, answer from disk. The key is everything that shapes the reply.\"\"\"\nimport base64\nimport hashlib\nimport json\nimport os\nimport sys\n\nfrom openai import OpenAI\n\n"
    },
    {
      "code": "CACHE = \"cache\"\n\n\n",
      "note": "**Replies are kept as files in one directory**, one per question asked."
    },
    {
      "code": "def describe(path, prompt, model=\"lab-vision-1\", detail=\"high\"):\n    raw = open(path, \"rb\").read()\n    key = hashlib.sha256(json.dumps([hashlib.sha256(raw).hexdigest(), prompt, model, detail]).encode()).hexdigest()\n    hit = os.path.join(CACHE, key + \".json\")\n",
      "note": "**The key is a hash of everything that shapes the reply**: the picture's own hash, the prompt, the model and the `detail`. Leave one out and two different questions share an answer."
    },
    {
      "code": "    if os.path.exists(hit):\n        return json.load(open(hit)), \"cache\"\n",
      "note": "**A hit costs nothing**: no request, no tokens, no wait."
    },
    {
      "code": "    url = \"data:image/png;base64,\" + base64.b64encode(raw).decode()\n    r = OpenAI().chat.completions.create(model=model, messages=[{\"role\": \"user\", \"content\": [\n        {\"type\": \"text\", \"text\": prompt}, {\"type\": \"image_url\", \"image_url\": {\"url\": url, \"detail\": detail}}]}])\n",
      "note": "**A miss is lesson 8's request**, unchanged."
    },
    {
      "code": "    out = {\"text\": r.choices[0].message.content, \"tokens\": r.usage.prompt_tokens}\n    os.makedirs(CACHE, exist_ok=True)\n    json.dump(out, open(hit, \"w\"))\n    return out, \"provider\"\n\n\n",
      "note": "**The reply and the tokens it cost are written down before they are returned**, so the next identical question is a hit."
    },
    {
      "code": "for prompt in sys.argv[2:]:\n    out, source = describe(sys.argv[1], prompt)\n    print(\"%-8s %4d tokens  %s\" % (source, out[\"tokens\"], out[\"text\"][:48]))",
      "note": "**One picture, several prompts**, each printed with where its answer came from."
    }
  ]
}
```

```
ana@lab:~/mm$ python cached.py media/invoice-0931.png "What is the total?" "What is the total?" "What is the total of this invoice?"
provider 1113 tokens  The invoice is INV-0931 from Lantern & Quill Dis
cache    1113 tokens  The invoice is INV-0931 from Lantern & Quill Dis
provider 1116 tokens  The invoice is INV-0931 from Lantern & Quill Dis
ana@lab:~/mm$ grep -c chat/completions /var/log/labmm/requests.jsonl
2
```

Three questions, two requests in labmm's log. The second "What is the total?" came from the cache. The third question means the same thing in other words and **missed**, because the key is the exact prompt: a cache by meaning is possible, by embedding the prompt as lesson 12 embedded pieces, and it can then return an answer to a question that only looked similar. The reply itself is lesson 8's rule `l08-invoice-high`, written by the course.

A cache holds the provider's answers, which can hold personal data from the pictures. It needs the same retention and erasure rules as the pictures do.

The second habit is a **budget checked before the call**. A per-user monthly allowance, in integer cents as this platform keeps its own money, and an estimate made from the sheet's unit before anything is sent:

```python
"""A monthly allowance per user, in integer cents, checked BEFORE the call rather than after."""
from decimal import ROUND_CEILING, Decimal

PER_SECOND = Decimal("0.0001")   # sheet: whisper-1 input_cost_per_second, in dollars
ALLOWANCE = 50           # cents a user may spend in a month

spent = {"ana": 47}


def charge_cents(seconds):
    cents = Decimal(str(seconds)) * PER_SECOND * 100
    return int(cents.to_integral_value(rounding=ROUND_CEILING))   # UP: an estimate that undercharges is a leak


def transcribe(user, seconds):
    cost = charge_cents(seconds)
    if spent.get(user, 0) + cost > ALLOWANCE:
        return f"refused: {seconds} s costs {cost} cents and {user} has {ALLOWANCE - spent.get(user, 0)} left"
    spent[user] = spent.get(user, 0) + cost
    return f"sent: {seconds} s for {cost} cents, {user} has {ALLOWANCE - spent[user]} left"


for seconds in (55.38, 600, 1800):
    print(transcribe("ana", seconds))
```

```
ana@lab:~/mm$ python -c "print(600 * 0.0001 * 100)"
6.000000000000001
ana@lab:~/mm$ python budget.py
sent: 55.38 s for 1 cents, ana has 2 left
refused: 600 s costs 6 cents and ana has 2 left
refused: 1800 s costs 18 cents and ana has 2 left
```

The one-minute call costs one cent and is sent. Ten minutes would cost six cents against two left and is refused before any audio leaves. Three choices in it are deliberate. The estimate **rounds up**, because an estimate that rounds down lets every call through a fraction of a cent cheap, and a thousand of them add up. And the check is **before** the call: a budget read after the bill arrives is a report, not a limit.

The third is `Decimal`, and the first line of the capture is why. In floating point, 600 seconds at $0.0001 is 6.000000000000001 cents, and rounding up turns that into **7**. The first version of this program did exactly that, and every ten-minute call was refused a cent early. Money is never a float, which is the same rule this platform keeps for its own.
