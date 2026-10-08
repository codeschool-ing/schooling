---
title: The window is a budget
version: 2
---

Every lesson so far has been about finding the right text. This one and the four after it are about
a different question: **of everything that could go in front of the model, what should?** That is
what has come to be called context engineering. The context window is everything the model reads in
one call: the instructions, the sources, any earlier turns of the conversation, the question, and the
room left for the reply. It has a hard limit, and well before the limit it has a price.

This lesson's decisions live in one module, `context.py`, which the later sections take apart one
function at a time. Save it now, because every program in the lesson imports it:

```schooling-example
{
  "language": "python",
  "file": "context.py",
  "parts": [
    {
      "code": "\"\"\"What goes into the window, and in what order: lesson 12's decisions in one place.\"\"\"\nimport re\n\nimport tiktoken\nfrom answer import FLOOR, REFUSAL, ask\nfrom vectors import embed\nfrom search import conn, vector\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nSAME = 0.9      # two sources this similar say the same thing\nKEEP = 0.45     # a sentence this similar to the question stays in its source\nBUDGET = 200    # tokens of sources, headers included\n\n\ndef tokens(text):\n    return len(enc.encode(text))",
      "note": "The decisions of this lesson, as constants: how alike two sources must be to count as one, how close a sentence must be to the question to stay, and how many tokens of sources a prompt may carry. `tokens` counts with tiktoken, as lesson 1 did."
    },
    {
      "code": "def candidates(question, k=10, where=\"status = %s AND audience = %s\", params=(\"current\", \"public\")):\n    \"\"\"Up to K chunks above the floor, best first, with what a source header needs.\"\"\"\n    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]\n    meta = {i: (u, v) for i, u, v in conn.execute(\n        \"SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],))}\n    return [{\"id\": i, \"path\": p, \"text\": t, \"score\": s, \"updated\": meta[i][0], \"version\": meta[i][1]}\n            for i, p, t, s in found]",
      "note": "Up to k chunks above lesson 7's floor, with what a source's header needs: its date and version."
    },
    {
      "code": "def dedupe(sources, same=SAME):\n    \"\"\"Drop a source that says what a better one already said.\"\"\"\n    if not sources:\n        return []\n    v = embed([s[\"text\"] for s in sources])\n    kept = []\n    for i in range(len(sources)):\n        if all(v[i] @ v[j] < same for j in kept):\n            kept.append(i)\n    return [sources[i] for i in kept]",
      "note": "The section on duplicates explains this one."
    },
    {
      "code": "def sentences(text):\n    return [s for s in re.split(r\"(?<=[.!?])\\s+(?=[A-Z0-9])|\\n(?=- )|\\n\\n\", text) if s.strip()]\n\n\ndef compress(question, source, keep=KEEP):\n    \"\"\"Keep the sentences of a source that are about the question, in their order, and always its best.\"\"\"\n    parts = sentences(source[\"text\"])\n    scores = embed(parts) @ embed(question)[0]\n    chosen = [p for p, s in zip(parts, scores) if s >= keep or s == scores.max()]\n    return {**source, \"text\": \" \".join(\" \".join(p.split()) for p in chosen)}",
      "note": "The section on compressing sources explains these."
    },
    {
      "code": "def ends(sources):\n    \"\"\"Best first, second best last, the weakest in the middle.\"\"\"\n    return sources[0::2] + sources[1::2][::-1]\n\ndef header(n, source):\n    return f\"[{n}] {source['path']} (updated {source['updated']})\\n\"",
      "note": "The sections on placement and headers explain these."
    },
    {
      "code": "def pack(question, budget=BUDGET, k=10, **filters):\n    \"\"\"Floor, then duplicates out, then each source cut to what is about the question, then as many\n    as fit the budget, best first, and finally the strongest two at the two ends.\"\"\"\n    kept, used = [], 0\n    for s in dedupe(candidates(question, k, **filters)):\n        s = compress(question, s)\n        cost = tokens(header(0, s) + s[\"text\"])\n        if used + cost <= budget:\n            kept.append(s)\n            used += cost\n    return ends(kept)",
      "note": "The section on packing explains this, and the last one."
    },
    {
      "code": "def answer(question, **filters):\n    sources = pack(question, **filters)\n    if not sources:\n        return REFUSAL, []\n    return ask(question, sources), sources"
    }
  ]
}
```

`window.py` asks it how big lesson 7's prompt is, part by part:

```schooling-example
{
  "language": "python",
  "file": "window.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import SYSTEM, prompt, sources_for\nfrom context import header, tokens\n\nquestion = sys.argv[1]\nsources = sources_for(question)\nprint(f\"{tokens(SYSTEM):5}  instructions\")\nfor n, s in enumerate(sources, 1):\n    print(f\"{tokens(header(n, s)):5}  header [{n}]\")\n    print(f\"{tokens(s['text']):5}  text   [{n}] {s['path']}\")\nprint(f\"{tokens('Question: ' + question):5}  question\")\ntotal = tokens(SYSTEM) + tokens(prompt(question, sources))\nprint(f\"{total:5}  sent, of a window of 4096\")",
      "note": "Every part of the prompt lesson 7's `answer.py` would send for one question, counted in tokens: the instructions, each source's header and text, and the question, against the 4,096 tokens Ollama gives llama3.2:3b."
    }
  ]
}
```

```
ana@vm:~/rag$ python window.py "How long is a gift card valid?"
   71  instructions
   19  header [1]
   39  text   [1] Gift card terms > Validity
   22  header [2]
   69  text   [2] Payments, invoices and gift cards > Gift cards
   22  header [3]
   59  text   [3] Payments, invoices and gift cards > Gift cards
   10  question
  311  sent, of a window of 4096
```

**311 tokens, of a window of 4,096.** It looks like a problem that does not exist yet, and three
things make it one anyway.

- **Every token is paid for**, on every query, and lesson 17 multiplies that by a week of traffic.
  A prompt twice the size is twice the bill for the input.
- **Every token is read before the first word comes back.** Lesson 9's streaming hid the time to
  write the reply; nothing hides the time to read the prompt, and it grows with its length.
- **Every token competes for the model's attention.** That is the one this course measures least
  well, with one small model and thirty questions, and the section after next quotes the research
  that has measured it.

And the 311 is the smallest it will ever be. Lesson 13 adds the conversation so far, a support
assistant may add the customer's account details, an agent in `agents-mcp` adds the descriptions of
its tools, and each of them arrives with a reason to be there. **A window is never filled by one
decision; it is filled by many reasonable ones**, and the sum is nobody's choice unless somebody
makes it one.

The anatomy above is also the agenda of this lesson. The instructions, 71 tokens, are fixed. The
question is the customer's. Everything else is a decision: how many sources (the next two sections),
which ones (duplicates), how much of each (compression), in what order (placement), and with what
around them (headers). The last section puts the decisions into one function, `pack`, and measures it
against lesson 7's prompt.
