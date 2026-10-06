---
title: The Anthropic SDK and its citations
version: 1
---

Anthropic's Messages API does something the Chat Completions format leaves to the program: it can take
the sources as **documents** and return the reply already tied to them, each sentence with the
document it came from and the exact characters it used. Lesson 7 parsed `[1]` out of the text and
checked it afterwards; here the provider returns structure.

```schooling-example
{
  "language": "python",
  "file": "rag_claude.py",
  "parts": [
    {
      "code": "import sys\n\nimport anthropic\nfrom rag import retrieve",
      "note": "The Anthropic SDK, and `retrieve` from `rag.py`: the search does not change with the provider of the generator."
    },
    {
      "code": "client = anthropic.Anthropic()\nquestion = sys.argv[1]\nsources = retrieve(question)\ndocuments = [{\"type\": \"document\", \"title\": path, \"citations\": {\"enabled\": True},\n              \"source\": {\"type\": \"text\", \"media_type\": \"text/plain\", \"data\": text}}\n             for _, path, text, _, _ in sources]",
      "note": "Each source becomes a `document` block with its path as the title and citations enabled. The numbering is gone: the API refers to documents by their position in the list."
    },
    {
      "code": "message = client.messages.create(\n    model=\"extract-1\", max_tokens=300,\n    system=\"Answer the customer's question from the documents.\",\n    messages=[{\"role\": \"user\", \"content\": documents + [{\"type\": \"text\", \"text\": question}]}])",
      "note": "The documents go in the user's message, before the question. The system prompt is shorter, because the API, not the prompt, now asks for the citations."
    },
    {
      "code": "for block in message.content:\n    if block.type == \"text\" and block.text.strip():\n        print(block.text)\n        for c in block.citations or []:\n            print(f\"  document {c.document_index}, {c.document_title}, characters {c.start_char_index}-{c.end_char_index}\")\nprint(\"usage:\", message.usage.input_tokens, \"in,\", message.usage.output_tokens, \"out\")",
      "note": "The reply is a list of text blocks, and a block that came from a document carries a `citations` list: which document, its title and the character range the text was taken from."
    }
  ]
}
```

## Running it

```
ana@lab:~/rag$ python rag_claude.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought.
  document 0, Gift card terms > Validity, characters 0-62
Gift cards are valid for two years from purchase and cannot be exchanged for cash.
  document 1, Payments, invoices and gift cards > Gift cards, characters 0-82
usage: 187 in, 32 out
```

**Each sentence came back as its own block, with a citation saying which document and which
characters.** *Document 0, Gift card terms > Validity, characters 0-62*: the first 62 characters of
that source are the sentence quoted. A program can now highlight the exact span in the source when a
reader clicks the citation, which is the experience a legal reader in lesson 2 wanted.

Two notes on what is real here. The request and response shapes are Anthropic's, as the SDK expects
them; labgen implements the `document` block, the `citations` field and the `char_location` citation
type closely enough that the official SDK parses its replies. The replies are extract-1's. A real Claude
model writes its own sentences and attaches citations to the spans it relied on; extract-1 copies whole
sentences, so its spans are always whole sentences starting at their first character.

## What changes and what does not

**The search does not change.** `retrieve` is imported from `rag.py`: which chunks reach the model is
decided before any provider is involved, and swapping the generator leaves recall@3 exactly where
lesson 8 measured it.

**The prompt shrinks.** The instruction to cite every sentence by number is gone; the API asks for
citations itself. The token count reflects it: 187 input tokens here, against 314 for the same
question through `rag.py`, in the next section and in the log.

**The check does not go away.** Lesson 7's quoting section said it: a span says where the provider says
the text came from. For a legal answer, the program still confirms the quoted text is in the source
at those characters, which, with the span in hand, is one string comparison.

## Choosing between them

Write against the format the provider you use does best, keep the search independent of it, and keep
the evaluation of lesson 8 running across both. The question to ask of a provider-specific feature is
the one lesson 6 asked of reranking: what does the test set say it buys.
