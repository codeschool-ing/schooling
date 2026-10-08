---
title: What happens when a reply fails, and the limits around it
version: 2
---

A validator that rejects a reply has only done half the job. **The code also has to decide what
happens next**, and the two easy answers are both wrong: showing the reply anyway defeats the
validator, and showing the client an error for every rejection makes the feature unusable on the
days the model is having trouble.

The usual answer is to ask once more and tell the model what was wrong, then stop. The loop is eight
lines, `retry_loop` below, and the rest of the program is the command that runs it. Save it as
`~/guard/tools/retry.py`:

```schooling-example
{"language": "python", "file": "tools/retry.py", "parts": [
 {"code": "import json\nimport os\nimport sys\n\nfrom shapes import check_output\n\n\ndef retry_loop(call, check, attempts=2):\n    feedback = []\n", "note": "`call` asks the model and returns its text; `check` returns the list of problems, empty when the reply passes. `attempts` is a hard limit, and two is the usual choice."},
 {"code": "    for n in range(1, attempts + 1):\n        text = call(feedback)\n        problems = check(text)\n        yield n, text, problems\n", "note": "Each attempt is checked by the same rules. The caller sees every attempt, with its text, so that each one can be logged."},
 {"code": "        if not problems:\n            return\n        feedback = problems\n", "note": "A reply that passes ends the loop. One that fails hands its problems to the next call, which can put them in the prompt: the validator's messages are written to be read by the model as well as by a person."},
 {"code": "\n\nif __name__ == \"__main__\":\n    # guard retry ID [ID ...]: the loop, with the replies named on the command\n    # line, from data/outputs.jsonl, standing in for the model's attempts.\n    data = os.path.expanduser(\"~/guard/data/\")\n    with open(data + \"output-schema.json\") as f:\n        schema = json.load(f)\n    with open(data + \"allowed-hosts.json\") as f:\n        hosts = json.load(f)\n    with open(data + \"outputs.jsonl\") as f:\n        texts = {o[\"id\"]: o[\"text\"] for o in map(json.loads, f)}\n    replies = iter(sys.argv[1:])\n\n    def call(feedback):\n        if feedback:\n            print(\"           sent back: %d problem(s) with the previous reply\" % len(feedback))\n        return texts[next(replies)]\n\n    def check(text):\n        return check_output(text, schema, hosts, 120000)\n\n    for n, _, problems in retry_loop(call, check, attempts=len(sys.argv) - 1):\n        print(\"attempt %d  %s\" % (n, \"ok\" if not problems else \"REJECT \" + problems[0]))\n        for p in problems[1:]:\n            print(\"                  %s\" % p)\n    if problems:\n        print(\"no valid reply after %d attempts: the job goes to a person\" % (len(sys.argv) - 1))\n        sys.exit(1)\n", "note": "The command, `guard retry`: the loop with replies from `data/outputs.jsonl`, named on the command line, standing in for the model's attempts. The budget is in-1's."}
]}
```

`guard retry` runs this loop with **replies the course wrote standing in for the model's
attempts**: the first ID on the command line is the first attempt, the second is the retry. No model
is called; what is real is the loop and the checks. A retry that works, and one that does not:

```
ana@lab:~/guard$ guard retry out-3 out-1; echo "exit $?"
attempt 1  REJECT $.category: 'illustration' is not one of design, development, writing, translation, marketing
           sent back: 1 problem(s) with the previous reply
attempt 2  ok
exit 0
ana@lab:~/guard$ guard retry out-2 out-7; echo "exit $?"
attempt 1  REJECT not JSON: Expecting value at character 0
           sent back: 1 problem(s) with the previous reply
attempt 2  REJECT $.summary: 607 characters, limit 400
                  $.skills: 7 items, limit 5
no valid reply after 2 attempts: the job goes to a person
exit 1
```

When the attempts run out, the job goes to a person, and **nothing from the rejected replies reaches
the client**. That is the rule that matters most in this section: a validator fails closed. A
reply that could not be checked is treated like a reply that failed, because the alternative is a
check that only works when nothing is wrong.

## The same loop with a real model

The replies above were written to be caught. This program asks `llama3.2:3b` for the real thing: it
sends a request from `data/inputs.jsonl` with the schema in the system prompt, asks for JSON only, and
runs the reply through the same `retry_loop` and `check_output`. Save it as `~/guard/tools/draft.py`:

```python
# draft.py: the job intake with a real model, its reply checked and retried once.
#
#   guard draft REQUEST_ID
#
# It sends one request from data/inputs.jsonl to the model, with the schema
# the reply must follow, and runs the reply through retry_loop() and
# check_output(). A failed reply's problems go back with the next attempt.
import json
import os
import sys

from ask import ask
from retry import retry_loop
from shapes import check_output

DATA = os.path.expanduser("~/guard/data/")
with open(DATA + "output-schema.json") as f:
    schema = json.load(f)
with open(DATA + "allowed-hosts.json") as f:
    hosts = json.load(f)
with open(DATA + "inputs.jsonl") as f:
    req = next(r for r in map(json.loads, f) if r["id"] == sys.argv[1])

SYSTEM = """You turn a client's job request on Tarefa, a freelance marketplace,
into one JSON object that follows this JSON Schema exactly, with no other text:

%s

The price is in cents of a real, and must not exceed twice the client's budget.
Links, if any, may only point at https://help.tarefa.example/.""" % json.dumps(schema)
REQUEST = json.dumps({k: v for k, v in req.items() if k != "id"})


def call(feedback):
    question = REQUEST
    if feedback:
        question += "\n\nYour previous reply had these problems; fix them:\n" + "\n".join(feedback)
    return ask(question, system=SYSTEM, json_only=True)


def check(text):
    return check_output(text, schema, hosts, req["budget_cents"])


for n, text, problems in retry_loop(call, check):
    print("attempt %d  %s" % (n, text))
    print("           %s" % ("ok" if not problems else "REJECT " + problems[0]))
    for p in problems[1:]:
        print("                  %s" % p)
if problems:
    print("no valid reply after 2 attempts: the job goes to a person")
    sys.exit(1)
```

```
ana@lab:~/guard$ guard draft in-1; echo "exit $?"
attempt 1  {"type": "object", "category": "design", "title": "Logo for a bakery", "summary": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "price_suggestion_cents": 60000, "skills": ["design"], "links": ["https://help.tarefa.example/"]}
           REJECT $: 'type' is not allowed
attempt 2  {"category": "design", "title": "Logo for a bakery", "summary": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "price_suggestion_cents": 60000, "skills": ["design"], "links": ["https://help.tarefa.example/"]}
           ok
exit 0
```

The first reply is well-formed JSON, and the check refused it: the model copied `"type": "object"`
from the schema into its own reply, a field the schema does not allow. The problem went back with the
second attempt, and the second reply passed. That is the loop doing what it is for, on a mistake
nobody wrote into a test file. Your run may fail differently, or pass the first time.

Look at what passed, too. The summary is the client's own sentence copied back, and the price is half
the budget. Nothing in the schema says a summary has to summarise, and no check here can say whether
R$ 600,00 is a fair price for a logo. **A reply that passes is a reply that is safe to show, not a reply
that is right**, and the second question is for whoever reviews the feature, with samples, the way
lesson 6 measured moderation.

## The limits that go with it

The retry loop is one of several limits, and each of them bounds a different way a model call can
run away:

| limit | what it bounds | where it was met |
|---|---|---|
| attempts per request | how often one request can be retried | the loop above |
| `max_tokens` on each call | the length, and so the cost, of one reply | the provider's API |
| length of each input field | the cost of the prompt, and how much the model has to read | the input rules |
| tokens per user per day | what one person can spend | lesson 7 |
| tool calls or turns per task | how far an agent can go before it stops | lesson 10 |

`max_tokens` deserves a note because it is easy to set too high on the grounds that a reply should
never be cut off. A reply that the schema caps at 400 characters of summary never needs thousands of tokens. A limit near what the schema allows turns a reply that rambles into one that fails quickly and cheaply, and the retry loop handles it from there.

## Count the rejections

Every rejection is logged under the request id, as lesson 11 recommends, with the path and the rule
that failed. Counted per day, rejections are one of the most useful numbers this feature produces.
A rate that rises after a prompt change or a model update is the earliest sign that something
changed, and it arrives before any client complains. The metrics tier from lesson 11 is the place for
it: a count per day, with no text in it, kept for as long as the other counts.
