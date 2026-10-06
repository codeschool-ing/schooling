---
title: What happens when a reply fails, and the limits around it
version: 1
---

A validator that rejects a reply has only done half the job. **The code also has to decide what
happens next**, and the two easy answers are both wrong: showing the reply anyway defeats the
validator, and showing the client an error for every rejection makes the feature unusable on the
days the model is having trouble.

The usual answer is to ask once more and tell the model what was wrong, then stop. The loop in the
lab is eight lines:

```schooling-example
{"language": "python", "file": "guardlab/retry.py", "parts": [
 {"code": "def ask(call, check, attempts=2):\n    feedback = []\n", "note": "`call` asks the model and returns its text; `check` returns the list of problems, empty when the reply passes. `attempts` is a hard limit, and two is the usual choice."},
 {"code": "    for n in range(1, attempts + 1):\n        text = call(feedback)\n        problems = check(text)\n        yield n, problems\n", "note": "Each attempt is checked by the same rules. The caller sees every attempt, so that each one can be logged."},
 {"code": "        if not problems:\n            return\n        feedback = problems\n", "note": "A reply that passes ends the loop. One that fails hands its problems to the next call, which can put them in the prompt: the validator's messages are written to be read by the model as well as by a person."}
]}
```

In the lab, `guard retry` runs this loop with **replies the course wrote standing in for the model's
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
