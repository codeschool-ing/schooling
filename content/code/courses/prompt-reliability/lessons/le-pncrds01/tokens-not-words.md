---
title: Tokens, not words
version: 2
---

Every length setting a model offers counts tokens, and **a token is not a word**. `prompt-engineering`
introduced tokens in its lesson 3 and the output limit in its lesson 15. This lesson takes the limit
again on purpose, with a narrower question: what a cut does to an answer that a program has to read.

To count tokens you need the model's own tokeniser, the piece that turns text into the numbered
pieces the model reads. Ollama has no command that only counts, but every reply reports how many
tokens the model read, so a short program can send a text and read the count back. Save it as
`tokens.py`:

```python
"""tokens: how many tokens the model's own tokeniser makes of a text."""
import json
import sys
import urllib.request

from pl import DEFAULTS, OLLAMA


def count(text):
    # Ollama has no endpoint that only counts, so this sends the text raw, with
    # no chat template around it, asks for one token back, and reads how many
    # tokens the model had to read. That count includes the one token the model
    # puts at the start of every text, so it is taken off.
    body = {"model": DEFAULTS["model"], "prompt": text, "raw": True, "stream": False,
            "options": {"num_predict": 1}}
    req = urllib.request.Request(OLLAMA + "/api/generate", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))["prompt_eval_count"] - 1


text = sys.stdin.read() if sys.argv[1:] == ["-"] else open(sys.argv[1], encoding="utf-8").read()
print("%d tokens, %d words, %d characters" % (count(text), len(text.split()), len(text)))
```

It takes a file, or `-` for whatever is piped into it:

```
ana@lab:~/triage$ python3 tokens.py prompts/v4-only-json.txt
85 tokens, 59 words, 362 characters
ana@lab:~/triage$ echo 'They were charged twice for order 4471.' | python3 tokens.py -
10 tokens, 7 words, 40 characters
ana@lab:~/triage$ echo '{"summary": "They were charged twice for order 4471."}' | python3 tokens.py -
15 tokens, 8 words, 55 characters
```

The sentence is seven words and ten tokens: `echo` adds a line break, which is a token, and
`llama3.2:3b`'s tokeniser splits the order number into pieces. Put the same sentence inside one JSON
field and it comes to fifteen: the braces, the colon, the quotation marks and the field's name are
tokens too, though the tokeniser merges some of them with their neighbours.

**Each model splits text its own way, and a provider charges by its own count.** Common words tend to
be one token, rare or long words are split into pieces, and punctuation is often merged with what
stands next to it. So these counts are `llama3.2:3b`'s and nobody's bill. What carries over is the
proportion this lesson is about: in a JSON answer, a large share of what the model writes is
structure.

## Where the tokens of an answer go

Here is one reply from the prompt that asks for the JSON object and nothing else:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "Refund duplicate payment for order 4471"}
stop: stop, tokens in 123, out 28, 3.5 s
```

`out 28` is the length of that reply in tokens. The summary, the part a person reads, is a minority
of them. The rest is the frame: field names, labels and punctuation.

That proportion decides two things in the rest of this lesson. **A cap chosen by thinking about how
long a summary should be will be too small**, because the summary is only part of the reply. And
asking for a shorter summary moves the total less than you would expect, because the frame does not
shrink when the sentence does.
