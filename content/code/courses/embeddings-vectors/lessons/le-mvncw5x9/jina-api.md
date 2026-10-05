---
title: Jina's embedding API
version: 1
---

Lesson 7 called OpenAI's embeddings endpoint and lesson 8 called Gemini's and Cohere's, each through
the provider's own SDK. Jina AI's endpoint needs no SDK of its own, because **it copies OpenAI's
shape**. A request is a `POST` to `/v1/embeddings` with a bearer token and a body with `model` and
`input`; in the answer, `data[i].embedding` holds the vectors and `usage` counts the tokens. What
Jina adds is a few fields of its own in the same body, and one of them changes the vector.

The program below calls it with `httpx`, the HTTP client the `openai` package already brought in.
The address and the key come from the environment. On this machine `JINA_BASE_URL` points at
**labembed**, the course's stand-in server on 127.0.0.1:8500. It answers Jina's request shape with
vectors from the two models the lab runs, under the lab's own model names, so the model here is
`lab-wordllama`. Against the real service the address would be `https://api.jina.ai/v1`, the key
one from Jina's dashboard and the model one of Jina's, such as `jina-embeddings-v3`. Nothing else in
the program changes.

```schooling-example
{
  "language": "python",
  "file": "jina.py",
  "parts": [
    {
      "code": "import os\nimport httpx\n\nurl = os.environ[\"JINA_BASE_URL\"] + \"/embeddings\"\nheaders = {\"Authorization\": \"Bearer \" + os.environ[\"JINA_API_KEY\"]}\n\ndef jina(texts, task, dimensions=None):\n    body = {\"model\": \"lab-wordllama\", \"task\": task, \"input\": texts}\n    if dimensions:\n        body[\"dimensions\"] = dimensions\n    return httpx.post(url, headers=headers, json=body)",
      "note": "The address and the key come from the environment, so the same file talks to labembed here and to api.jina.ai elsewhere. `jina()` builds the body Jina documents: a model, a task, the texts, and `dimensions` only when one is asked for."
    },
    {
      "code": "r = jina([\"how do I get my money back\"], \"retrieval.query\", dimensions=64)\nd = r.json()\nprint(r.status_code, len(d[\"data\"][0][\"embedding\"]), d[\"usage\"])",
      "note": "A question embedded as a query and cut to 64 dimensions. Print the status, the length of the vector and the tokens counted."
    },
    {
      "code": "text = [\"When your refund arrives\"]\nq = jina(text, \"retrieval.query\").json()[\"data\"][0][\"embedding\"]\np = jina(text, \"retrieval.passage\").json()[\"data\"][0][\"embedding\"]\nprint(\"query and passage identical:\", q == p)",
      "note": "One title embedded twice, once as a query and once as a passage, and the two vectors compared number by number."
    },
    {
      "code": "r = jina(text, \"retrieval.document\")\nprint(r.status_code, r.json()[\"error\"][\"message\"])",
      "note": "A task name Jina does not have. Print the status and the message that comes back."
    }
  ]
}
```

```
ana@lab:~/emb$ python jina.py
200 64 {'prompt_tokens': 7, 'total_tokens': 7}
query and passage identical: True
422 task must be one of ['classification', 'retrieval.passage', 'retrieval.query', 'separation', 'text-matching']
```

## Three fields worth knowing

**`dimensions` asks for a shorter vector.** The first line shows 64 numbers where WordLlama
returns 256. It works for the reason lesson 7 gave for OpenAI's parameter of the same name: the
model was trained so that the first numbers of its vector still work on their own. Jina documents
the same for jina-embeddings-v3, whose full vector has 1024 numbers.

**`task` says what the text is for.** Jina documents five values for jina-embeddings-v3:
`retrieval.query` for a search query, `retrieval.passage` for the text a search should find,
`text-matching` for comparing two texts on an equal footing, `classification`, and `separation`
for grouping texts into clusters. The model carries a small set of extra weights per task and uses
the set the task names, so one text gets one vector as a query and another as a passage. This is
the asymmetric search of lesson 8 under Jina's names: embed the help articles with
`retrieval.passage` and the customer's question with `retrieval.query`.

**The lab does not do that, and the second line shows it.** Both of the lab's models are
symmetric. labembed checks the task, records it, and computes the same vector whatever it says, so
`query and passage identical: True` is a fact about labembed and not about Jina. With
jina-embeddings-v3 the two vectors would differ, and that difference is the point of the field.

**A task Jina does not know is refused**, and labembed copies the refusal: the message lists the
five it accepts.
`retrieval.document` is the slip to expect from somebody who has just used Gemini's
`RETRIEVAL_DOCUMENT` or Cohere's `search_document`: Jina calls the same thing a passage. The status
is 422, where lessons 7 and 8 met 400 for a malformed request, so code that treats only a 400 as
"my request was wrong" will treat this one as something else.

labembed's log shows what it understood:

```
ana@lab:~/emb$ tail -n 4 /var/log/labembed/requests.jsonl | jq -c "{provider, task, dims, status}"
{"provider":"jina","task":"retrieval.query","dims":64,"status":200}
{"provider":"jina","task":"retrieval.query","dims":256,"status":200}
{"provider":"jina","task":"retrieval.passage","dims":256,"status":200}
{"provider":"jina","task":null,"dims":null,"status":422}
```

All four requests went to `/v1/embeddings`, the path an OpenAI request uses, and labembed told them
apart by the key alone: `provider` says `jina`. The first asked for 64 dimensions and the next two
got the full 256. The refused request has no task recorded, because labembed turned it away before
accepting one.

## Late chunking, described and not run

Lesson 3 cuts a long document into chunks and embeds each chunk on its own. That loses context: a
chunk saying *it arrives in five working days* no longer says what *it* is. Jina's `late_chunking`
field is aimed at exactly that. With it set, the model reads the chunks of one request together, as
one text, and only then averages each chunk's share of the pieces into its own vector. Lesson 9
showed that average, the mean pooling at the end of the model; late chunking moves the cut to after
the layers instead of before them, so each chunk's vector has seen its neighbours.

```python
r = httpx.post("https://api.jina.ai/v1/embeddings",
               headers={"Authorization": "Bearer " + os.environ["JINA_API_KEY"]},
               json={"model": "jina-embeddings-v3", "task": "retrieval.passage",
                     "late_chunking": True, "input": chunks})
```

**This was not run.** api.jina.ai is out of reach from the machine this course was recorded on,
and labembed ignores the field, so nothing here measures whether it helps. The course `rag` takes
chunking further.

## The price is not on the sheet

Every price in this course comes from one place, LiteLLM's sheet at commit b9e71e990aed, which
lesson 7's `prices.py` reads. The next section searches that sheet for Jina, and the only row
naming it is a reranker, not an embedding model. **So this lesson quotes no price for Jina.** Read
it on Jina's own pricing page on the day you decide, and write down the date beside it.
