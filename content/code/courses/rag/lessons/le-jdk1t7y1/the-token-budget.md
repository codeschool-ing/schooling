---
title: The token budget
version: 2
---

Every request has a size limit, and lesson 1 hit it: about 9,000 tokens of documents against the
4,096 Ollama serves llama3.2:3b with, cut to fit without a word of warning. With retrieval the prompt is small, a few hundred
tokens, and the limit seems far away. It stops seeming so the day somebody raises k, adds a
conversation history, or indexes a document with one enormous section. A program that counts before it
sends never meets the cut, or, with a commercial provider, the refusal.

## Counting before sending

`budget.py` counts the tokens of each part of the prompt with the provider's encoding, keeps sources in
rank order while they fit, and drops the rest:

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "import sys\n\nimport tiktoken\nfrom rag import SYSTEM, retrieve",
      "note": "tiktoken for the count, and the search and instructions of `rag.py`."
    },
    {
      "code": "enc = tiktoken.get_encoding(\"cl100k_base\")\nBUDGET = int(sys.argv[2])\nquestion = sys.argv[1]\nsources = retrieve(question)",
      "note": "The budget comes from the command line, and the sources from the search, in rank order."
    },
    {
      "code": "cost = lambda s: len(enc.encode(f\"[0] {s[1]} (updated {s[3]})\\n{s[2]}\"))\nfixed = len(enc.encode(SYSTEM)) + len(enc.encode(f\"Question: {question}\"))\nprint(f\"instructions and question: {fixed} tokens\")",
      "note": "A source costs its header and its text. The instructions and the question are paid whatever happens."
    },
    {
      "code": "kept, used = [], fixed\nfor s in sources:\n    if used + cost(s) > BUDGET:\n        print(f\"  drop  {cost(s):4} tokens  {s[1]}\")\n        continue\n    kept.append(s)\n    used += cost(s)\n    print(f\"  keep  {cost(s):4} tokens  {s[1]}\")\nprint(f\"{used} of {BUDGET} tokens, {len(kept)} of {len(sources)} sources\")",
      "note": "Walk the sources in rank order, keep each one that fits whole, and drop each one that does not."
    }
  ]
}
```

```
ana@vm:~/rag$ python budget.py "How long after my return arrives will I get the refund?" 400
instructions and question: 85 tokens
  keep    84 tokens  Returns and refunds policy > Refunds
  keep    85 tokens  Returns and refunds policy > The return window
  keep   104 tokens  Returns and refunds policy > Items sold by marketplace sellers
358 of 400 tokens, 3 of 3 sources
ana@vm:~/rag$ python budget.py "How long after my return arrives will I get the refund?" 250
instructions and question: 85 tokens
  keep    84 tokens  Returns and refunds policy > Refunds
  drop    85 tokens  Returns and refunds policy > The return window
  drop   104 tokens  Returns and refunds policy > Items sold by marketplace sellers
169 of 250 tokens, 1 of 3 sources
```

With 400 tokens to spend, all three sources fit, 358 in all. With 250, the first source fits and the
next two do not, and the prompt goes out with one source, 169 tokens. The refund question still has
its answer, because the answer was the first source. **Dropping by rank keeps the best and loses the
rest**, which is right when rank is a good guide, and lesson 12 is about the cases where it is not.

## What to count

**Everything that goes into the request.** The instructions, the sources with their headers, the
question, any conversation history, and the room left for the reply. Ollama's window holds the prompt
and the reply together, so a prompt that fills it leaves the reply nowhere to go. A budget that
forgets the reply is a budget that fails on the longest answers.

**With an encoding close to the model's.** The count here is tiktoken's `cl100k_base`, OpenAI's;
llama3.2 has a tokenizer of its own, so a count by one is an estimate of the other. The gift-card
query logged in this lesson went out with 336 prompt tokens by
llama3.2's count, which also includes the template Ollama wraps around every message and which no
count made before sending can see. Close enough to budget with a margin, never close enough to
budget to the last token.
Anthropic's API offers a token-counting endpoint for exactly this, and Ollama does not implement it.

**In rank order, whole.** A source cut in half to fit is a source whose second half is missing,
usually the half with the exception in it. Dropping whole sources keeps every source intact.

## Why a budget smaller than the window

The window is the most a request may hold, not what it should. Lesson 1 gave three reasons for not
filling it, price, time and distraction, and each holds at a hundredth of the window as much as at the
whole of it. So the budget is a product decision: the smallest context that keeps lesson 8's
correctness where it is. Lesson 12 measures that number and packs the window to meet it.
