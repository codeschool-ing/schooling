---
title: Checking the citations
version: 1
---

An answer with citations looks trustworthy, and that is a risk of its own. A citation is a claim
about where a sentence came from, and **a model can produce a citation the same way it produces any
other text**: the likely-looking id, after the likely-looking sentence. The good news is that this
claim, unlike most of what a model says, can be checked by a program.

## Two checks a program can make

```python
def check_citations(answer, found):
    """Every cited id must be one that was retrieved, and every quoted phrase must be in it."""
    given = {c["id"]: c["text"] for c, _ in found}
    problems = []
    for cid in re.findall(r"\[([\w.-]+#\d+)\]", answer):
        if cid not in given:
            problems.append(f"cites {cid}, which was not among the passages")
    for sentence in re.split(r"(?<=\.)\s+", answer):
        cited = re.findall(r"\[([\w.-]+#\d+)\]", sentence)
        for quote in re.findall(r'"([^"]+)"', sentence):
            if cited and not any(quote.lower() in given.get(c, "").lower() for c in cited):
                problems.append(f'quotes "{quote}", which {", ".join(cited)} does not say')
    return problems
```

- **Every cited id must be one that was retrieved.** If the answer cites a passage that was not in
  the prompt, the sentence came from somewhere else: the model's training, or nowhere.
- **Every quoted phrase must be in the passage it cites.** A quotation is the most checkable claim
  there is, and the one readers trust most.

## Three answers, checked

An answer whose one citation is in order:

```
ana@dev:~/shop$ python lab/ask.py "My lamp stopped working after two months. What can I do?"
retrieved: warranty.md#1, shipping.md#1, returns.md#4
Two months is within the 90-day warranty, and "a lamp that does not light" is one of the faults it covers [warranty.md#1].
citations: every citation checks out
```

An answer that cites a passage it was never given:

```
ana@dev:~/shop$ python lab/ask.py "Can I return a mug I bought 40 days ago?"
retrieved: returns.md#1, account.md#1, returns.md#2
No. A customer may return an item "within 30 days of delivery" [returns.md#1], so a mug delivered 40 days ago is past the limit. If the mug is faulty, the 90-day warranty still covers it [warranty.md#1].
citations: cites warranty.md#1, which was not among the passages
```

The first sentence is supported and checks out. The second cites `warranty.md#1`, and the retrieved
passages were two about returns and one about accounts. **The claim happens to be true**, since the
handbook does give a 90-day warranty, but it did not come from the passages, so nothing in this
request supports it. On another question the same move produces a confident warranty the shop does
not offer. The checker cannot tell those apart, and does not need to: it flags both.

An answer whose quotation is not in its source:

```
ana@dev:~/shop$ python lab/ask.py "Is the WELCOME10 coupon still valid in December?"
retrieved: coupons.md#1, shipping.md#2, coupons.md#2
Yes. WELCOME10 "takes 10% off and never expires" [coupons.md#1], so it is still valid in December.
citations: quotes "takes 10% off and never expires", which coupons.md#1 does not say
```

The handbook says WELCOME10 *has no end date*. The answer quotes *never expires*, which means the
same thing, and puts it in quotation marks with a citation, as if the handbook said it. **The answer
is right and the quotation is invented.** A reader who trusted the marks would repeat a sentence the
shop never wrote.

## What to do with a flagged answer

- **Do not show it as checked.** The cheapest response is to show the answer without the quotation
  marks or without the unsupported sentence, or to fall back to showing the passages themselves.
- **Ask again, with the problem stated**, the loop of lesson 5 section 07: "the sentence citing
  warranty.md#1 is not supported by the passages given".
- **Count them.** The share of answers with citation problems is a number to watch, per prompt and
  per model, in the evaluation of the next section.

The check proves that a quotation is in the passage and that a cited passage was given. It does not
prove that the passage says what the sentence claims; a sentence can cite the right passage and
misread it. That part still needs a person, on a sample.
