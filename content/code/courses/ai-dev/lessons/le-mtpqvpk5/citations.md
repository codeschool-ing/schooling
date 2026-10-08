---
title: Checking the citations
version: 2
---

An answer with citations looks trustworthy, and that is a risk of its own. A citation is a claim
about where a sentence came from, and **a model can produce a citation the same way it produces any
other text**: the likely-looking id, after the likely-looking sentence. The good news is that this
claim, unlike most of what a model says, can be checked by a program.

## Three checks a program can make

```python
def check_citations(answer, found):
    """Every sentence cites a passage that was retrieved, and every quoted phrase is in it."""
    given = {c["id"]: c["text"] for c, _ in found}
    if answer.strip() == NOT_THERE:
        return []
    problems = []
    for sentence in re.split(r"(?<=[.!?\]])\s+(?!\[)", answer.strip()):
        cited = re.findall(r"\[([\w.-]+#\d+)\]", sentence)
        if not cited:
            problems.append(f'cites nothing: "{sentence[:50]}"')
        for cid in cited:
            if cid not in given:
                problems.append(f"cites {cid}, which was not among the passages")
        for quote in re.findall(r'"([^"]+)"', sentence):
            if cited and not any(quote.lower() in given.get(c, "").lower() for c in cited):
                problems.append(f'quotes "{quote}", which {", ".join(cited)} does not say')
    return problems
```

- **The fixed sentence passes as it is.** "The handbook does not say." is the one answer allowed to
  cite nothing, and it is recognised by comparing strings, which is why the prompt asks for it
  exactly.
- **Every other sentence must cite a passage, and only a passage that was retrieved.** A sentence
  with no id may have come from the passages or from the model's training, and nothing in the
  answer says which. A sentence citing a passage that was not in the prompt came from somewhere
  else.
- **Every quoted phrase must be in the passage it cites.** A quotation is the most checkable claim
  there is, and the one readers trust most.

The answer is cut into sentences after a full stop, a question mark, an exclamation mark or a closing
bracket, and never just before an opening one, so `abroad. [shipping.md#3]` stays one sentence with
its citation. The first version of this checker forgot the closing bracket, and a sentence after
one was silently joined to it and borrowed its citation. The broken mug below found that.

## Three answers, checked

```
ana@dev:~/shop$ python scratch/ask.py "My lamp stopped working after two months. What can I do?"
retrieved: warranty.md#1, shipping.md#1, returns.md#4
You can return the lamp to the shop, but since it's been more than 30 days, you won't be eligible for a refund. However, since the lamp stopped working within the 90-day warranty period, you can file a claim under the warranty described in [warranty.md#1].
citations: cites nothing: "You can return the lamp to the shop, but since it'"
```

**The second sentence is right and cited**: two months is within the 90-day warranty of
`warranty.md#1`. The first is flagged, and it deserves to be. Its second half comes from
`returns.md#4`, which was in the prompt and says the shop takes no returns after 30 days, and its
first half contradicts that passage: "You can return the lamp to the shop". It cites nothing, so
nothing in the answer says which half to believe. A program cannot tell that the sentence is
muddled. It can tell that the sentence has no source, and that was enough here.

```
ana@dev:~/shop$ python scratch/ask.py "Is support open on Saturday?"
retrieved: contact.md#1, account.md#2, contact.md#2
The handbook does not say.
citations: every citation checks out
```

**Passes, and wrong.** The first passage retrieved is `contact.md#1`, and it says support answers
"Monday to Friday". The answer to the question is no, it is in the prompt, and the model answered
that the handbook does not say. The fixed sentence is allowed to cite nothing, so the checker has
nothing to hold it to. A refusal is safer than an invented answer, and still a failure: the customer
who asked gets nothing they could not have got from no answer at all.

```
ana@dev:~/shop$ python scratch/ask.py "My mug arrived broken. Can I get my money back?"
retrieved: payment-errors.md#3, returns.md#3, warranty.md#1
The refund goes back to the original payment method once the item arrives at the warehouse and is checked, which takes up to five working days. [returns.md#3]

Note: The warranty information does not mention refunds for broken items, only manufacturing faults.
citations: cites nothing: "Note: The warranty information does not mention re"
```

The first sentence copies `returns.md#3` faithfully and cites it, and it does not answer the
question: it says how a refund is paid, not whether this customer gets one. The note after it cites
nothing and is flagged. The handbook's actual answer, that a breakage in transit is a damaged
delivery and not a return, is in `returns.md#1`, which the search did not bring back for the word
*broken*, and lesson 6 section 09 measures how often that happens.

**In every run made for this lesson, `llama3.2:3b` never cited a passage it had not been given and
never put a phrase in quotation marks that its passage did not contain.** The two checks for that
stay anyway. They cost one line each, a different model or a longer answer can fail them, and the
day one does they are already there.

## What to do with a flagged answer

- **Do not show it as checked.** The cheapest response is to show the answer without the sentence
  that cites nothing, or to fall back to showing the passages themselves.
- **Ask again, with the problem stated**, the loop of lesson 5 section 07: "the first sentence cites
  no passage; cite one, or leave the sentence out".
- **Count them.** The share of answers with citation problems is a number to watch, per prompt and
  per model, in the evaluation of the next section.

The check proves that a sentence cites something, that what it cites was given, and that a quotation
is in it. It does not prove that the passage says what the sentence claims, and it says nothing at
all about a refusal: the Saturday above is a passage misread, and it passed. That part still needs a
person, on a sample.
