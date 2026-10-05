---
title: Thirty days, unless you say otherwise
version: 1
---

A conversation kept on OpenAI's side is a conversation **stored** on OpenAI's side, and the
library's documentation says for how long:

```
ana@desk:~/desk$ python lab/doc.py store
store: Whether to store the generated model response for later retrieval via API.
    Defaults to true when omitted. If set to true, response data will be stored for
    at least 30 days, subject to the
    [data retention exceptions](https://developers.openai.com/api/docs/guides/your-data#v1responses).
```

Stored is the default. Every response ana creates without saying otherwise, e-mail and all, is kept
for at least thirty days, and can be fetched again by anybody holding the key and the id. For
Lantern Books that is lesson 2 section 07's question with a new answer: the e-mail goes to OpenAI,
and stays. `lab/forget.py` exercises the two ways out:

```python
import json

from openai import OpenAI, NotFoundError, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

kept = client.responses.create(model="standin-small", instructions=prompt, input=case["text"])
print("stored:   ", client.responses.retrieve(kept.id).output_text)
client.responses.delete(kept.id)
try:
    client.responses.retrieve(kept.id)
except NotFoundError as e:
    print("deleted:  ", e.status_code, e.body["message"])

once = client.responses.create(model="standin-small", instructions=prompt, input=case["text"], store=False)
try:
    client.responses.create(model="standin-small", previous_response_id=once.id, input="Thanks.")
except BadRequestError as e:
    print("store=False:", e.status_code, e.body["message"])
```

```
ana@desk:~/desk$ python lab/forget.py
stored:    other
deleted:   404 Response with id 'resp_lab_0006' not found.
store=False: 400 Previous response with id 'resp_lab_0010' not found.
```

**Delete after use**, and the response is gone from the API: the next `retrieve` is a 404. **Or
never store it**: `store=False`, and there is nothing to fetch and nothing to chain from, as the
last line shows. The two are not equivalent in what they promise. Deleting removes what the API
returns; what the provider keeps for its own purposes is governed by its data policy, which the docstring's link points to and which this machine could not
read. That is the document to read before customers' e-mail goes anywhere.

For ana's sorting the choice is easy: every request stands alone, so `store=False` costs nothing.
For a conversation she wants kept, the alternative is the Chat Completions habit: keep the history
in her own database and send it every time.
