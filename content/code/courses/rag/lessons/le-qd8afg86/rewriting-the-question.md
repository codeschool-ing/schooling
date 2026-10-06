---
title: Rewriting the question
version: 1
---

The search needs a question that stands on its own. The common fix is a **rewrite**: before
searching, ask a model to turn the latest message and the conversation so far into one question that
needs no history. LlamaIndex's chat engine that does this carries its instruction as a template:

```
ana@lab:~/rag$ python condense.py
Given a conversation (between Human and Assistant) and a follow up message from Human, rewrite the message to be a standalone question that captures all relevant context from the conversation.

<Chat History>
{chat_history}

<Follow Up Message>
{question}

<Standalone question>
```

"How do I send back Mansfield Park?" would come back as something like "How do I return a book that
was sent instead of the one I ordered?", and that searches well. LangChain has the same step under
the name of a history-aware retriever. The price is a second model call on every turn, before the
search can start, and a new place to be wrong: a rewrite that drops a detail, or adds one, searches
for a question the customer did not ask. Lesson 8's test is how a team finds out which.

extract-1 cannot rewrite anything; it copies sentences. So this lab does a cheaper version with no
model at all: **find the earlier turn most like the new message, and put it in front for the
search**. It is a recall, the same kind of search as lesson 6's, over the customer's own turns:

```
ana@lab:~/rag$ python recalled.py chat-a A-1001 10 11 12
turn 10: How do I send back Mansfield Park?
   0.579  turn 3: The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park.
   0.373  turn 7: I have photographs of the damaged cover next to the box. Where do I send them?
turn 11: How long will the refund for Middlemarch take?
   0.427  turn 5: For Persuasion I would like a replacement, not a refund.
   0.682  turn 6: For Middlemarch I want my money back. I bought it somewhere else in the meantime.
turn 12: Sorry, what was my order number again? I need it for my notes.
   0.492  turn 1: Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   0.325  turn 2: The order had two books. Persuasion arrived with water damage on the cover.
```

For each question, the two earlier turns closest to it. **Turn 10 recalls turn 3**, the wrong book,
at 0.579, and **turn 11 recalls turn 6**, "For Middlemarch I want my money back", at 0.682. Those are
the turns a rewrite would have used. The second recalled turn is weaker every time, so `chat.py`
takes only the closest one, and only when it reaches `LIKE`, 0.5; turn 12's best match, turn 1, is
0.492 and is left out, which the section on state comes back to. A recalled turn that is not like the
question at all would steer the search away from what was asked, which is the same drift a careless
rewrite causes.

The recalled turn goes into the search and **not into the prompt**. The model is asked the
customer's question as they wrote it. Beatriz's own words are not a source: they are what she said,
not what Marginalia's policy says, and a reply that cites them cites her to herself, which is turn
10 of the previous section.
