---
title: Technical documentation
version: 1
---

The first job most teams give a retrieval system is their own documentation: an API reference, a set
of manuals, a wiki of how things are deployed. It looks like the easy case. The documents are written
by engineers, they are structured, and the readers are engineers who will check the answer. It is
the case where meaning-based search is weakest, and the reason is in the vocabulary.

## A program that searches by section

Every run in this lesson uses `sections.py`, the search from lesson 1 made into a module: the
documents cut at their `## ` headings, embedded once, searched by cosine similarity, with the best
three put in a prompt for extract-1.

```schooling-example
{
  "language": "python",
  "file": "sections.py",
  "parts": [
    {
      "code": "import glob\nimport re\nimport sys\n\nfrom minilm import embed\nfrom openai import OpenAI\n\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        sections.append((f\"{doc} > {part.splitlines()[0][3:]}\", part))\nvectors = embed([text for _, text in sections])",
      "note": "The documents cut at every `## ` heading, each section named after its document and heading, and all of them embedded once, when the module is imported."
    },
    {
      "code": "def search(question, k=3):\n    scores = vectors @ embed(question)[0]\n    return [(sections[i][0], sections[i][1], float(scores[i])) for i in scores.argsort()[::-1][:k]]",
      "note": "`search` scores every section against the question and returns the best `k`, with their names, texts and scores."
    },
    {
      "code": "def answer(question, k=3):\n    found = search(question, k)\n    for rank, (name, _, score) in enumerate(found, 1):\n        print(f\"[{rank}] {score:.3f}  {name}\")\n    sources = \"\".join(f\"[{rank}] {name}\\n{text}\\n\" for rank, (name, text, _) in enumerate(found, 1))\n    reply = OpenAI().chat.completions.create(model=\"extract-1\", messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"}])\n    print(reply.choices[0].message.content)",
      "note": "`answer` prints what the search found, then puts it in a numbered prompt and prints extract-1's reply."
    },
    {
      "code": "if __name__ == \"__main__\":\n    answer(sys.argv[1])",
      "note": "Run as a program, it answers the question on the command line."
    }
  ]
}
```

## Asking about an error code

The affiliate API reference ends with a table of error codes. A developer whose integration has just
logged `E-4104` asks what it means:

```
ana@lab:~/rag$ python sections.py "What does error E-4104 mean?"
[1] 0.478  affiliate-api > Changes in 2.3
[2] 0.393  affiliate-api > Errors
[3] 0.380  affiliate-api > Rate limits
E-4102 429 more than 120 requests in the last minute [2] Version 2.3, released on 10 February 2026, added the lang parameter to /search and the error E-4105. [1] E-5001 500 an error on our side; retry after a few seconds [2]
ana@lab:~/rag$ grep -n "E-4104" data/docs/*.md
data/docs/affiliate-api.md:61:than 24 months in the past, or in the future, return E-4104.
data/docs/affiliate-api.md:85:| E-4104 | 400 | the month is out of range or not in the form YYYY-MM |
```

**The reply names three error codes, and none of them is E-4104.** The search ranked the change log
above the error table, because *Changes in 2.3* talks about an error and a version and so does the
question; the table came second. From that table, extract-1 then copied the rows most similar to the
question, and to an embedding model `E-4102`, `E-4104` and `E-5001` are nearly the same string. `grep`
found the exact row in no time at all, twice.

That is the documentation problem in one run. An embedding model represents what a text is *about*,
and it is very good at that; it is poor at telling apart two strings that differ in one character,
because almost nothing in its training taught it that `E-4104` and `E-4102` mean different things.
Technical documentation is full of such strings: error codes, function names, flags, version numbers,
configuration keys. **Questions about documentation are often questions about an exact identifier,
and an exact identifier is what lexical search was built for.** Lesson 6 adds a lexical search beside
the vector one and merges the two.

## Asking about a concept

The same reference answers conceptual questions too, and there the embedding search does better at
finding and worse at answering:

```
ana@lab:~/rag$ python sections.py "What is the rate limit of the affiliate API?"
[1] 0.517  affiliate-api > Base URL and authentication
[2] 0.445  affiliate-api > Rate limits
[3] 0.335  affiliate-api > Commission
The sources do not say.
```

The section titled *Rate limits* came second, behind *Base URL and authentication*, and extract-1
found no single sentence close enough to the question. The sentence it needed, "A key may make 120
requests per minute", never uses the words *rate* or *limit*: the heading does. Once the section is
cut away from its heading, nothing in its text says what it is about. Lesson 4 comes back to this,
and lesson 5 shows the cheap fix of embedding each chunk with the headings above it.

## What documentation asks of a pipeline

- **Exact identifiers have to be found exactly.** A hybrid of lexical and vector search, at least.
- **Code has to survive chunking.** A code sample cut in half is worse than none, so the cut has to
  respect blocks; lesson 4.
- **Versions matter.** The reference above is version 2.3, and 2.2 is still served. An answer about
  the `lang` parameter is wrong for anybody on 2.2, so the version belongs beside the chunk.
- **The reader will run the answer.** A developer pastes the snippet into a terminal within a minute.
  A wrong answer costs a little time and is found quickly, which makes documentation the case where
  being wrong is cheapest. It is still the case where it happens most often.
