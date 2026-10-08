---
title: Quoting, for answers that bind
version: 2
---

Lesson 2 said a legal reader needs the text that binds, located exactly, in the version that was in
force. Most of that is now in place: the search can be filtered to the right documents, every source
carries its date, and the checker confirms a sentence is quoted word for word. One piece is missing, the clause number. In lesson 2 the model happened to copy it into its reply,
*section 2.2*, because it was in the text it read, while the citation itself named only the heading,
*2. Placing an order*. A number the model happens to copy is not a citation a program can rely on.

The number is in the source text, just before the clause. `clause.py` looks for it there:

```schooling-example
{
  "language": "python",
  "file": "clause.py",
  "parts": [
    {
      "code": "import re\nimport sys\n\nfrom answer import answer\nfrom verify import claims, norm\n\nreply, sources = answer(sys.argv[1])",
      "note": "The reply and the sources it was given."
    },
    {
      "code": "for sentence, n in claims(reply):\n    print(f\"\\\"{sentence}\\\"\")\n    if n is None or not 0 < n <= len(sources):\n        print(\"  cites no source, so no clause\")\n        continue\n    source = sources[n - 1]\n    text = norm(source[\"text\"])\n    at = text.find(norm(sentence)[:30])\n    if at < 0:\n        print(f\"  {source['path']}: not quoted, so no clause\")\n        continue\n    numbers = re.findall(r\"(?:^|\\s)(\\d+\\.\\d+)\\s\", text[:at])\n    print(f\"  {source['path']}, clause {numbers[-1] if numbers else '?'}, updated {source['updated']}\")",
      "note": "For each sentence, where its first thirty characters start in the source it cites, and the last clause number in the text before that point. A sentence that cites nothing, or is not in its source word for word, has no place in the text to look before, and the program says so instead of guessing."
    }
  ]
}
```

```
ana@vm:~/rag$ python clause.py "When is the contract of sale formed?"
"According to the sources, the contract of sale is formed when the customer sends the email confirming that their order has been dispatched, as stated in."
  Terms of sale > 11. Changes to these terms: not quoted, so no clause
"This is because the email confirming receipt of the order is not an acceptance, but rather the acceptance is implied when the order is dispatched, as stated in."
  Terms of sale > 11. Changes to these terms: not quoted, so no clause
```

**The model paraphrased, and got the party wrong again.** In lesson 2 it said the seller sends the
email; here it says *the customer* does. Clause 2.2 says *we*, which is Marginalia. Neither sentence is
in its source word for word, so `clause.py` has no place in the text to look before, and says so
rather than guess. Both cite the terms of sale's section on changes to the terms, which is not where
the answer is.

The program works when the reply quotes. It looks at the source text before the quoted sentence and
takes the last clause number it finds there, and it works because the documents number their clauses
consistently; on documents that do not, the number has to be added to the chunk's metadata when the
document is cut, the way lesson 5 adds the path. And a reply that paraphrases a clause, as this one
did, has failed before any number is looked for.

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
receives the exact span instead of a number to look up. Ollama's Anthropic-compatible endpoint does
not implement it, and lesson 9 shows the refusal it answers with. Where a provider does, the check
still does not go away: a span says where the provider says the text came from, and a program that
matters still confirms the text is there.
