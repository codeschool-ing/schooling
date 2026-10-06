---
title: Why documents are cut up
version: 1
---

Lesson 1 cut every document at its headings without saying why, and the obvious objection is that
nothing forced it to. Why not embed each document whole and retrieve whole documents? There are two
reasons, and one of them is a hard limit that most people only discover by accident.

## The embedding model reads a fixed number of pieces

all-MiniLM-L6-v2 reads at most 256 word pieces. That is not a soft preference: the tokenizer cuts the
input at 256, and everything after that point never reaches the model. Every embedding model has a
limit like it; the hosted ones are larger, a few thousand pieces, and still finite. `truncation.py`
measures what that means for the returns policy:

```
ana@lab:~/rag$ python truncation.py
pieces in the whole policy: 1043
words the model reads: 219 of 884
similarity, whole policy and its first 219 words: 1.0000
similarity, whole policy and the policy plus a sentence at the end: 1.0000
```

**The policy is 1,043 pieces, and the model reads the first 256 of them, which is 219 of its 884
words.** The vector for the whole policy and the vector for its first 219 words are identical,
similarity 1.0000, because they are the same input once the tokenizer is done. The last line is the
alarming one: appending *Returns are never accepted.* to the end of the policy did not move its
vector at all. Whatever a document says after its first 219 words, its embedding cannot know.

That is a silent failure of the worst kind. Nothing errors, every document gets a vector, and a search
over whole documents works well for questions about the first page and not at all for the rest. A
question about refunds, which this policy reaches long after its first 219 words, would be matched
against a vector that never saw them.

## A vector is an average

The second reason holds even for a model with a large limit. An embedding summarises the whole input
in one point, and a long text about many things lands at a point that is about none of them in
particular: near returns, near refunds, near marketplace sellers, and close to no question about any
one of them. `embeddings-vectors` lesson 1 called it meaning turned into a vector, and a vector has
room for one meaning at a time.

A small chunk about one thing lands close to questions about that thing. That is what makes it
findable, and it is the whole reason to cut.

## And the prompt has a budget

The third consideration comes from the other end of the pipeline. Whatever is retrieved goes into the
prompt, and lesson 3 measured that cost: 332 tokens per question for three whole sections. Retrieve
whole documents and that becomes thousands, most of them about something else. Smaller chunks spend
the context on text that is about the question.

## The tension

Cutting smaller makes each chunk easier to find and cheaper to send. It also strips context away:
lesson 2 found the sentence "A key may make 120 requests per minute" unfindable once separated from
its heading, *Rate limits*. **Every chunking decision trades findability against context**, and the
rest of this lesson measures that trade on this corpus, with five ways of cutting and one table that
compares them.

The program all of them use is `chunking.py`, a module of small functions shown in the sections that
use them, and a loader that reads each document and its front matter:

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "import glob\nimport re\n\nimport numpy as np\nfrom minilm import embed",
      "note": "numpy for the semantic cut, and the same embedding model as every other lesson."
    },
    {
      "code": "def load():\n    \"\"\"{id: (metadata, body)} for every document, the front matter read into a dict.\"\"\"\n    docs = {}\n    for path in sorted(glob.glob(\"data/docs/*.md\")):\n        head, body = open(path).read().split(\"\\n---\\n\", 1)\n        meta = dict(line.split(\": \", 1) for line in head.splitlines()[1:])\n        docs[meta[\"id\"]] = (meta, body.strip())\n    return docs",
      "note": "Each document's front matter becomes a dictionary, and its body is kept apart from it, so that `id`, `audience` and `status` are data, not text to embed."
    }
  ]
}
```
