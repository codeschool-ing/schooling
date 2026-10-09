---
title: State the program writes
version: 2
---

Turn 12 asked for the order number. The whole history answered it, by sending turn 1 again with
every turn after it, at 1,201 tokens for that one question; the recall left turn 1 out at 0.491, and
no document holds it. The order number is not something to search for. **It is a fact the application
already knows**, and the way to give it to the model is to write it down.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def state(account, name):\n    \"\"\"What the program knows for certain, written as sentences a reply to the customer can quote.\"\"\"\n    said = \" \".join(t for (t,) in conn.execute(\"SELECT text FROM memories WHERE account = %s ORDER BY turn\",\n                                               (account,)))\n    orders = list(dict.fromkeys(ORDER.findall(said)))\n    lines = [f\"The customer is {name}.\"]\n    if orders:\n        lines.append(f\"The customer's order number is {' and '.join(orders)}.\")\n    return \" \".join(lines)",
      "note": "Only what the program can be sure of: the name from the account, and order numbers found in the customer's own words by their exact pattern. Each fact is written as a sentence about the customer, so a reply can quote it and cite it."
    }
  ]
}
```

```
ana@vm:~/rag$ python -c "import memory; print(memory.state(\"A-1001\", \"Beatriz Costa\"))"
The customer is Beatriz Costa. The customer's order number is MG-20481937.
```

The state is two sentences, and each comes from somewhere certain. The name comes from the account
that is signed in, which in this course is a dictionary in `chat.py` standing in for the shop's
account table. The order number is found in the customer's own words by its exact shape, `MG-` and
eight digits, which a regular expression can match without guessing. Nothing in it is a model's
interpretation, so nothing in it can be a model's mistake.

`chat.py` sends the state as source [1], ahead of the documents, so a reply can quote it and cite
it like any source:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def remembered(text, past, account, name):\n    \"\"\"The earlier turns most like this one, if they are like it at all, put in front of it to make\n    a search that stands on its own; the state as a source; and the documents that search finds. The customer's own words steer\n    the search and are never sources to cite; the model is asked what the customer asked.\"\"\"\n    recalled = [r for r in memory.recall(account, text, RECALL) if r[2] >= LIKE]\n    search = \" \".join([t for _, t, _ in recalled] + [text])\n    state = {\"path\": \"what we know about this customer\", \"text\": memory.state(account, name)}\n    return ask([state] + sources_for(search), text)",
      "note": "The recalled turn, if it passes `LIKE`, is put in front of the question for the search only. The model gets the state as source [1], the documents after it, and the customer's question as they asked it."
    }
  ]
}
```

```
ana@vm:~/rag$ python chat.py chat-b memory
 1   132 tokens
 2   306 tokens
 3   312 tokens
 4   135 tokens  Could you remind me of my order number?
   no document above the floor
   I could not find that in our documents.
885 prompt tokens over 4 turns
```

Rafael Lima's conversation, the second one in `data/`, asks the same thing at its fourth turn, and
**the reply is the refusal, with the answer as source [1]**. Beatriz's turn 12, in the next section, is
refused the same way. The model reads the state: in that section, its reply to turn 10 quotes the
order number from it, unasked. What it will not do is answer a question from it. Lesson 7's
instruction says to refuse when the sources do not answer, and llama3.2:3b decided that a line about
the customer is not one of *our documents*.

So the state, as a source, half works with this model: it informs replies and does not answer the
question it was written for. **A fact the program knows for certain is the program's to say**, and
routing it through the model gives the model a chance to refuse it. An account page that shows the
order number, or a reply the program writes itself when the question is about the account, cannot be
refused by an instruction that was written for policies. What the state is still for is everything
else the model writes: a reply that knows who it is talking to and which order the chat is about.

## What belongs in a state

A state is for what the program **knows**: the account, the order the chat is about, what the
customer chose in a form, what a tool returned. It is a poor place for what a model **inferred**,
like "the customer prefers email", because an inference written as a fact is cited as a fact.
Beatriz did say "Please write to me by email only", and a support system would want that remembered;
the place for it is the account's contact preference, set by a person or confirmed by the customer,
and from there the state can read it as certain.
