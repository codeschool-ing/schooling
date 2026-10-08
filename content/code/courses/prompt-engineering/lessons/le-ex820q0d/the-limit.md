---
title: A limit that cuts the loop
version: 2
---

A maximum on output tokens is easy to mistake for a length instruction, as if setting it to 50
asked the model for a fifty-token answer. It asks for nothing. **The model writes exactly as it
would have, and the loop is stopped when the count reaches the limit**, wherever in a sentence
that happens to fall. The model never learns that a limit existed.

Lesson 1 showed the two ways generation ends: the model picks the end, or a limit is reached.
`toylm` reports which one in its last line. Without a tight limit the model finishes on its own:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0
soup, bread and cake.
-- finish: end, prompt 3 tokens, output 6 tokens
```

With `--max-tokens 3`:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0 --max-tokens 3
soup, bread
-- finish: length, prompt 3 tokens, output 3 tokens
```

`finish: length` says the loop was stopped from outside. The three tokens were `soup`, the comma
and `bread`, and the fourth was never generated.

## Some loops never end on their own

The limit is also what stops a model that would otherwise go on for ever. At temperature 0,
`toylm` writes this after `the cat`:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

After `cat sleeps` the likeliest word is `and`, after `and the` it is `cat`, and after `the cat`
it is `sleeps` again, so greedy decoding goes round the same circle. **Without the limit the
loop would never end.** A large model can fall into the same kind of circle, repeating a line or
a list item, and the limit is what turns a request that would never return into one that returns
too much. Lesson 17 shows the controls that discourage the circle in the first place.

## A truncated answer looks finished

Read the output of the `--max-tokens 3` run again without its last line: *the menu has soup,
bread*. It is a grammatical sentence, and it says something false, because the menu also has
cake. **A cut answer rarely looks cut.** A list stops after an item, a paragraph stops after a
sentence, a set of steps stops before the step that mattered, and a reader who does not check the
reason goes on as if it were complete.

So the rule for code that calls a model is plain: **check why it stopped before you use what it
wrote.** Every model API returns a finish reason of some kind, under its own name; `toylm` calls
it `finish`, and `length` is the value that means "this was cut". Treat that value as an error or
a retry with a higher limit, never as an answer.

## A cut JSON object is not JSON

Structured output makes the problem visible instead of silent, which is better and still a
failure. Here is a request that asks the model to classify one review as a JSON object, and the
schema its reply should match, both small enough to type:

```
ana@lab:~/pe$ cat request.txt review.schema.json
You read customer reviews of Café Aurora. For the review below, reply with
one JSON object with three fields: "sentiment" (positive, neutral or
negative), "topic" (two or three words) and "summary" (one sentence).
Reply with the object and nothing else.

Review:
Waited fifteen minutes for a tea at noon. The staff were kind about it.
{
  "type": "object",
  "required": ["sentiment", "topic", "summary"],
  "properties": {
    "sentiment": {"enum": ["positive", "neutral", "negative"]},
    "topic": {"type": "string"},
    "summary": {"type": "string"}
  }
}
```

`ask --json` asks for a JSON object and nothing else. The reply, as it came, and then the same
request with a limit of 20 tokens:

```
ana@lab:~/pe$ ask - --json --temperature 0 < request.txt
{"sentiment": "positive", "topic": "long wait", "summary": "Customer waited 15 minutes for a tea at noon, but staff were kind about the delay."}
-- llama3.2:3b, finish: stop, prompt 104 tokens, output 39 tokens
ana@lab:~/pe$ ask - --json --temperature 0 --max-tokens 20 < request.txt
{"sentiment": "positive", "topic": "long wait", "summary": "Customer waited
-- llama3.2:3b, finish: length, prompt 104 tokens, output 20 tokens
```

The first reply took 39 tokens and stopped by itself. The second stopped at 20 with
`finish: length`, in the middle of the summary, and nothing about the text says so except that it
looks unfinished. Save both, with `--plain` to leave out the accounting line:

```
ana@lab:~/pe$ ask - --json --temperature 0 --plain < request.txt > reply.json
ana@lab:~/pe$ ask - --json --temperature 0 --max-tokens 20 --plain < request.txt > cut.json
```

`validate` checks a file against a schema, with the `jsonschema` library lesson 1 installed. Save
it as `~/pe/bin/validate` and make it executable:

```python
#!/usr/bin/env python3
"""validate SCHEMA FILE: is FILE valid JSON, and does it match SCHEMA?

Every problem is listed with the path to the field it is about, so a program
(or a person) can say exactly what to fix. Exit status 0 means valid.
"""
import json
import sys

from jsonschema import Draft202012Validator

schema_path, data_path = sys.argv[1:3]
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
try:
    with open(data_path, encoding="utf-8") as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print("not JSON: %s" % e)
    sys.exit(1)
errors = sorted(Draft202012Validator(schema).iter_errors(data), key=lambda e: list(e.path))
for e in errors:
    where = "/".join(str(p) for p in e.path) or "(top level)"
    print("%s: %s" % (where, e.message))
print("valid" if not errors else "%d problem%s" % (len(errors), "" if len(errors) == 1 else "s"))
sys.exit(1 if errors else 0)
```

The complete object passes the schema check, and the cut one is not JSON at all:

```
ana@lab:~/pe$ validate review.schema.json reply.json
valid
ana@lab:~/pe$ validate review.schema.json cut.json
not JSON: Invalid control character at: line 1 column 76 (char 75)
```

**A limit that is fine for prose can be fatal for JSON**, because prose cut short is still prose
and an object cut short is not an object. Set the limit with room above the largest reply you
expect, and still check the finish reason, because "largest reply you expect" is a guess.

Look at the valid one again, too. `"sentiment": "positive"`, for a customer who waited fifteen
minutes for a tea: the schema allows `positive`, so `validate` passed it, and a person would not.
**Valid is a statement about shape, not about truth.** Lessons 18 and 19 are about structured
output and about validating and repairing it, and the second ends on exactly this gap.
