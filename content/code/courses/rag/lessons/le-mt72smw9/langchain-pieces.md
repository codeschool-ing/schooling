---
title: LangChain's pieces, and what they decide
version: 1
---

Lesson 9 built the pipeline from the provider's SDK, a database driver and about a hundred lines of
Python. **LangChain** and **LlamaIndex** are the two best-known libraries that package those same
steps as parts with a common shape: a loader, a splitter, an embedding client, a vector store, a
retriever, a prompt template, a model client. Swapping one store or provider for another is then
a change of one line, and that is the main thing they sell.

This lesson builds the pipeline again with each of them and asks one question of every part: **what
did it decide that lessons 4 to 8 decided by measuring?** A framework never leaves a value empty. A
default chosen by somebody who has never seen your documents is still a decision, and it is made
without anybody noticing. The versions are pinned in the lab (`langchain-core` 1.6.6,
`llama-index-core` 0.14.25), and both libraries change fast, so the names on this page will move.
The questions are what lasts.

## The splitter

LangChain's usual splitter is `RecursiveCharacterTextSplitter`. It tries to cut at a blank line,
then at a line break, then at a space, and only then inside a word, so a chunk ends at the largest
boundary that keeps it under the size. That is lesson 4's preference for structure, without the
headings. Here it is with nothing set, and then with a size chosen to match lesson 4:

```
ana@lab:~/rag$ python lc_split.py | head -n 20
{'chunk_size': 4000, 'chunk_overlap': 200, 'length_function': <built-in function len>}
 14 chunks, 491 words on average
132 chunks,  54 words on average
---
id: affiliate-api
title: Affiliate API reference
audience: developers
owner: platform
updated: 2026-02-10
version: 2.3
status: current
---

# Affiliate API reference

The affiliate API lets partner sites look up books, build tracked links and read their commission
reports. This is version 2.3 of the reference.

## Base URL and authentication
```

The first line is the signature of the base class: **4,000 by default, and measured with `len`, so in
characters**, not words or tokens. On Marginalia's thirteen documents that makes 14 chunks of 491
words on average, which is a document or most of one per chunk. Lesson 4 measured where that end of
the scale goes: the 240-word row found everything and sent 768 tokens per question, and whole
documents are lesson 1's "why not put everything in the prompt" with extra steps. At 400 characters the chunks
average 54 words, close to the 60 that lesson 4 chose.

The printed chunk shows the other thing the splitter does not know: **front matter**. The block
between the `---` lines is text to it, so the document's id, audience and status are cut, embedded
and searched as if they were prose. Lesson 5 kept them in columns because lesson 6 filters on them.
`langchain-text-splitters` also has a `MarkdownHeaderTextSplitter`, which cuts at headings and keeps
each heading as metadata, the heading path of lesson 5. Neither splitter reads a front matter block.

## The embedding client

`OpenAIEmbeddings` from `langchain-openai` is the embedding half of the provider's SDK, wrapped.
Pointed at the lab's model, it fails on the first call:

```
ana@lab:~/rag$ python lc_embed.py
BadRequestError Error code: 400 - {'error': {'message': "'input' must be a string or a non-empty array of strings.", 'type': 'invalid_request_error', 'param': None, 'code': 'invalid_value'}}
384 dimensions
```

The provider refused the request as malformed: `'input' must be a string`. With its default
settings, **`OpenAIEmbeddings` does not send text**. It encodes each text with tiktoken and sends
the token numbers, so that it can split a text longer than the model accepts and average the pieces.
OpenAI's own API accepts a list of token numbers. labembed, the lab's stand-in, accepts only strings,
and so may any provider that only imitates OpenAI's format. `check_embedding_ctx_length=False`
turns the behaviour off and the same call returns 384 numbers.

Two lessons in one error. A default can assume a particular provider even in a class whose whole
purpose is to let you change provider. And the silent half of that default is worse than the loud
one: against a provider that accepts token numbers, a text longer than the model's limit is split
and averaged without a word, and that averaged vector stands for a chunk nobody chose. Lesson 4's
sizes keep every chunk far below any model's limit, so the right setting here is the one that sends
what you wrote.
