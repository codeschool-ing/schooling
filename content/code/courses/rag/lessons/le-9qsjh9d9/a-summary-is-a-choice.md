---
title: A summary is a choice
version: 1
---

`compact.py` asks the model for a summary in a given number of words:

```schooling-example
{
  "language": "python",
  "file": "compact.py",
  "parts": [
    {
      "code": "def summarise(turns, words):\n    \"\"\"extract-1's summary of the turns, in at most WORDS words.\"\"\"\n    reply = client.chat.completions.create(model=\"extract-1\", messages=[\n        {\"role\": \"system\", \"content\": f\"Summarise the conversation in at most {words} words.\"},\n        *({\"role\": \"user\", \"content\": t} for t in turns)])\n    return reply.choices[0].message.content",
      "note": "The summary is the model's: the instruction and the word limit in the system message, the turns as the conversation. With extract-1 it is a selection of whole sentences; with a language model it would be new sentences."
    }
  ]
}
```

Here is extract-1's summary of Beatriz's first eleven turns in at most 40 words:

```
ana@lab:~/rag$ python one.py 40
The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. For Persuasion I would like a replacement, not a refund. I bought it somewhere else in the meantime. How do I send back Mansfield Park?
```

Four sentences, all hers, and each one true. **Read as a record of the conversation, it is wrong in
ways nobody could see from the summary alone.** There is no order number, so an agent picking up the
chat starts by asking for it again. Nothing says she wants email only, so the next reply may promise a
phone call she said she cannot take. Nothing says where the replacement should go, so it goes to the
address she is leaving next week. And "I bought it somewhere else in the meantime" has lost the
sentence that said what "it" was.

extract-1 summarises by keeping the sentences closest to the conversation's average meaning, so it
keeps what the conversation is mostly about, two books and a mix-up, and drops what is said once: an
identifier, a preference, an address. A language model writes its own sentences instead and loses
different things, sometimes the same ones. **The point is not this summariser's choices; it is that
every summary is a choice**, made by something that does not know which details the next turn will
need. The next section measures the choice instead of reading it.
