---
title: Putting the passages in the prompt
version: 1
---

Retrieval found the passages; the prompt decides what the model does with them. Three instructions
carry most of the weight: **answer only from these passages, say which passage each sentence comes
from, and say so when the passages do not contain the answer.**

```python
def prompt(question, found):
    passages = "\n".join(f"[{c['id']}] {c['text']}" for c, _ in found)
    return ("Answer only from the passages below. Cite the passage id in square brackets after "
            "every sentence that uses it. If the passages do not contain the answer, say so.\n\n"
            f"{passages}\n\nQuestion: {question}")
```

Each passage goes in with its id in square brackets, the same id the answer is asked to cite. Here is
the whole prompt for one question, exactly as it would be sent:

```
ana@dev:~/shop$ PYTHONPATH=lab python -c 'import rag; q = "Do you deliver to Portugal?"; print(rag.prompt(q, rag.hybrid_search(q)))'
Answer only from the passages below. Cite the passage id in square brackets after every sentence that uses it. If the passages do not contain the answer, say so.

[shipping.md#3] Shipping. The shop ships only to addresses in Brazil. It does not ship abroad and does not deliver to post office boxes.
[contact.md#1] Contacting support. Support answers by email and chat from 9:00 to 18:00, Monday to Friday, Brasília time, except public holidays. Messages that arrive outside those hours are answered the next working day, in the order they arrived.
[returns.md#3] Returns and refunds. The refund goes back to the original payment method once the item arrives at the warehouse and is checked, which takes up to five working days. Shipping costs are refunded only when the whole order is returned.

Question: Do you deliver to Portugal?
```

**Two of the three passages have nothing to do with the question.** The search always returns three,
and the prompt carries them. That is normal and mostly harmless, as long as the instructions tell the
model it may ignore what does not answer.

## The answer

`lab/ask.py` retrieves, builds the prompt, asks `scripted-1` and runs the citation check of lesson 6
section 08 on the reply. The answers in this lesson were written by the course; the retrieval and
the check are real:

```
ana@dev:~/shop$ python lab/ask.py "Do you deliver to Portugal?"
retrieved: shipping.md#3, contact.md#1, returns.md#3
No. "The shop ships only to addresses in Brazil" [shipping.md#3].
citations: every citation checks out
```

## When the answer is not there

A question the handbook does not answer still retrieves three passages, because search always
returns something:

```
ana@dev:~/shop$ python lab/ask.py "Do you sell bicycles?"
retrieved: contact.md#2, payment-errors.md#2, coupons.md#3
The passages do not say whether the shop sells bicycles.
citations: every citation checks out
```

None of the three is about products, and the answer says the passages do not say. **That sentence is
the reason for the third instruction.** Without it, the likely continuation of a question about
bicycles in a shop's support chat is an answer about bicycles, and lesson 1 section 07 showed where
likely continuations come from.

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
