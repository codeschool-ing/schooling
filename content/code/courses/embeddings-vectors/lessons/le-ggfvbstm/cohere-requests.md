---
title: Calling Cohere's embed endpoint
version: 1
---

Cohere's SDK, `cohere`, sends the same request in different words: `texts` where Google says
`contents`, `input_type` where Google says `task_type`. The one difference that is not a name is
that **Cohere will not embed a text until you say what it is for.** Google's `task_type` is
optional; Cohere's `input_type` is required by its embed models from version 3 on.

`ClientV2` takes the key and, here, labembed's address. Against Cohere you leave `base_url` out and
use a real model name, such as `embed-v4.0`:

```schooling-example
{
  "language": "python",
  "file": "cohere_embed.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport cohere"
    },
    {
      "code": "co = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])",
      "note": "`ClientV2` is the SDK's client for version 2 of Cohere's API. `base_url` sends it to labembed."
    },
    {
      "code": "help = [json.loads(line) for line in open(\"data/help.jsonl\")]\nr = co.embed(\n    model=\"lab-minilm\",\n    texts=[h[\"title\"] + \". \" + h[\"body\"] for h in help],\n    input_type=\"search_document\",\n    embedding_types=[\"float\"],\n)\nprint(len(r.embeddings.float_), len(r.embeddings.float_[0]))\nprint(\"billed:\", int(r.meta.billed_units.input_tokens), \"tokens\")",
      "note": "The 40 articles in one call, each as title and body, declared as documents to be searched. Print how many vectors came back, how long each is, and what the call was billed."
    },
    {
      "code": "def embed_all(texts, input_type, size=96):\n    out = []\n    for i in range(0, len(texts), size):\n        r = co.embed(model=\"lab-minilm\", texts=texts[i:i + size],\n                     input_type=input_type, embedding_types=[\"float\"])\n        out += r.embeddings.float_\n        print(f\"  call {i // size + 1}: {len(texts[i:i + size])} texts\")\n    return out",
      "note": "Any list, however long, in slices of at most 96, one call per slice. The vectors are appended in the order the texts were sent."
    },
    {
      "code": "tickets = [json.loads(line)[\"text\"] for line in open(\"data/tickets.jsonl\")]\nvectors = embed_all(tickets, \"classification\")\nprint(len(vectors), \"vectors\")",
      "note": "The 150 tickets, as inputs to a classifier."
    }
  ],
  "output": "ana@lab:~/emb$ python cohere_embed.py\n40 384\nbilled: 2296 tokens\n  call 1: 96 texts\n  call 2: 54 texts\n150 vectors"
}
```

**The vectors are in `r.embeddings.float_`, with a trailing underscore.** The response holds one
list per encoding you asked for, and `float` is a Python built-in, so the SDK names that attribute
`float_` and the others `int8`, `ubinary` and so on. The section on quantised outputs asks for several
encodings at once; here `embedding_types=["float"]` asks for the ordinary one. `meta.billed_units`
is what the call would be charged for: 2,296 tokens for the 40 articles, counted with the lab's own
model, so a real provider's count for the same text would differ.

## Ninety-six texts at a time

The 40 articles went in one call. The 150 tickets did not, because **Cohere documents a limit of 96
texts per call**, and labembed enforces the same number. `embed_all` cuts the list into slices of
96 and sends one call per slice, which is the loop every batch job against this endpoint needs.
Here it made two calls, 96 texts and then the 54 left over, and the 150 vectors came back in order.

The tickets went in as `classification`, not `search_document`, because lesson 4 uses ticket
vectors as features for a classifier rather than as things to search. The next section lists the
four input types and when each applies.

## Two refusals, and where each happens

```schooling-example
{
  "language": "python",
  "file": "cohere_errors.py",
  "parts": [
    {
      "code": "import os\nimport cohere\n\nco = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])\ntry:\n    co.embed(model=\"lab-minilm\", texts=[\"Audiobooks\"])\nexcept TypeError as e:\n    print(\"TypeError:\", e)\ntry:\n    co.embed(model=\"lab-minilm\", texts=[\"Audiobooks\"] * 97, input_type=\"search_document\")\nexcept cohere.errors.BadRequestError as e:\n    print(e.status_code, e.body)",
      "note": "A call with no `input_type`, and a call with one text too many."
    }
  ],
  "output": "ana@lab:~/emb$ python cohere_errors.py\nTypeError: V2Client.embed() missing 1 required keyword-only argument: 'input_type'\n400 {'message': 'too many texts: 97 (the limit is 96)'}"
}
```

**The missing `input_type` never reached the server.** The SDK declares it as a required keyword
argument, so Python refuses the call with a `TypeError` before any request is built. The same
request sent by hand, without the SDK, gets the server's own answer, which is the HTTP version of
the same rule:

```
ana@lab:~/emb$ cat no-type.json
{"model": "lab-minilm", "texts": ["Audiobooks"]}
ana@lab:~/emb$ curl -s -w " %{http_code}\n" -H "authorization: Bearer $CO_API_KEY" -H "content-type: application/json" -d @no-type.json $CO_API_URL/v2/embed
{"message": "input_type is required for embed models v3 and higher"} 400
```

The 97 texts did reach the server, and it answered with a 400 whose body names the limit. The SDK
raises it as `cohere.errors.BadRequestError`, with `status_code` and `body` to read. A batch job
that hits it has a bug rather than bad luck: the slice size is wrong, and retrying the same call
can never succeed.
