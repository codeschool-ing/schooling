---
title: Why not put everything in the prompt
version: 2
---

If one document in the prompt fixes one question, all thirteen should fix every question. It is the
first idea everybody has, and for a small enough corpus and a large enough window it even works.
Measured on this one, it fails before the model writes a word, and the reasons it fails stay true
long after the window is big enough.

## Counting the corpus

A model reads, and a provider bills, in tokens, so the corpus has to be counted in tokens too.
`count.py` uses tiktoken's `cl100k_base`, the encoding OpenAI bills its GPT-4 models by. llama3.2
splits text with a tokenizer of its own, and counts a few percent differently; the course uses
tiktoken wherever it counts text it has not sent, because it is quick, needs no model running, and is
the count a paid provider would charge for.

```schooling-example
{
  "language": "python",
  "file": "count.py",
  "parts": [
    {
      "code": "import glob\nimport tiktoken\n\nenc = tiktoken.get_encoding(\"cl100k_base\")",
      "note": "tiktoken is OpenAI's tokenizer; `cl100k_base` is the encoding of its GPT-4 generation."
    },
    {
      "code": "total = 0\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    n = len(enc.encode(open(path).read()))\n    total += n\n    print(f\"{n:6,}  {path}\")\nprint(f\"{total:6,}  in all\")",
      "note": "Every document's length in tokens, and the total."
    }
  ]
}
```

```
ana@vm:~/rag$ python count.py
   816  data/docs/affiliate-api.md
   660  data/docs/ebooks-and-audiobooks.md
   483  data/docs/finance-refund-controls.md
   342  data/docs/gift-cards.md
   617  data/docs/payments-and-invoices.md
   626  data/docs/privacy-notice.md
   403  data/docs/returns-policy-2025.md
 1,113  data/docs/returns-policy.md
   726  data/docs/seller-agreement.md
   845  data/docs/shipping-and-delivery.md
   906  data/docs/support-handbook.md
   841  data/docs/terms-of-sale.md
   536  data/docs/warehouse-runbook.md
 8,914  in all
```

**8,914 tokens for 6,843 words**, about 1.3 tokens a word, which is typical for English prose with
some numbers and identifiers in it. `everything.py` puts all thirteen in one prompt, numbered, and
asks the price of express delivery:

```schooling-example
{
  "language": "python",
  "file": "everything.py",
  "parts": [
    {
      "code": "import glob\nfrom openai import OpenAI\n\nclient = OpenAI()\nsources = \"\"\nfor i, path in enumerate(sorted(glob.glob(\"data/docs/*.md\")), 1):\n    sources += f\"[{i}] {path}\\n{open(path).read()}\\n\"",
      "note": "All thirteen documents, numbered, in one string."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[{\"role\": \"user\", \"content\": sources + \"Question: How much is express delivery?\"}],\n)\nprint(reply.choices[0].message.content)\nprint(\"prompt tokens:\", reply.usage.prompt_tokens)",
      "note": "One question, and how many tokens of the request the model says it read."
    }
  ]
}
```

```
ana@vm:~/rag$ python everything.py
Here is a response to the customer's question about express delivery:

Dear [Customer],

Yes, express delivery is available for an additional fee. The cost is [insert cost] and delivery is typically [insert timeframe, e.g. "next day" or "2-3 working days"].

Please note that express delivery is only available for orders placed before [insert cutoff time, e.g. "12pm"] and is subject to availability.

If you would like to upgrade to express delivery, please contact us at [insert contact email or phone number] and we will be happy to assist you.

Best regards,
[Your Name]

Note: I've followed the guidelines provided, including:

* Starting with a clear and concise answer to the customer's question
* Providing additional information about express delivery, such as the cost and timeframe
* Mentioning any limitations or cutoff times for express delivery
* Including a clear call to action for the customer to contact support if they would like to upgrade to express delivery
* Signing off with a professional closing and your name.
prompt tokens: 2050
```

**The model read 2,050 tokens of a prompt about four and a half times that long, and nothing
refused.** Ollama serves llama3.2:3b with a window of 4,096 tokens and keeps room in it for the reply,
so it cut the prompt to fit and sent the rest to the model. Its own log, which `journalctl -u ollama`
shows on the VM, said so in one line nobody reads:

```
level=WARN msg="truncating input prompt" limit=2050 prompt=9094 keep=4 new=2050
```

What survived was the end: the question, and before it roughly the last two and a half documents in
alphabetical order, the close of the support handbook, the terms of sale and the warehouse runbook.
The price of express delivery is in `shipping-and-delivery.md`, the tenth document, and was cut
before the model saw it. So the model did what it does with a question and no answer in sight: it
wrote a customer-service template, `[insert cost]` where the price should be, and then a note saying
it had followed the guidelines, the support handbook's rules for agents, which did survive.

Two things are worth taking from this beyond the size of the corpus. **A window that is too small
does not always fail loudly**: a commercial API answers an oversized request with an error, and a
local server may cut it and carry on. And **`prompt_tokens` is the one place the truncation shows**:
the request carried about 9,000 tokens, and the model says it read 2,050. Lesson 9's program logs
that number for every question, for exactly this reason.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 302\" role=\"img\" aria-label=\"Four bars measured in llama3.2 tokens. Every document and one question: 9,094. What the model read after Ollama cut the prompt: 2,050. The window Ollama serves, for prompt and reply together: 4,096. One document and one question: 1,166.\"><text x=\"218\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">every document</text><text x=\"218\" y=\"71\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and one question</text><rect x=\"230\" y=\"44\" width=\"440.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"678.0\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9,094</text><text x=\"218\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what the model read</text><text x=\"218\" y=\"133\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">after Ollama cut it</text><rect x=\"230\" y=\"106\" width=\"99.2\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"337.2\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2,050</text><text x=\"218\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the window Ollama serves</text><text x=\"218\" y=\"195\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">prompt and reply</text><rect x=\"230\" y=\"168\" width=\"198.2\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><text x=\"436.2\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4,096</text><text x=\"218\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one document</text><text x=\"218\" y=\"257\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and one question</text><rect x=\"230\" y=\"230\" width=\"56.4\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"294.4\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1,166</text></svg>", "caption": "The thirteen documents and a question came to 9,094 tokens; Ollama kept the last 2,050 and the model never saw the rest. One document and the same question came to 1,166. The first number is from Ollama's log, the others from the replies."}
```

## Suppose it fitted

A window of a million tokens would take this corpus a hundred times over. Three costs remain, and
each grows with the corpus, not with the question.

**Every question pays for every document.** At an illustrative price of 3 per million input tokens,
not any provider's, the 8,914 tokens of the documents cost 0.027 to send, and ten thousand questions
a day cost 267 a day before a single word of reply. The same questions with one relevant document cost about an
eighth of that. Providers cache a repeated prefix at a discount, and lesson 17 counts what that buys,
but a discount on text the question did not need is still a price for text the question did not
need.

**Every question waits for every document.** A model reads its whole prompt before it writes the
first token of a reply, and reading takes time in proportion to the length. A support chat that
reads the warehouse runbook before answering a question about gift cards is slower for no reason
the customer could see.

**Every question competes with every document.** The more unrelated text a prompt holds, the more
chances the reply has to use the wrong part of it. In the run above, the support handbook's rules for
agents survived the cut and shaped a reply to a question they had nothing to do with. Researchers
measuring models with long contexts found that they use information at the start and the end of a
long prompt better than information in the middle; the paper is *Lost in the Middle*, Liu and others,
2023. Lesson 12 comes back to what it means for how a prompt is packed.

## And the corpus grows

Thirteen documents is a teaching corpus. A real support team's knowledge base runs to thousands of
articles, a law firm's to millions of pages, and both change every week. Whatever fits today will
not fit next year, and a design that depends on it fitting has a date on which it breaks.

So the useful question is not *how do I fit everything in* but **how do I find, for this question,
the few passages that answer it, and send only those.** That is retrieval, and the next section
builds the smallest version of it.
