---
title: What a query costs
version: 2
---

A provider bills by the token: tokens embedded, tokens sent to the model, tokens the model writes,
often at a different price for each, and the prices change. So this lesson counts tokens and leaves the
multiplication to the reader's current price list, which is the only price that will be right on the
day they read it.

`data/querylog.jsonl` is a week of questions asked of the help assistant, 500 of them, generated from
phrasings the course wrote. Save the generator as `~/rag/querylog.py` and run it:

```schooling-example
{
  "language": "python",
  "file": "querylog.py",
  "parts": [
    {
      "code": "\"\"\"querylog: writes data/querylog.jsonl, a week of questions asked of the help assistant.\n\nTHE LOG IS GENERATED, NOT RECORDED, and nothing about it is measured from a\nreal shop. It is drawn with a fixed seed from PHRASINGS below, which were\nwritten by the course: each topic has a few ways people say it, and topics\nare drawn with Zipf-like weights (the first is asked most), because that is\nthe shape a support queue has. Lesson 17 measures caches against it, and\nwhat it measures is the cache, not Marginalia's customers.\n\"\"\"\nimport json\nimport random\nfrom datetime import datetime, timedelta\n\nPHRASINGS = [\n    [\"How many days do I have to return a printed book?\", \"how many days do I have to return a printed book?\",\n     \"how long do I have to return a book\", \"return window for books\", \"Can I still return a book I got 3 weeks ago?\"],\n    [\"How much is express delivery?\", \"how much is express delivery\", \"express shipping price\", \"what does next day delivery cost\"],\n    [\"How long after my return arrives will I get the refund?\", \"when do I get my refund\",\n     \"how long does a refund take\", \"refund timing after return\"],\n    [\"Above what order value is standard delivery free?\", \"free delivery threshold\", \"when is shipping free\"],\n    [\"On how many devices can I read my e-books?\", \"how many devices for ebooks\", \"ebook device limit\"],\n    [\"Can I cancel my order?\", \"how do I cancel an order\", \"cancel order\"],\n    [\"Can I cancel a pre-order?\", \"how do I cancel a pre-order\", \"cancel preorder\"],\n    [\"How long is a gift card valid?\", \"gift card expiry\", \"do gift cards expire\"],\n    [\"Will my e-books open on a Kindle?\", \"kindle ebooks\", \"can I read on kindle\"],\n    [\"Can I pay in instalments?\", \"pay in instalments\", \"split payment in three\"],\n    [\"When is a standard parcel considered lost?\", \"my parcel is lost\", \"parcel not arrived after two weeks\"],\n    [\"Who pays for the return postage?\", \"is returning free\", \"return shipping cost\"],\n]",
      "note": "Twelve topics, each with the ways the course wrote of asking it. The log is generated, not recorded: what lesson 17 measures with it is the cache, not Marginalia's customers."
    },
    {
      "code": "def main(out, n=500, seed=11):\n    rng = random.Random(seed)\n    weights = [1 / (k + 1) for k in range(len(PHRASINGS))]\n    users = [f\"u{i:03d}\" for i in range(1, 61)]\n    start = datetime(2026, 9, 21, 8, 0)\n    with open(out, \"w\") as f:\n        for i in range(n):\n            topic = rng.choices(range(len(PHRASINGS)), weights)[0]\n            text = rng.choice(PHRASINGS[topic])\n            at = start + timedelta(minutes=int(i * 7 * 24 * 60 / n) + rng.randrange(0, 15))\n            f.write(json.dumps({\"at\": at.strftime(\"%Y-%m-%dT%H:%M\"), \"user\": rng.choice(users),\n                                \"topic\": topic + 1, \"text\": text}) + \"\\n\")",
      "note": "Five hundred questions over a week, drawn with a fixed seed so that every run writes the same file: topics with weights that fall off like a support queue's, a phrasing, a time and one of sixty customers."
    },
    {
      "code": "if __name__ == \"__main__\":\n    main(\"data/querylog.jsonl\")"
    }
  ]
}
```

```
ana@vm:~/rag$ python querylog.py
ana@vm:~/rag$ wc -l data/querylog.jsonl
500 data/querylog.jsonl
ana@vm:~/rag$ head -n 2 data/querylog.jsonl
{"at": "2026-09-21T08:07", "user": "u033", "topic": 2, "text": "what does next day delivery cost"}
{"at": "2026-09-21T08:22", "user": "u052", "topic": 8, "text": "How long is a gift card valid?"}
```

`priced.py` runs every distinct question through lesson 7's pipeline once, records what it cost, and
adds up the week:

```schooling-example
{
  "language": "python",
  "file": "priced.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom answer import SYSTEM, prompt, sources_for\nfrom openai import OpenAI",
      "note": "Lesson 7's pipeline, its instructions and its prompt, and the week's log."
    },
    {
      "code": "client = OpenAI()\nenc = tiktoken.get_encoding(\"cl100k_base\")\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]",
      "note": "The provider's client, and tiktoken to count what the provider does not report."
    },
    {
      "code": "def run(question):\n    \"\"\"What answering one question costs, in tokens, through lesson 7's pipeline.\"\"\"\n    sources = sources_for(question)\n    cost = {\"embedding\": len(enc.encode(question)), \"input\": 0, \"output\": 0, \"instructions\": 0, \"sources\": 0}\n    if sources:\n        user = prompt(question, sources)\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n            {\"role\": \"system\", \"content\": SYSTEM}, {\"role\": \"user\", \"content\": user}])\n        cost.update(input=reply.usage.prompt_tokens, output=reply.usage.completion_tokens,\n                    instructions=len(enc.encode(SYSTEM)), sources=len(enc.encode(user)) - len(enc.encode(f\"Question: {question}\")))\n    return cost",
      "note": "One question priced: the tokens embedded for the search, and, if any source passed the floor, the tokens of the prompt and the reply as Ollama reports them. A question refused before the model costs only its embedding."
    },
    {
      "code": "if __name__ == \"__main__\":\n    costs = {text: run(text) for text in sorted({q[\"text\"] for q in LOG})}\n    json.dump(costs, open(\"costs.json\", \"w\"), indent=1)\n    total = {k: sum(costs[q[\"text\"]][k] for q in LOG) for k in (\"embedding\", \"input\", \"output\")}\n    calls = sum(1 for q in LOG if costs[q[\"text\"]][\"input\"])\n    print(f\"{len(LOG)} questions, {calls} model calls, {len(LOG) - calls} refused before the model\")\n    print(f\"embedding {total['embedding']:6} tokens\")\n    print(f\"input     {total['input']:6} tokens   {total['input'] / calls:.0f} per call\")\n    print(f\"output    {total['output']:6} tokens   {total['output'] / calls:.0f} per call\")",
      "note": "Every distinct question is priced once, and the week is the sum over the log. The same question costs the same every time it is asked, which is what a cache is about to exploit."
    }
  ]
}
```

```
ana@vm:~/rag$ python priced.py
500 questions, 486 model calls, 14 refused before the model
embedding   3551 tokens
input     155811 tokens   321 per call
output     26677 tokens   55 per call
```

**486 model calls for 500 questions.** Fourteen were refused before the model, because no source
passed the floor, and cost only the few tokens of their embedding; that is lesson 7's refusal paying
for itself. The calls that were made cost 321 input tokens and 55 output tokens on average, 155,811
and 26,677 over the week. The 3,551 tokens of embedding are small next to them, which is the usual
shape: generation is where a RAG pipeline's money goes, and embedding the question is close to free.

Two things to take from the shape before any number. **Input is most of it**, about six tokens in for
every one out, because a RAG prompt carries sources and a support answer is short. And **every
question pays the whole price** every time it is asked, even when the same question was answered a
minute earlier. The rest of the lesson is about those two facts.
