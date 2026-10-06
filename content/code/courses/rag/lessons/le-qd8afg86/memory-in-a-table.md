---
title: Memory in a table
version: 1
---

Recalling a turn needs the turns to be somewhere a search can reach. `memory.py` keeps them in a
table in the same database as the documents, one row per turn, embedded with the same model:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS memories (\n    id           bigserial PRIMARY KEY,\n    account      text NOT NULL,\n    conversation text NOT NULL,\n    turn         int NOT NULL,\n    text         text NOT NULL,\n    embedding    vector(384) NOT NULL,\n    created      timestamptz NOT NULL DEFAULT now()\n);\nCREATE INDEX IF NOT EXISTS memories_account ON memories (account);\n\"\"\"\nORDER = re.compile(r\"\\bMG-\\d{8}\\b\")\nconn.execute(SCHEMA)",
      "note": "One row per turn of every conversation, with the account it belongs to and the turn's embedding. The index on `account` is there because every query has to name one."
    },
    {
      "code": "def remember(account, conversation, turn, text):\n    conn.execute(\"INSERT INTO memories (account, conversation, turn, text, embedding) VALUES (%s, %s, %s, %s, %s)\",\n                 (account, conversation, turn, text, embed(text)[0]))",
      "note": "Each turn is kept the moment it is said, before the next one arrives."
    },
    {
      "code": "def recall(account, question, k=2, before=None):\n    \"\"\"The K earlier turns of THIS account most similar to the question, oldest first.\"\"\"\n    q = embed(question)[0]\n    found = conn.execute(\n        \"SELECT turn, text, 1 - (embedding <=> %s) FROM memories WHERE account = %s AND turn < %s\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, account, before or 2**31 - 1, q, k)).fetchall()\n    return sorted(found)",
      "note": "Lesson 6's search over a customer's own turns. `account` is not optional: the function cannot be called without saying whose memory it searches. `before` keeps a turn from recalling itself."
    }
  ]
}
```

It is **external memory**: outside the model, outside the prompt, in storage the application owns
and queries. The model never remembers anything between two calls; whatever it seems to remember was
put in front of it by the program, and this table is where the program keeps it. That makes memory
an ordinary engineering problem, with a schema, an index, queries that can be read, and rows that can
be deleted.

Three properties of this table are decisions rather than details.

- **Every row carries the account.** Not the conversation, which is a session and ends, but the
  person, who comes back. Every question about memory, recall, privacy, erasure, is a question about
  one person's rows.
- **The turns are kept as the customer wrote them**, not summarised or extracted. A summary is a
  model's reading of what was said, and lesson 15 is about when that trade is worth making; the
  original words can always be summarised later, and a summary can never be turned back into them.
- **Recall is a search, with lesson 6's tools.** The same embedding model and the same cosine
  distance as the document search, so the floor-like `LIKE` of the previous section can be chosen
  the same way, by looking at scores.

`chat.py` writes each turn after answering it and recalls before answering the next, so a turn can
recall anything said before it and never itself.
