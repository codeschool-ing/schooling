---
title: Haystack's components, and ids made of content
version: 1
---

**Haystack**, from deepset, takes a stricter line than the two libraries of lesson 10. Everything
is a **component**: a class with a `run` method whose inputs and outputs are declared with their
types. A **pipeline** is a graph of named components, and every connection between two of them is
checked when it is made. The lab pins `haystack-ai` 3.3.0.

## A connection that does not fit

Connecting the text embedder's output straight to the chat generator is nonsense, since a vector is
not a conversation, and Haystack says so before anything runs:

```
ana@lab:~/rag$ python hs_wrong.py
PipelineConnectError: Cannot connect 'embed.embedding' with 'generate.messages': their declared input and output types do not match. 'embed': - embedding: list[float] 'generate': - messages: list[ChatMessage] | str (available)
```

The error names both ends and both types: a `list[float]` cannot go where a `list[ChatMessage]` is
expected. LangChain's `|` would have joined the two and failed at the first question, with an error
from inside the model client. A pipeline that cannot be built is a cheaper failure than one that
breaks when a customer uses it.

## Indexing as a pipeline

Indexing is a pipeline too: split, embed, write. The program loads the corpus, loads it again, and
then changes one field of one document's metadata, the owner of the returns policy, and loads that
document alone:

```schooling-example
{
  "language": "python",
  "file": "hs_index.py",
  "parts": [
    {
      "code": "import sys\n\nfrom haystack import Pipeline\nfrom haystack.components.embedders import OpenAIDocumentEmbedder\nfrom haystack.components.preprocessors import DocumentSplitter\nfrom haystack.components.writers import DocumentWriter\nfrom haystack.document_stores.in_memory import InMemoryDocumentStore\nfrom haystack.document_stores.types import DuplicatePolicy\nfrom hs_docs import docs",
      "note": "A pipeline, three components and a store that lives in memory. `hs_docs.py` reads the front matter into metadata, as `lc_load.py` did in lesson 10."
    },
    {
      "code": "store = InMemoryDocumentStore()\npolicy = DuplicatePolicy.OVERWRITE if \"--overwrite\" in sys.argv else DuplicatePolicy.NONE\nindexing = Pipeline()\nindexing.add_component(\"split\", DocumentSplitter(split_by=\"word\", split_length=60))\nindexing.add_component(\"embed\", OpenAIDocumentEmbedder(model=\"lab-minilm\", progress_bar=False))\nindexing.add_component(\"write\", DocumentWriter(store, policy=policy))\nindexing.connect(\"split\", \"embed\")\nindexing.connect(\"embed\", \"write\")",
      "note": "Each component is added under a name and then connected by name. `connect` checks that what one sends is what the next accepts. `DuplicatePolicy.NONE` leaves the decision to the store, which for this store means refusing a duplicate."
    },
    {
      "code": "def load(documents):\n    try:\n        print(\"written:\", indexing.run({\"split\": {\"documents\": documents}})[\"write\"][\"documents_written\"])\n    except Exception as e:\n        print(type(e).__name__ + \":\", [line for line in str(e).splitlines() if line.startswith(\"Error:\")][0][:110])",
      "note": "Run the pipeline on some documents and print how many chunks were written, or the error's own line."
    },
    {
      "code": "load(docs)\nload(docs)\ndocs[7].meta[\"owner\"] = \"customer-service\"\nload(docs[7:8])\nprint(\"in the store:\", store.count_documents())\nstore.save_to_disk(\"store.json\")",
      "note": "Load everything, load it again, then change one metadata field of one document, the returns policy's owner, and load that document alone. The store is saved for the next program."
    }
  ]
}
```

The splitter is set to 60 words, lesson 4's size; its own default is 200 words with no overlap,
which the section on measuring comes back to. The embedder sends text, as the provider expects,
and reads the provider's address from `OPENAI_BASE_URL` like the `openai` SDK it is built on.

```
ana@lab:~/rag$ python hs_index.py
written: 110
PipelineRuntimeError: Error: ID '070820b895e5fb0107bb644c997975b17ee639273fdc05bbcd34657810edd9b8' already exists.
written: 14
in the store: 124
```

**The second load was refused**: a chunk with that id already exists. Haystack gives every
document an id when it is created, a SHA-256 hash of its content **and its metadata**, so the same
chunk always gets the same id, and with the default duplicate policy this store refuses to write
it twice. That is lesson 5's idea, ids made of the content, chosen as a default. LangChain's store,
with no ids passed, doubled.

Then the third line. One metadata field changed on one document, and **14 chunks were written as
new**, and the store went from 110 to 124. Because the metadata is part of the hash, a chunk whose
text did not change but whose owner did is a different id, so it is written beside the old one
instead of over it. The old 14 are still there, with the old owner.

```
ana@lab:~/rag$ python hs_index.py --overwrite
written: 110
written: 110
written: 14
in the store: 124
```

Overwriting does not help. The policy decides what happens when an id already exists, and these ids
are new, so the result is the same 124. Lesson 5 hashed the heading path and the text and nothing
else, and it updated metadata in place; that is why a change of status or audience in lesson 5 moved
a chunk out of the search instead of copying it. In Haystack the same effect needs either an id
built the way lesson 5 builds it, set on each document before writing, or a delete of the
document's old chunks first. The next section shows what the duplicate does to an answer.
