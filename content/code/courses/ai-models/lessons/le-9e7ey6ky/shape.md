---
title: Three things every request carries
version: 1
---

Lesson 6 chose among the Claude models; this lesson is the API they all answer through, the
**Messages API**, and the `anthropic` library that calls it. api.anthropic.com is reachable from the
machine this course was recorded on, but a key is a bill a course cannot hand out. Ollama speaks
the same shape at `/v1/messages`, and lesson 1 section 04 already pointed `ANTHROPIC_BASE_URL` at
it, so the answers below are llama3.2:3b's and what the library sends is exactly what it would send
to Anthropic. Where Ollama behaves differently from what Anthropic documents, the section says so.

Every program in this lesson goes through the relay from lesson 9 section 03, so that what the
library sends can be read back. Start the relay in a second terminal, and in the one you work in,
send both libraries to it:

```
ana@desk:~/desk$ export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500
```

`claude_sort.py` takes a prompt file, a case and a limit:

```python
import json
import sys

import anthropic

client = anthropic.Anthropic()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}
prompt_file, case_id, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])

r = client.messages.create(model="llama3.2:3b", max_tokens=max_tokens,
                           system=open(prompt_file).read(),
                           messages=[{"role": "user", "content": cases[case_id]["text"]}])
print(repr(r.content[0].text), r.stop_reason, f"{r.usage.input_tokens} in, {r.usage.output_tokens} out")
```

```
ana@desk:~/desk$ python claude_sort.py prompts/triage.txt c05 16
'other.' end_turn 19 in, 3 out
```

```
ana@desk:~/desk$ python relay.py show --headers anthropic-version,x-api-key,user-agent
POST /v1/messages
user-agent: Anthropic/Python 1.11.0
x-api-key: ollama…
anthropic-version: 2023-06-01

{
  "max_tokens": 16,
  "messages": [
    {
      "role": "user",
      "content": "Do you have a physical shop I can visit in Curitiba?"
    }
  ],
  "model": "llama3.2:3b",
  "system": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

Your label may differ: the library sets no temperature, so the model samples. Three things differ
from OpenAI's shape. **`system` is a field of its own**, not a message with a role. **`max_tokens`
is required**: every request says how long the answer may be, where Chat Completions has a
default. And two headers carry the account and the version: `x-api-key`, which here holds the
placeholder `ollama` from `desk.env` and on Anthropic holds the key, and `anthropic-version`,
which the documentation fixes at one date:

```
# https://platform.claude.com/docs/en/api/versioning, read 2026-10-07
 186: anthropic-version: 2023-06-01
```

The version header is what lets Anthropic change the API without breaking a program written
against an older shape: the program names the shape it was written for.

## Why it stopped

`stop_reason` says why the answer ended. `end_turn` is the model finishing. The other one to check
for is `max_tokens`, the limit reached. ana's extraction prompt, with room and then without:

```
ana@desk:~/desk$ python claude_sort.py prompts/extract.txt c01 64
'{"order": "LB-20417"}' end_turn 79 in, 10 out
```

```
ana@desk:~/desk$ python claude_sort.py prompts/extract.txt c01 8
'{"order": "LB-20417' max_tokens 1 in, 8 out
```

Eight tokens cut the JSON in half, and the reply is still a 200 with text in it. **A program that
reads the text without reading `stop_reason` tries to parse a broken object**, and for a reply in
prose, a cut sentence reads like a short one. Lesson 5 section 09 counted unparseable replies as
failures; this is the cheapest one to prevent: check `stop_reason`, and size `max_tokens` from the
longest correct answer in the cases, with room to spare.

The `in` column moves for a reason section 04 explains: Ollama keeps what it has already read, and
`input_tokens` counts only what it had to read again.
