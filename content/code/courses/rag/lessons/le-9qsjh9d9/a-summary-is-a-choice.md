---
title: A summary is a choice
version: 2
---

`compact.py` asks the model for a summary in a given number of words:

```schooling-example
{
  "language": "python",
  "file": "compact.py",
  "parts": [
    {
      "code": "\"\"\"Making a long conversation short: pin what must survive word for word, summarise the rest, keep the\nlatest turns as they were.\"\"\"\nimport re\n\nimport tiktoken\nfrom memory import ORDER\nfrom openai import OpenAI\n\nclient = OpenAI()\nenc = tiktoken.get_encoding(\"cl100k_base\")\n# A sentence is pinned when it carries something a later turn may need exactly: an identifier, or a\n# choice the customer made. The patterns are the team's, written down and tested like any code.\nPIN = re.compile(rf\"{ORDER.pattern}|\\b(only|please|would like|want|instead|should go to)\\b\", re.I)\nKEEP = 3",
      "note": "A sentence is pinned when it carries an order number or one of a few words that mark a choice. The rule is written down beside the code, so it can be read, argued with and tested."
    },
    {
      "code": "def tokens(text):\n    return len(enc.encode(text))",
      "note": "Tokens counted with tiktoken, as in lesson 12."
    },
    {
      "code": "def sentences(text):\n    return [s for s in re.split(r\"(?<=[.!?])\\s+(?=[A-Z])\", text.strip()) if s]",
      "note": "Sentences, split at the end of each one."
    },
    {
      "code": "def summarise(turns, words):\n    \"\"\"The model's summary of the turns, in at most WORDS words. The turns go in as one text to\n    summarise, never as messages: sent as messages, they are a conversation, and a model answers it.\"\"\"\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n        {\"role\": \"system\", \"content\": f\"Summarise the text the user sends in at most {words} words. \"\n                                      \"Reply with the summary and nothing else.\"},\n        {\"role\": \"user\", \"content\": \"\\n\".join(turns)}])\n    return reply.choices[0].message.content",
      "note": "The summary is the model's: the instruction and the word limit in the system message, and the turns as one text in the user's message. Sent as messages of their own, the turns were a conversation, and llama3.2:3b answered it instead of summarising it. Which details the summary keeps is the model's choice."
    },
    {
      "code": "def pinned(turns):\n    return [s for t in turns for s in sentences(t) if PIN.search(s)]",
      "note": "Pinned sentences are kept word for word, never summarised."
    },
    {
      "code": "def compact(turns, words=30, keep=KEEP):\n    \"\"\"The pinned sentences of the older turns, a summary of what is left of them, and the last KEEP\n    turns as they were.\"\"\"\n    older, recent = turns[:-keep], turns[-keep:]\n    pins = pinned(older)\n    rest = [s for t in older for s in sentences(t) if s not in pins]\n    return {\"pinned\": pins, \"summary\": summarise(rest, words) if rest else \"\", \"recent\": recent}",
      "note": "The older turns are split: what is pinned stays, the rest goes to the summariser. The last three turns stay as they were, because the next reply is most likely to be about them."
    },
    {
      "code": "def text_of(compacted):\n    return \"\\n\".join(compacted[\"pinned\"] + [compacted[\"summary\"]] + compacted[\"recent\"])",
      "note": "The compacted conversation as one text, in the order a prompt would carry it."
    }
  ]
}
```

Here is llama3.2:3b's summary of Beatriz's first eleven turns in at most 40 words:

```schooling-example
{
  "language": "python",
  "file": "one.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nfrom compact import summarise\n\nturns = [json.loads(line)[\"text\"] for line in open(\"data/chat-a.jsonl\")]\nprint(summarise(turns[:11], int(sys.argv[1])))",
      "note": "Beatriz's first eleven turns, summarised in as many words as the command line says."
    }
  ]
}
```

```
ana@vm:~/rag$ python one.py 40
Beatriz Costa's order MG-20481937 had two issues: a water-damaged Persuasion book and a wrong book, Mansfield Park instead of Middlemarch. She wants a replacement Persuasion and a refund for Middlemarch, with replacement to be sent to Rua das Flores 120, Curitiba.
```

Two sentences, fluent and true. They kept the order number, both books, what she wants for each and
the new address. **They dropped one thing, and it is the one an agent needs before writing back**:
Beatriz asked to be contacted by email only, because she cannot take phone calls at work, and nothing
in the summary says so. The next reply may promise a phone call.

This summary chose well, at 40 words, on this conversation, on this run. **The point is not this
summary's choices; it is that every summary is a choice**, made by something that does not know which
details the next turn will need, and that a summary that reads perfectly says nothing about what it
left out. The next section measures the choice instead of reading it.
