---
title: What goes back to the model
version: 2
---

The observation is the only way the world reaches the model, so what a tool returns shapes every step after it. It also travels in every later request, which makes its size a cost paid again at each step.

To measure that size in the model's own tokens, ask Ollama. This short program sends a text to `llama3.2:3b` without a chat template around it, lets it write one token, and prints how many tokens the text was. Save it as `~/agents/tokens.py`:

```python
"""tokens.py: how many tokens llama3.2:3b reads in the text on standard input, counted by Ollama."""
import json
import sys
import urllib.request


def count(text, model="llama3.2:3b"):
    body = {"model": model, "prompt": text, "raw": True, "stream": False, "options": {"num_predict": 1}}
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)["prompt_eval_count"]


if __name__ == "__main__":
    print(count(sys.stdin.read()))
```

Then measure the three observations this lesson met: the whole order, the three fields a refund question needs, and what `search_help` returns.

```
ana@lab:~/agents$ python -c "import json, shop; print(json.dumps(shop.get_order(\"M-1047\")))" | python tokens.py
105
ana@lab:~/agents$ python -c "import json, shop; o = shop.get_order(\"M-1047\"); print(json.dumps({k: o[k] for k in (\"status\", \"delivered_on\", \"total\")}))" | python tokens.py
28
ana@lab:~/agents$ python -c "import json, shop; print(json.dumps(shop.search_help(\"refund after a return\")))" | python tokens.py
230
```

The whole of M-1047, as `get_order` returns it, is 105 tokens. The three fields the refund question needs (`status`, `delivered_on`, `total`) are 28. The three help articles `search_help` returns are 230. Each count includes two tokens that are not the JSON, the one the model puts at the start of any text and the newline `print` leaves at the end, so the differences are exact and each total is two high. In a three-step run, an observation returned at step 1 is sent at steps 2 and 3 as well, so trimming it saves its tokens twice; in a twenty-step run, nineteen times. **Return what the model needs to decide the next step, and nothing it has to wade through.**

Trimming has a cost of its own: a field left out is a field the model cannot use. `customer_id` looks irrelevant to a refund question, and is exactly what lesson 17 needs to check that the person asking owns the order. The usual compromise is a tool per purpose (an order summary for the agent, the full record for code that needs it) rather than one tool that returns everything.

## Four rules for observations

- **Structured, and labelled.** `{"status": "delivered", "delivered_on": "2026-09-18"}` beats `delivered 2026-09-18`, because the model does not have to guess which date is which.
- **Units in the field name or the value.** `get_order` returns `"total": 7780` with nothing to say it is cents, and the model in section 03 invented a total of "120 cents" before it had seen any. `total_cents` would have said so; a tool that returns money with no unit invites a refund a hundred times too large.
- **Errors are observations too.** A failed lookup should come back as a short, specific message (*"no order M-9999"*) marked as an error, so the model can correct the id or ask the customer. Lesson 4 builds that, and it is what keeps a typo from becoming a crash.
- **Bounded.** A search that could return a thousand rows returns the top few and says how many there were. An observation that does not fit in the context window ends the run, and one that nearly fits leaves no room for the answer.

## Observations are not instructions

Everything a tool returns is text the model reads, and some of it was written by people who are not the user: a help article, a product review, a customer's earlier message. **A model can mistake text inside an observation for an instruction**, and that is how indirect prompt injection works (`prompt-engineering` lesson 7). Lesson 17 builds the defence in the host, where it belongs; for now the habit to form is to treat an observation as data that arrived from outside, whatever it says.
