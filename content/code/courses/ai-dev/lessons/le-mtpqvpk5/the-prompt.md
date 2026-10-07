---
title: Putting the passages in the prompt
version: 2
---

Retrieval found the passages; the prompt decides what the model does with them. Three instructions
carry most of the weight: **answer only from these passages, say which passage each sentence comes
from, and say so when the passages do not contain the answer**, in one fixed sentence that a program
can recognise.

```python
NOT_THERE = "The handbook does not say."


def prompt(question, found):
    passages = "\n".join(f"[{c['id']}] {c['text']}" for c, _ in found)
    return ("Answer only from the passages below. Cite the passage id in square brackets after "
            "every sentence. If the passages do not contain the answer, reply with exactly: "
            f"{NOT_THERE}\n\n{passages}\n\nQuestion: {question}")
```

Each passage goes in with its id in square brackets, the same id the answer is asked to cite. Here is
the whole prompt for one question, exactly as it would be sent:

```
ana@dev:~/shop$ PYTHONPATH=scratch python -c 'import rag; q = "Do you deliver to Portugal?"; print(rag.prompt(q, rag.hybrid_search(q)))'
Answer only from the passages below. Cite the passage id in square brackets after every sentence. If the passages do not contain the answer, reply with exactly: The handbook does not say.

[shipping.md#3] Shipping. The shop ships only to addresses in Brazil. It does not ship abroad and does not deliver to post office boxes.
[contact.md#1] Contacting support. Support answers by email and chat from 9:00 to 18:00, Monday to Friday, Brasília time, except public holidays. Messages that arrive outside those hours are answered the next working day, in the order they arrived.
[returns.md#3] Returns and refunds. The refund goes back to the original payment method once the item arrives at the warehouse and is checked, which takes up to five working days. Shipping costs are refunded only when the whole order is returned.

Question: Do you deliver to Portugal?
```

**Two of the three passages have nothing to do with the question.** The search always returns three,
and the prompt carries them. That is normal and mostly harmless, as long as the instructions tell the
model it may ignore what does not answer.

## The answer

`scratch/ask.py` retrieves, builds the prompt, asks `llama3.2:3b` and runs the citation check of
lesson 6 section 08 on the reply. It sets the temperature to 0, so the model takes the likeliest
token every time (lesson 1 section 08) and the same question mostly gets the same words. This
version of the Anthropic SDK has no `temperature` argument, so it goes in `extra_body`, which is
sent as it is and which Ollama reads:

```python
import sys

import anthropic

from rag import check_citations, hybrid_search, prompt

question = sys.argv[1]
found = hybrid_search(question)
r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=400, extra_body={"temperature": 0},
                                          messages=[{"role": "user", "content": prompt(question, found)}])
answer = r.content[0].text
print("retrieved:", ", ".join(c["id"] for c, _ in found))
print(answer)
problems = check_citations(answer, found)
print("citations:", "; ".join(problems) if problems else "every citation checks out")
```

```
ana@dev:~/shop$ python scratch/ask.py "Do you deliver to Portugal?"
retrieved: shipping.md#3, contact.md#1, returns.md#3
The shop does not ship abroad. [shipping.md#3]
citations: every citation checks out
```

One sentence, true, citing the passage it came from. The other two passages were ignored, which is
what the first instruction is for.

## When the answer is not there

A question the handbook does not answer still retrieves three passages, because search always
returns something:

```
ana@dev:~/shop$ python scratch/ask.py "Do you sell bicycles?"
retrieved: contact.md#2, payment-errors.md#2, coupons.md#3
The handbook does not say.
citations: every citation checks out
```

None of the three is about products, and the answer is the fixed sentence, word for word. **That
sentence is the reason for the third instruction.** Without it, the likely continuation of a question
about bicycles in a shop's support chat is an answer about bicycles, and lesson 1 section 11 showed
where likely continuations come from. Making it one exact sentence, rather than "say so", is lesson
5 section 05 again: a program can tell this answer from every other one by comparing two strings,
and the checker of the next section does.

## Choices in the prompt

- **Passages before the question.** The model reads the passages knowing what to look for when the
  question is at the end, and the passages form a stable prefix that lesson 2 section 07 can cache
  when many questions share them.
- **How many passages.** More passages raise the chance the answer is among them and add tokens and
  distractions. Three is small; tens are common. Measure it (lesson 6 section 09) rather than
  guessing.
- **Labelled clearly as data.** The passages are text from documents, and a document can contain
  sentences that look like instructions. Lesson 11 shows why that matters, and why the passages are
  marked as material to answer from rather than as part of the instructions.
