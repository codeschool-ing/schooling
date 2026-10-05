---
title: What it cannot see
version: 1
---

An embedding detector measures one thing: how far a message's **subject** is from the subjects of
normal messages. Lesson 1 showed that an embedding captures what a text is about far better than
what it asserts, and that limit carries straight over to anomalies. A message can be dangerous and
perfectly on topic.

```schooling-example
{
  "language": "python",
  "file": "blind.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\nref = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"train\"])\nheld = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"test\"])\nbest = lambda Q, R: (Q @ R.T).max(axis=1)\ncut = np.percentile(1 - best(held, ref), 95)",
      "note": "The reference and the cut-off from the threshold section: k=1 against the 100 training tickets, at the 95th percentile of the 50 held-out ones."
    },
    {
      "code": "messages = [\n    \"Please refund the 4,800 I paid for order 1182, the book never came.\",\n    \"Change the email on my account to a new address and send the password there.\",\n    \"I want to return all 40 copies of the same novel I bought yesterday.\",\n    \"Meu pedido ainda não chegou e já faz duas semanas, alguém pode me ajudar?\",\n    \"My order still hasn't arrived and it has been two weeks, can somebody help me?\",\n]\nfor text, s in zip(messages, 1 - best(embed(messages), ref)):\n    print(f\"{s:.3f}  {'flag' if s > cut else 'pass'}  {text[:60]}\")",
      "note": "Five messages written for this section. Three are dangerous and look ordinary; the last two are one complaint in Portuguese and in English."
    }
  ]
}
```

```
ana@lab:~/emb$ python blind.py
0.347  pass  Please refund the 4,800 I paid for order 1182, the book neve
0.313  pass  Change the email on my account to a new address and send the
0.317  pass  I want to return all 40 copies of the same novel I bought ye
0.760  flag  Meu pedido ainda não chegou e já faz duas semanas, alguém po
0.334  pass  My order still hasn't arrived and it has been two weeks, can
```

## Dangerous and normal-looking

The first three messages pass, with scores well under the cut-off at 0.560.

- A refund request for 4,800 on what is presumably a small order is a refund request. The amount is
  what makes it suspicious, and an embedding does not compare amounts.
- A request to move the account's e-mail and send the password there is an account question, and
  it is also how somebody takes over an account that is not theirs.
- Forty copies of one novel returned the day after buying is a return. Whether it is fraud depends
  on who is asking and what they bought, which is not in the text.

All three are anomalies of **content within a normal topic**, and they need checks that read the
content: rules on amounts, the order history, the account's own record, and a person. The
detector here is a filter for messages that are about the wrong thing. It is not a fraud system,
and describing it as one would be the most expensive mistake this lesson could leave behind.

## Flagged for the model's reasons

The last two lines are one complaint: an order that has not arrived after two weeks. In English it
scores 0.334 and passes. In Portuguese it scores 0.760 and is flagged, more than twice as far from
normal.

The message is not odd. The **model** is: all-MiniLM-L6-v2 was trained on English, and lesson 1
measured a sentence and its Portuguese translation at −0.015. The course marked this message odd
because to this shop's English-only reference it is, and the detector agrees for the same reason.
A multilingual model, which lesson 9 shows how to recognise, would place it beside the shipping
tickets and pass it. If what you need is to know which language a message is in, a language
detector answers that directly and reliably; an embedding answers it by accident.

## Where it earns its keep

Put together, the lesson's measurements say what this kind of detector is good for:

| catches | misses or misreads |
|---|---|
| messages about the wrong subject: spam, recipes, job applications | a normal-looking message with the wrong amount, account or intent |
| keyboard noise | a new topic that arrives a few messages at a time, until you watch the batch |
| text the model cannot read, such as other languages for an English model | the difference between a foreign language and a foreign subject |

It is cheap, needs no examples of what it is looking for, and keeps working when next week's spam
is different from this week's. Those are the reasons to use it, in front of a person and beside
the checks that read what a message says.
