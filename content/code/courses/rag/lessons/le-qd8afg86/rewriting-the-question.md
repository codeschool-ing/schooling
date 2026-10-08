---
title: Rewriting the question
version: 2
---

The search needs a question that stands on its own. The common fix is a **rewrite**: before
searching, ask a model to turn the latest message and the conversation so far into one question that
needs no history. LlamaIndex's chat engine that does this carries its instruction as a template:

```schooling-example
{
  "language": "python",
  "file": "condense.py",
  "parts": [
    {
      "code": "from llama_index.core.chat_engine.condense_question import DEFAULT_TEMPLATE\n\nprint(DEFAULT_TEMPLATE)",
      "note": "The instruction LlamaIndex's condensing chat engine sends, printed from the library itself."
    }
  ]
}
```

```
ana@vm:~/rag$ python condense.py
Given a conversation (between Human and Assistant) and a follow up message from Human, rewrite the message to be a standalone question that captures all relevant context from the conversation.

<Chat History>
{chat_history}

<Follow Up Message>
{question}

<Standalone question>
```

`rewrite.py` sends that template to llama3.2:3b with Beatriz's earlier turns as the history, and
searches with what comes back:

```schooling-example
{
  "language": "python",
  "file": "rewrite.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nfrom llama_index.core.chat_engine.condense_question import DEFAULT_TEMPLATE\nfrom openai import OpenAI\nfrom search import vector\n\nclient = OpenAI()\nturns = [json.loads(line)[\"text\"] for line in open(f\"data/{sys.argv[1]}.jsonl\")]",
      "note": "LlamaIndex's template, the model, and lesson 6's search. Only the template is borrowed: the call is the plain SDK's."
    },
    {
      "code": "for n in map(int, sys.argv[2:]):\n    history = \"\\n\".join(f\"Human: {t}\" for t in turns[:n - 1])\n    prompt = DEFAULT_TEMPLATE.format(chat_history=history, question=turns[n - 1])\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0,\n                                           messages=[{\"role\": \"user\", \"content\": prompt}])\n    question = reply.choices[0].message.content.strip()\n    top = vector(question, 1, \"status = %s\", (\"current\",))[0]\n    print(f\"turn {n}: {turns[n - 1]}\")\n    print(f\"  rewritten: {question}\")\n    print(f\"  {top[3]:.3f}  {top[1]}\")",
      "note": "For each turn named, the customer's earlier turns as the history, the rewrite the model returns, and the chunk the rewritten question finds first."
    }
  ]
}
```

```
ana@vm:~/rag$ python rewrite.py chat-a 10 11 12
turn 10: How do I send back Mansfield Park?
  rewritten: Can I return the damaged copy of Mansfield Park and send it back to you, and if so, where should I send it?
  0.594  Returns and refunds policy > Damaged, faulty and wrong items
turn 11: How long will the refund for Middlemarch take?
  rewritten: Here is a rewritten version of the follow-up message as a standalone question that captures all relevant context from the conversation:

"Will the refund for the incorrect book, Mansfield Park, be processed quickly enough to arrive before I move house next week, and if so, how long can I expect it to take?"
  0.592  Returns and refunds policy > Damaged, faulty and wrong items
turn 12: Sorry, what was my order number again? I need it for my notes.
  rewritten: What is the order number for the two parcels that were sent to me, one of which has water damage and the other of which contains the wrong book?
  0.590  Returns and refunds policy > Damaged, faulty and wrong items
```

**Three rewrites, three mistakes, and three searches that found the damaged-books section.** Turn 10
became a question about returning *the damaged copy of Mansfield Park*; the damaged book was
*Persuasion*. Turn 11's rewrite began *Here is a rewritten version of the follow-up message*, the
model talking about its task instead of doing it, and then swapped the titles: the refund is for
*Middlemarch*, and the rewrite asks about *Mansfield Park*. Turn 12 asked for the order number of *the
two parcels*, which no document can answer. A rewrite is a model call, and a model call can be wrong;
this one was wrong every time, and each mistake went straight into the search.

There is a cheaper version with no model call at all: **find the earlier turn most like the new
message, and put it in front for the search**. It is a recall, the same kind of search as lesson 6's,
over the customer's own turns. It reads them from the table the section after next sets up, so
`chat.py` in that mode runs first, silently, to fill it:

```schooling-example
{
  "language": "python",
  "file": "recalled.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nimport memory\n\nchat, account = sys.argv[1], sys.argv[2]\nturns = [json.loads(line)[\"text\"] for line in open(f\"data/{chat}.jsonl\")]\nfor n in map(int, sys.argv[3:]):\n    print(f\"turn {n}: {turns[n - 1]}\")\n    for turn, text, score in memory.recall(account, turns[n - 1], 2, before=n):\n        print(f\"   {score:.3f}  turn {turn}: {text}\")",
      "note": "For each turn named on the command line, the two earlier turns of the same customer that `memory.recall` finds closest to it."
    }
  ]
}
```

```
ana@vm:~/rag$ python chat.py chat-a memory > /dev/null
ana@vm:~/rag$ python recalled.py chat-a A-1001 10 11 12
turn 10: How do I send back Mansfield Park?
   0.578  turn 3: The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park.
   0.372  turn 7: I have photographs of the damaged cover next to the box. Where do I send them?
turn 11: How long will the refund for Middlemarch take?
   0.427  turn 5: For Persuasion I would like a replacement, not a refund.
   0.682  turn 6: For Middlemarch I want my money back. I bought it somewhere else in the meantime.
turn 12: Sorry, what was my order number again? I need it for my notes.
   0.491  turn 1: Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   0.325  turn 2: The order had two books. Persuasion arrived with water damage on the cover.
```

For each question, the two earlier turns closest to it. **Turn 10 recalls turn 3**, the wrong book,
at 0.578, and **turn 11 recalls turn 6**, "For Middlemarch I want my money back", at 0.682. Those are
the turns a rewrite would have used. The second recalled turn is weaker every time, so `chat.py`
takes only the closest one, and only when it reaches `LIKE`, 0.5; turn 12's best match, turn 1, is
0.491 and is left out, which the section on state comes back to. A recalled turn that is not like the
question at all would steer the search away from what was asked, which is the same drift a careless
rewrite causes.

The recalled turn goes into the search and **not into the prompt**. The model is asked the
customer's question as they wrote it. Beatriz's own words are not a source: they are what she said,
not what Marginalia's policy says, and a reply that cites them cites her to herself.
