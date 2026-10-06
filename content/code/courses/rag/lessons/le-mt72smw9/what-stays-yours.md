---
title: What stays yours
version: 1
---

A framework is worth what it saves minus what it hides, and this lesson has measured both.

## What it saves

**Connectors.** Both libraries ship readers for files, web pages and dozens of services, and
clients for dozens of vector stores and providers behind one interface. Moving from pgvector to
another store, or from one provider to another, is a change of a class name rather than a rewrite.
For a team that has not yet settled its store or its provider, that is real.

**Techniques already written.** The sentence window and auto-merging took one line each in this
lesson and would take an afternoon each to write and test by hand. So would hybrid retrieval,
rerankers and query rewriting, which both libraries have as parts.

**A shared vocabulary.** "A retriever with a post-processor" means the same thing to anybody who
has used LlamaIndex, which matters on a team where people come and go.

## What it hides

Every surprise in this lesson was a default, and none of them announced itself:

| part | its default | what the measured pipeline does |
| --- | --- | --- |
| LangChain's splitter | 4,000 characters, front matter included | 60 words inside headings, front matter as columns |
| LangChain's embedding client | token numbers, long texts split and averaged | the text, never longer than the model reads |
| `PGVector` | a random id per load | an id from the document and the text |
| `PGVector` scores | a distance, lower is better | a similarity, with a floor of 0.5 |
| LlamaIndex's clients | `OPENAI_API_BASE`, else OpenAI | the address the team configured |
| LlamaIndex's splitter | 1,024 tokens, 200 overlapping | 60 words |
| LlamaIndex's prompt | never reference the context | cite every sentence |
| both | no filter on status or audience | current and public only |

Each line is a decision lessons 4 to 8 made with a measurement behind it. A framework makes the same
decisions with no measurement, because it has never seen the documents, and a pipeline assembled
from defaults reads well in a demonstration and fails on the questions nobody tried.

They also **change between versions**. Every class name in this lesson is from the versions pinned
in the lab; `langchain-postgres` is still numbered 0.0.18, and a version below 1 promises nothing
about the next one. A default that changes in an upgrade changes the pipeline's behaviour with
nothing in the team's code changing. So pin the versions, and run lesson 8's test after every
upgrade as well as after every change of your own.

## A way to use one

- **Read what it sends.** The prompt, the address, the shape of the embedding request. labgen's log
  in this lab, and a provider's own request log or a proxy in production, show the request as it
  left, which is the only version that matters.
- **Set every value lessons 4 to 8 measured**, explicitly, even when it equals the default, so that
  the next upgrade cannot move it without the code saying so.
- **Keep the test outside the framework.** The questions, the facts and the rule for a hit live in
  `eval.jsonl` and a few lines of `frameworks.py`, not in either library, so the next pipeline
  somebody proposes is measured by the same rules as this one.
- **Write the decisions yourself**: the ids, the filter, the floor, the refusal, the citations. In
  this lesson they were a dictionary, a threshold and an `if`, and they are what made the
  framework's pipeline answer the way lesson 8 measured.

Lesson 11 does the same with two more, Haystack and RAGFlow, and they answer the same questions in
different ways. The questions stay.
