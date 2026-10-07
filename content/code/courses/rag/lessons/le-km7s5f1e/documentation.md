---
title: Technical documentation
version: 2
---

The first job most teams give a retrieval system is their own documentation: an API reference, a set
of manuals, a wiki of how things are deployed. It looks like the easy case. The documents are written
by engineers, they are structured, and the readers are engineers who will check the answer. It is
the case where meaning-based search is weakest, and the reason is in the vocabulary.

## A program that searches by section

Every run in this lesson uses `sections.py`, the search from lesson 1 made into a module: the
documents cut at their `## ` headings, embedded once, searched by cosine similarity, with the best
three put in a prompt for llama3.2:3b.

```schooling-example
{
  "language": "python",
  "file": "sections.py",
  "parts": [
    {
      "code": "import glob\nimport re\nimport sys\n\nfrom vectors import embed\nfrom openai import OpenAI\n\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        sections.append((f\"{doc} > {part.splitlines()[0][3:]}\", part))\nvectors = embed([text for _, text in sections])",
      "note": "The documents cut at every `## ` heading, each section named after its document and heading, and all of them embedded once, when the module is imported."
    },
    {
      "code": "def search(question, k=3):\n    scores = vectors @ embed(question)[0]\n    return [(sections[i][0], sections[i][1], float(scores[i])) for i in scores.argsort()[::-1][:k]]",
      "note": "`search` scores every section against the question and returns the best `k`, with their names, texts and scores."
    },
    {
      "code": "def answer(question, k=3):\n    found = search(question, k)\n    for rank, (name, _, score) in enumerate(found, 1):\n        print(f\"[{rank}] {score:.3f}  {name}\")\n    sources = \"\".join(f\"[{rank}] {name}\\n{text}\\n\" for rank, (name, text, _) in enumerate(found, 1))\n    reply = OpenAI().chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"}])\n    print(reply.choices[0].message.content)",
      "note": "`answer` prints what the search found, then puts it in a numbered prompt and prints the model's reply."
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
ana@vm:~/rag$ python sections.py "What does error E-4104 mean?"
[1] 0.478  affiliate-api > Changes in 2.3
[2] 0.393  affiliate-api > Errors
[3] 0.380  affiliate-api > Rate limits
According to [2], error E-4104 means that the month is out of range or not in the correct format (YYYY-MM).
ana@vm:~/rag$ grep -n "E-4104" data/docs/*.md
data/docs/affiliate-api.md:61:than 24 months in the past, or in the future, return E-4104.
data/docs/affiliate-api.md:85:| E-4104 | 400 | the month is out of range or not in the form YYYY-MM |
```

**The reply is right, and the search nearly was not.** It ranked the change log above the error
table, because *Changes in 2.3* talks about an error and a version and so does the question; the
table came second, at 0.393. The model then found the row, because a language model reads the
characters of its prompt and `E-4104` is written there exactly. `grep` found the same row in no time
at all, twice, without needing anything to come second.

That is the documentation problem in one run, and the model's good reading only hid it. An embedding model represents what a text is *about*,
and it is very good at that; it is poor at telling apart two strings that differ in one character,
because almost nothing in its training taught it that `E-4104` and `E-4102` mean different things.
With k = 3 the table made the cut; with a larger corpus and k = 3 it would be one near-miss among
hundreds of sections, and the model cannot read a row the search did not return. Technical
documentation is full of such strings: error codes, function names, flags, version numbers,
configuration keys. **Questions about documentation are often questions about an exact identifier,
and an exact identifier is what lexical search was built for.** Lesson 6 adds a lexical search beside
the vector one and merges the two.

## Asking about a concept

The same reference answers conceptual questions too, and the pattern repeats:

```
ana@vm:~/rag$ python sections.py "What is the rate limit of the affiliate API?"
[1] 0.517  affiliate-api > Base URL and authentication
[2] 0.445  affiliate-api > Rate limits
[3] 0.335  affiliate-api > Commission
According to [2] affiliate-api > Rate limits, the rate limit of the affiliate API is 120 requests per minute.
```

The section titled *Rate limits* came second, behind *Base URL and authentication*, and the model
answered from it: 120 requests per minute, the right number. The sentence it needed, "A key may make
120 requests per minute", never uses the words *rate* or *limit*: the heading does, and the heading is
what put the section in the top three at all. Once a section is cut away from its heading, nothing in
its text says what it is about. Lesson 4 comes back to this, and lesson 5 shows the cheap fix of
embedding each chunk with the headings above it.

## What documentation asks of a pipeline

- **Exact identifiers have to be found exactly.** A hybrid of lexical and vector search, at least.
- **Code has to survive chunking.** A code sample cut in half is worse than none, so the cut has to
  respect blocks; lesson 4.
- **Versions matter.** The reference above is version 2.3, and 2.2 is still served. An answer about
  the `lang` parameter is wrong for anybody on 2.2, so the version belongs beside the chunk.
- **The reader will run the answer.** A developer pastes the snippet into a terminal within a minute.
  A wrong answer costs a little time and is found quickly, which makes documentation the case where
  being wrong is cheapest. It is still the case where it happens most often.
