---
title: A pipeline written down as a file
version: 2
---

Because every component declares its parameters and every connection is named, a Haystack pipeline
can be written out as YAML and loaded back. `hs_dump.py` imports the pipeline from `hs_ask.py` and
prints `rag.dumps()`:

```schooling-example
{
  "language": "python",
  "file": "hs_dump.py",
  "parts": [
    {
      "code": "from hs_ask import rag\n\nprint(rag.dumps())",
      "note": "The pipeline of `hs_ask.py`, written out by Haystack itself as YAML."
    }
  ]
}
```

```
ana@vm:~/rag$ python hs_dump.py > rag.yaml; wc -l rag.yaml
115 rag.yaml
```

The first component, as written:

```
ana@vm:~/rag$ head -n 18 rag.yaml
components:
  embed:
    init_parameters:
      api_base_url: null
      api_key:
        env_vars:
        - OPENAI_API_KEY
        strict: true
        type: env_var
      dimensions: null
      http_client_kwargs: null
      max_retries: null
      model: all-minilm
      organization: null
      prefix: ''
      suffix: ''
      timeout: null
    type: haystack.components.embedders.openai_text_embedder.OpenAITextEmbedder
```

**The key is not in the file.** `api_key` is written as the name of the environment variable to read
it from, `OPENAI_API_KEY`, with `strict: true` meaning that a missing variable is an error rather
than a silent anonymous call. Haystack keeps secrets in a type of their own for this reason, and a
secret created from a literal key cannot be written out at all: serialising it is refused. A file
that describes a pipeline can then be committed, reviewed and diffed without leaking anything.

Every other parameter is written too, including the ones nobody set: `api_base_url: null` says that
the address comes from the environment, and `max_retries: null` that the SDK's own default applies.
A reviewer reading this file sees the defaults, which is exactly what lesson 10 had to dig for.

```
ana@vm:~/rag$ grep -n -A 11 "      filters:" rag.yaml
90:      filters:
91-        conditions:
92-        - field: meta.status
93-          operator: ==
94-          value: current
95-        - field: meta.audience
96-          operator: ==
97-          value: public
98-        operator: AND
99-      return_embedding: false
100-      scale_score: false
101-      top_k: 3
ana@vm:~/rag$ sed -n "/^connections:/,\$p" rag.yaml
connections:
- receiver: retrieve.query_embedding
  sender: embed.embedding
- receiver: floor.documents
  sender: retrieve.documents
- receiver: prompt.documents
  sender: floor.documents
- receiver: generate.messages
  sender: prompt.prompt
max_runs_per_component: 100
metadata: {}
```

The filter from lesson 6, the `top_k` of 3 and the four connections, readable by anybody who knows
what a retriever is. A change of `top_k` or of the floor is a one-line diff in a pull request, and
lesson 8's test can run against the file the pull request changes.

## What the file is not

**It is not the index.** The store is written as its settings, never its documents; this store
lives in memory and was saved to `store.json` separately by the indexing program. A store backed by
a database would be written as its connection, and the chunks stay in the database. Loading the YAML
gives the same pipeline over whatever the store holds at that moment.

**It is code.** Each component is written with the import path of its class, `hs_floor.Floor` among
them, and loading the file imports and builds every class it names. So a pipeline file is treated
like a program: loaded only from the team's own repository, reviewed like any other change, and
never accepted from a user, an upload or a request. The same is true of any system that builds
objects from a file naming them.
