---
title: Forgetting
version: 2
---

Everything in the memory table was typed by a customer into a support chat, and customers type what
they need help with: their name, their order, their address, sometimes a card number. **A memory of a
customer is personal data**, held by Marginalia about an identifiable person, and in Brazil the LGPD
gives that person the right to know what is held and to have it deleted, as the privacy notice in
the corpus promises.

The table makes both rights cheap, because every row names its account:

```schooling-example
{
  "language": "python",
  "file": "remembered.py",
  "parts": [
    {
      "code": "import sys\n\nfrom search import conn\n\nfor turn, text in conn.execute(\"SELECT turn, text FROM memories WHERE account = %s ORDER BY turn\",\n                               (sys.argv[1],)):\n    print(f\"{turn:2}  {text}\")",
      "note": "Every turn the table holds for one account, in order."
    }
  ]
}
```

```
ana@vm:~/rag$ psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"
A-1001|12
A-1002|4
ana@vm:~/rag$ python remembered.py A-1002
 1  Hello, this is Rafael Lima. My order MG-31770254 has not arrived.
 2  It was sent by standard delivery and the tracking has not changed for twelve working days.
 3  I would prefer a refund rather than waiting for a new parcel.
 4  Could you remind me of my order number?
```

What Marginalia remembers about Rafael is four sentences, in his own words, readable by him and by an
auditor without interpreting anything. And when he asks to be forgotten:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def forget(account):\n    return conn.execute(\"DELETE FROM memories WHERE account = %s\", (account,)).rowcount",
      "note": "Erasing a customer's memory is one statement, because every row carries the account. A table that did not would need a search through text to find what to delete."
    }
  ]
}
```

```
ana@vm:~/rag$ python -c "import memory; print(memory.forget(\"A-1002\"), \"rows deleted\")"
4 rows deleted
ana@vm:~/rag$ psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"
A-1001|12
```

**Four rows deleted, and only his.** Beatriz's twelve are still there.

## Deciding what to keep, before keeping it

Erasure on request is the floor. Above it, a memory needs the decisions a team makes for any personal
data:

- **A reason for each thing kept**, and a time after which it goes. A chat's turns help answer the
  next turns of that chat and perhaps the next chat; they do not need to live for years. An
  `expires` column and a nightly delete make the retention period a fact rather than a policy.
- **Things never to keep at all.** A card number typed into a chat should not reach the table, or the
  log, or a prompt. The program can mask a pattern like that before `remember` writes the row, the
  same way it found order numbers.
- **Everything derived goes with the source.** If turns are summarised (lesson 15) or their facts
  copied into a state or a profile, the erasure has to reach those too. A row that was computed from a
  deleted row is the same data in another shape.

The question to ask of every memory feature is the one the next lesson asks of documents: whose is
this, and who else can see it.
