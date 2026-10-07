---
title: Thirty days, unless you say otherwise
version: 1
---

A conversation kept on OpenAI's side is a conversation **stored** on OpenAI's side, and the
library's documentation says for how long:

```
ana@desk:~/desk$ python doc.py store
store: Whether to store the generated model response for later retrieval via API.
    Defaults to true when omitted. If set to true, response data will be stored for
    at least 30 days, subject to the
    [data retention exceptions](https://developers.openai.com/api/docs/guides/your-data#v1responses).
```

Stored is the default. Every response ana creates without saying otherwise, e-mail and all, is kept
for at least thirty days, and can be fetched again by anybody holding the key and the id. For
Lantern Books that is lesson 2 section 07's question with a new answer: the e-mail goes to OpenAI,
and stays. `forget.py` exercises the two ways out:

```python
import json

from openai import OpenAI, NotFoundError, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

kept = client.responses.create(model="llama3.2:3b", instructions=prompt, input=case["text"])
print("stored:   ", client.responses.retrieve(kept.id).output_text)
client.responses.delete(kept.id)
try:
    client.responses.retrieve(kept.id)
except NotFoundError as e:
    print("deleted:  ", e.status_code, e.body["message"])

once = client.responses.create(model="llama3.2:3b", instructions=prompt, input=case["text"], store=False)
try:
    client.responses.create(model="llama3.2:3b", previous_response_id=once.id, input="Thanks.")
except BadRequestError as e:
    print("store=False:", e.status_code, e.body["message"])
```

```
ana@desk:~/desk$ python forget.py 2>&1 | tail -1
openai.NotFoundError: 404 page not found
ana@desk:~/desk$ python relay.py show --count 2
POST /v1/responses -> 200 llama3.2:3b
GET /v1/responses/resp_977775 -> 404 
```

Against Ollama the program stops at its first `retrieve`, and the relay shows why: the response was
created, and the `GET` that asks for it back is a 404. **Ollama keeps nothing**, so there is nothing
to retrieve, delete or chain from, and a local server answers this section's question in the
simplest way there is. Against OpenAI, the docstring says the program's three steps go the other
way: the response is stored and comes back, **delete after use** removes it so the next `retrieve`
is a 404, and **never store it**, `store=False`, leaves nothing to fetch and nothing to chain from.

The two are not equivalent in what they promise. Deleting removes what the API returns; what the
provider keeps for its own purposes is governed by its data policy, which the docstring's link
points to and which this machine could not read. That is the document to read before customers'
e-mail goes anywhere.

For ana's sorting the choice is easy: every request stands alone, so `store=False` costs nothing.
For a conversation she wants kept, the alternative is the Chat Completions habit: keep the history
in her own database and send it every time.
