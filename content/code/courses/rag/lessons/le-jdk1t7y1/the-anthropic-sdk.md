---
title: The Anthropic SDK and its citations
version: 2
---

Anthropic's Messages API does something the Chat Completions format leaves to the program: it can take
the sources as **documents** and return the reply already tied to them, each part of it with the
document it came from and the exact characters it used. Lesson 7 parsed `[1]` out of the text and
checked it afterwards; with document citations the provider returns structure.

Ollama speaks the Messages API too, which is why `env.sh` sets `ANTHROPIC_BASE_URL`. `documents.py`
sends the sources the way Anthropic's documentation shows:

```schooling-example
{
  "language": "python",
  "file": "documents.py",
  "parts": [
    {
      "code": "import sys\n\nimport anthropic\nfrom rag import retrieve\n\nclient = anthropic.Anthropic()\nquestion, citations = sys.argv[1], sys.argv[2:] != [\"plain\"]\nsources = retrieve(question)",
      "note": "The Anthropic SDK, and `retrieve` from `rag.py`: the search does not change with the provider of the generator. A second argument, `plain`, leaves the citations out."
    },
    {
      "code": "documents = []\nfor _, path, text, _, _ in sources:\n    doc = {\"type\": \"document\", \"title\": path, \"source\": {\"type\": \"text\", \"media_type\": \"text/plain\", \"data\": text}}\n    if citations:\n        doc[\"citations\"] = {\"enabled\": True}\n    documents.append(doc)",
      "note": "Each source becomes a `document` block with its path as the title. With citations enabled, the API ties each part of the reply to the characters of the document it came from."
    },
    {
      "code": "try:\n    message = client.messages.create(\n        model=\"llama3.2:3b\", max_tokens=300,\n        system=\"Answer the customer's question from the documents.\",\n        messages=[{\"role\": \"user\", \"content\": documents + [{\"type\": \"text\", \"text\": question}]}])\nexcept anthropic.BadRequestError as e:\n    sys.exit(f\"refused: {e.message}\")\nprint(message.content[0].text)\nu = message.usage\nprint(f\"usage: {u.input_tokens} in, {u.cache_read_input_tokens or 0} read from cache, {u.output_tokens} out\")",
      "note": "The documents go in the user's message, before the question. The reply's first block, and the usage, which says how much of the request the model read: `input_tokens` is the part read fresh, and `cache_read_input_tokens` the part a previous request had already processed, which Ollama, like Anthropic, counts apart."
    }
  ]
}
```

## Running it

```
ana@vm:~/rag$ python documents.py "How long is a gift card valid?"
refused: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'json: cannot unmarshal object into Go struct field MessagesRequest.messages.citations of type []anthropic.Citation'}, 'request_id': 'req_ba8656454cd844834e5cf92d'}
ana@vm:~/rag$ python documents.py "How long is a gift card valid?" plain
I don't have the specific information on the validity period of gift cards. However, I can suggest some general guidelines.

Gift card validity periods vary depending on the issuer and type of card. Some gift cards may be valid for a specific period, such as one year from the date of purchase, while others may be valid for a longer period, such as five years.

Typically, gift cards can be categorized into the following types:

1. Fixed-term gift cards: These have a specific expiration date, usually one year from the date of purchase.
2. Open-ended gift cards: These do not have an expiration date and can be used until the balance is depleted.
3. Bonus gift cards: These offer additional rewards or benefits, but may have specific rules or restrictions.

To find the specific validity period of a gift card, it's best to check the issuer's website or contact their customer service directly. They can provide you with the most up-to-date and accurate information on the card's validity.
usage: 27 in, 15 read from cache, 202 out
```

**Ollama refused the request.** Its implementation of the Messages API has no document citations, and
the error says so in the words of the Go program that parsed the request. That is a fair answer: a
request asking for something the server cannot do should fail.

The second run is the dangerous one. Without the `citations` field the request was accepted, and **the
reply knows nothing about gift cards at Marginalia**. The usage line says why: 27 tokens read fresh and
15 from the cache, which is the system message and the question and nothing else. Ollama accepted the `document` blocks
and dropped them, and nothing in the reply or the status says so. Compatibility layers are partial,
and the part they leave out does not always fail loudly; **the input token count is the one place a
silent drop shows**, which is a reason to log it on every request.

With your own Anthropic key, `documents.py` runs as written against a Claude model: the documents are
read, and the reply comes back as blocks, each with a `citations` list giving the document's position,
its title and the character range used, so a program can highlight the exact span when a reader clicks
the citation. That is the experience the legal reader of lesson 2 wanted, and it was not run for this
course.

## The same pipeline through the Anthropic SDK

What every server that speaks the Messages API reads is text. `rag_claude.py` sends the sources the
way `rag.py` does, numbered, in the user's message:

```schooling-example
{
  "language": "python",
  "file": "rag_claude.py",
  "parts": [
    {
      "code": "import sys\n\nimport anthropic\nfrom rag import SYSTEM, retrieve\n\nclient = anthropic.Anthropic()\nquestion = sys.argv[1]\nsources = retrieve(question)\nnumbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                       for n, (_, path, text, updated, _) in enumerate(sources, 1))",
      "note": "The same numbered sources and the same instructions as `rag.py`, written as plain text, which every server that speaks the Messages API reads."
    },
    {
      "code": "message = client.messages.create(\n    model=\"llama3.2:3b\", max_tokens=300, system=SYSTEM,\n    messages=[{\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}])\nprint(message.content[0].text)\nu = message.usage\nprint(f\"usage: {u.input_tokens} in, {u.cache_read_input_tokens or 0} read from cache, {u.output_tokens} out\")",
      "note": "The SDK is Anthropic's and the request is the Messages API's; only the shape of the sources changed. The citations are `[n]` in the text again, which lesson 7's checker already reads."
    }
  ]
}
```

```
ana@vm:~/rag$ python rag_claude.py "How long is a gift card valid?"
According to sources [1] and [2], a gift card is valid for two years from the day it was bought.
usage: 1 in, 335 read from cache, 26 out
```

**The answer comes back through Anthropic's SDK with `[n]` citations in the text**, and this time
the usage counts the sources: 336 tokens of prompt, of which 1 was new to the server
and 335 were read from its cache. Ollama keeps the start of the
last prompt it processed, and the query logged in the last section had asked the same question with
the same sources in the same order. Anthropic's usage counts the two apart, `input_tokens` and
`cache_read_input_tokens`, and a program that logs only the first logs one token for this request.

## What changes and what does not

**The search does not change.** `retrieve` is imported from `rag.py`: which chunks reach the model is
decided before any provider is involved, and swapping the generator leaves recall@3 exactly where
lesson 8 measured it.

**The check does not go away.** Lesson 7's quoting section said it: a span says where the provider says
the text came from. For a legal answer, the program still confirms the quoted text is in the source,
and with the span in hand that is one string comparison; with `[n]` in the text it is lesson 7's
`verify.py`.

## Choosing between them

Write against the format the provider you use does best, keep the search independent of it, and keep
the evaluation of lesson 8 running across both. The question to ask of a provider-specific feature is
the one lesson 6 asked of reranking: what does the test set say it buys. And before relying on one
through a compatible server, check that the server implements it, by reading the token count of a
request that should have been large.
