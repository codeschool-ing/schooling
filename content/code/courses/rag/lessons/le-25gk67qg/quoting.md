---
title: Quoting, for answers that bind
version: 1
---

Lesson 2 said a legal reader needs the text that binds, located exactly, in the version that was in
force. Most of that is now in place: the search can be filtered to the right documents, every source
carries its date, and the checker confirms a sentence is quoted word for word. One piece is missing,
the clause number, and lesson 2 saw why it goes missing: extract-1 drops a number at the start of a
line when it splits sentences, and the chunk's path names the section, not the clause.

The number is still in the source text, just before the sentence. `clause.py` finds it there:

```
ana@lab:~/rag$ python clause.py "When is the contract of sale formed?"
"The contract is formed when we send the email confirming that your order has been dispatched."
  Terms of sale > 2. Placing an order, clause 2.2, updated 2026-01-05
```

**Clause 2.2, of the terms of sale, updated 2026-01-05**: everything a lawyer needs to find the text
and check it. The program looks at the source text before the quoted sentence and takes the last
clause number it finds there. It is a small piece of code, and it works because the documents number
their clauses consistently; on documents that do not, the number has to be added to the chunk's
metadata when the document is cut, the way lesson 5 adds the path.

## Verbatim, and checked

For a use where the wording matters, the prompt asks for quotations instead of answers: *quote the
clause that answers the question, word for word, with its number*. A real model will usually comply,
and will occasionally change a word while quoting, *may* for *must*, *delivered* for *dispatched*,
because paraphrase is what its training rewards. So the check from earlier in this lesson becomes
strict: **a legal reply passes only if every quoted sentence appears in its source character for
character**, and a sentence that is merely close is a failure, not a paraphrase.

## Provider support for citations

Anthropic's Messages API can do part of this itself. Sources sent as `document` blocks with citations
enabled come back with each part of the reply tied to a character range in a document, so the program
receives the exact span instead of a number to look up. labgen implements that format, and lesson 9
uses it through the Anthropic SDK. The check does not go away with it: a span says where the provider
says the text came from, and a program that matters still confirms the text is there.
