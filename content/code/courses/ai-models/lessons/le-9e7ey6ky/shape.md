---
title: Three things every request carries
version: 1
---

Lesson 6 chose among the Claude models; this lesson is the API they all answer through, the
**Messages API**, and the `anthropic` library that calls it. api.anthropic.com is reachable from the
machine this course was recorded on, but a key is a bill a course cannot hand out, so what answers
below is the lab's stand-in, and what the library sends is real.

`lab/claude_sort.py` takes a prompt file, a case and a limit:

```python
import json
import sys

import anthropic

client = anthropic.Anthropic()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}
prompt_file, case_id, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])

r = client.messages.create(model="standin-large", max_tokens=max_tokens,
                           system=open(prompt_file).read(),
                           messages=[{"role": "user", "content": cases[case_id]["text"]}])
print(repr(r.content[0].text), r.stop_reason, f"{r.usage.input_tokens} in, {r.usage.output_tokens} out")
```

```
ana@desk:~/desk$ python lab/claude_sort.py prompts/triage.txt c05 16
'other' end_turn 51 in, 1 out
```

```
ana@desk:~/desk$ wire --headers anthropic-version,x-api-key,user-agent
POST /v1/messages
user-agent: Anthropic/Python 1.11.0
x-api-key: lab-anthropi…
anthropic-version: 2023-06-01

{
  "max_tokens": 16,
  "messages": [
    {
      "role": "user",
      "content": "Do you have a physical shop I can visit in Curitiba?"
    }
  ],
  "model": "standin-large",
  "system": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

Three things differ from OpenAI's shape. **`system` is a field of its own**, not a message with a
role. **`max_tokens` is required**: every request says how long the answer may be, where Chat
Completions has a default. And two headers carry the account and the version: `x-api-key`, and
`anthropic-version`, which the documentation fixes at one date:

```
ana@desk:~/desk$ sources quote claude-versioning "anthropic-version: 2023"
# https://platform.claude.com/docs/en/api/versioning, read 2026-10-05
 186: anthropic-version: 2023-06-01
```

The version header is what lets Anthropic change the API without breaking a program written
against an older shape: the program names the shape it was written for.

## Why it stopped

`stop_reason` says why the answer ended. `end_turn` is the model finishing. The other one to check
for is `max_tokens`, the limit reached. ana's extraction prompt, with room and then without:

```
ana@desk:~/desk$ python lab/claude_sort.py prompts/extract.txt c01 64
'{"order": "LB-20417"}' end_turn 71 in, 9 out
```

```
ana@desk:~/desk$ python lab/claude_sort.py prompts/extract.txt c01 8
'{"order": "LB-20417' max_tokens 71 in, 8 out
```

Eight tokens cut the JSON in half, and the reply is still a 200 with text in it. **A program that
reads the text without reading `stop_reason` tries to parse a broken object**, and for a reply in
prose, a cut sentence reads like a short one. Lesson 5 section 09 counted unparseable replies as failures; this is
the cheapest one to prevent: check `stop_reason`, and size `max_tokens` from the longest correct
answer in the cases, with room to spare.
