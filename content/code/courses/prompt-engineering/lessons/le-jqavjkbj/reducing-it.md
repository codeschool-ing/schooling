---
title: What reduces it, and what does not
version: 2
---

The first instinct is to add a line to the prompt: "Do not make things up." It costs nothing and
helps very little, because a model does not know which of its likely answers are made up; if it
did, it would not write them. **What works is closing the gap between likely and true from the
outside**: put the true text where the model can see it, make an honest refusal a likely reply,
and check what comes back against something the model did not write.

## Ground the answer in sources you supply

A model asked about the café's refund rules from memory has nothing to go on but what refund rules
usually say. Give it the rules, and the likeliest continuation becomes one that repeats them.
`retrieve` finds the handbook lines that match a question, and with `--prompt` it puts them above
the question, numbered, with an instruction. Save it as `~/pe/bin/retrieve` and make it executable:

```python
#!/usr/bin/env python3
"""retrieve QUESTION [--k N] [--prompt]: find the handbook passages for a question.

Each line of each file in handbook/ is a passage. Passages are scored with
BM25, the ranking formula most keyword search engines start from: a word
counts for more when it is rare across the handbook, and for less each extra
time it repeats in one passage. With --prompt, the top passages are put into
the prompt a model would receive, each with a number to cite.
"""
import math
import os
import re
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
BOOK = os.path.join(HERE, "..", "handbook")
STOP = set("a an and are at be by can do does for from i if in is it its my not of on or "
           "the to was what when which who will with you".split())
words = lambda t: [w for w in re.findall(r"[a-z0-9]+", t.lower()) if w not in STOP]

args = sys.argv[1:]
k = 3
if "--k" in args:
    i = args.index("--k"); k = int(args[i + 1]); del args[i : i + 2]
prompt = "--prompt" in args
question = " ".join(a for a in args if a != "--prompt")

passages = []
for name in sorted(os.listdir(BOOK)):
    for line in open(os.path.join(BOOK, name), encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            passages.append((name, line))
docs = [Counter(words(t)) for _, t in passages]
avg = sum(sum(d.values()) for d in docs) / len(docs)
df = Counter(w for d in docs for w in d)
N = len(docs)

def bm25(q, d, k1=1.2, b=0.75):
    size = sum(d.values())
    s = 0.0
    for w in q:
        if w in d:
            idf = math.log(1 + (N - df[w] + 0.5) / (df[w] + 0.5))
            s += idf * d[w] * (k1 + 1) / (d[w] + k1 * (1 - b + b * size / avg))
    return s

q = words(question)
ranked = sorted(((bm25(q, d), i) for i, d in enumerate(docs)), key=lambda x: (-x[0], x[1]))
top = [(s, i) for s, i in ranked[:k] if s > 0]
if not prompt:
    print("query words: %s" % " ".join(q))
    for s, i in top:
        print("%6.2f  %-14s %s" % (s, passages[i][0], passages[i][1]))
    if not top:
        print("no passage shares a word with the question")
    sys.exit(0)
print("Answer the question using only the sources below. Cite each source you use")
print("as [1], [2]. If the sources do not contain the answer, say that the handbook")
print("does not say, and do not answer from general knowledge.")
print()
for n, (s, i) in enumerate(top, 1):
    print("[%d] (%s) %s" % (n, passages[i][0], passages[i][1]))
print()
print("Question: %s" % question)
```

How it scores the lines is lesson 11's subject. What it builds is this:

```
ana@lab:~/pe$ retrieve "Can I get a refund in cash if I paid by card?" --prompt
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.

[1] (refunds.md) Refunds are made to the card or method used to pay, never in cash for a card payment.
[2] (refunds.md) A refund above R$ 100 needs the shift manager's approval.
[3] (loyalty.md) Stamps cannot be exchanged for cash or for food.

Question: Can I get a refund in cash if I paid by card?
```

Three things in that prompt do the work. **The sources are in the text**, so the facts are now the
likely continuation rather than a guess about cafés in general. They are **numbered**, so the
reply can say which one it used. And the first line limits the answer to them. Send it to the model by piping it into `ask`, which
reads its prompt from standard input when it is given `-`:

```
ana@lab:~/pe$ retrieve "Can I get a refund in cash if I paid by card?" --prompt | ask - --temperature 0
According to the handbook, refunds are made to the card or method used to pay, never in cash for a card payment. [1]

Therefore, the answer is no, you cannot get a refund in cash if you paid by card.
-- llama3.2:3b, finish: stop, prompt 159 tokens, output 49 tokens
```

The `[1]` is what makes the reply checkable: a reader, or a program, can go to source 1 and see
whether it says that.

::: track ai
Lesson 11 is about this technique, retrieval-augmented generation, and the `rag` course in your
track builds the retrieval properly.
:::

::: track *
Lesson 11 is about this technique, retrieval-augmented generation: finding the right passages and
putting them in the prompt.
:::

## Make "I don't know" a likely reply

Grounding has a trap of its own. Retrieval always returns the best matches it has, and the best
match can be irrelevant. Ask the handbook who owns the café:

```
ana@lab:~/pe$ retrieve "Who owns the café?" --prompt
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.

[1] (hours.md) On public holidays the café follows the Sunday hours.
[2] (hours.md) Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.

Question: Who owns the café?
```

**Neither source says anything about an owner.** They matched because they mention the café. A
prompt that only said "use these sources" would leave the model with two lines about opening hours
and a question it cannot answer from them, and the likeliest continuation of a question is an
answer. That is why the instruction has its second sentence: if the sources do not contain the
answer, say that the handbook does not say. **An explicit way out turns the honest reply into a
likely one.** It did here:

```
ana@lab:~/pe$ retrieve "Who owns the café?" --prompt | ask - --temperature 0
The handbook does not say who owns the café.
-- llama3.2:3b, finish: stop, prompt 125 tokens, output 11 tokens
```

A short reply like that is a success, and it needs to be treated as one wherever replies are
measured. A test that only counts answered questions rewards exactly the behaviour this section is
trying to remove.

## Ask for quotes, and check them

A citation such as `[1]` points at a source. A **quote** goes further: it is the exact sentence
the claim rests on, and an exact sentence can be checked by a program, without reading or judging
anything. Here is that check done with `grep`, once for a quote that a reply might give for the
refund rule and once for one that a reply might invent:

```
ana@lab:~/pe$ grep -rF "never in cash for a card payment" handbook/
handbook/refunds.md:Refunds are made to the card or method used to pay, never in cash for a card payment.
ana@lab:~/pe$ grep -rF "cash refunds are available on request" handbook/ || echo "not in the handbook"
not in the handbook
```

The first is in `refunds.md`, word for word. The second appears nowhere, so whatever the reply
built on it has no source, however reasonable it sounds. **A quote that is not in the source is a
hallucination you caught automatically.** Asking for quotes costs some tokens in the reply, and
makes the cheapest check there is possible.

## Check the claims that matter

Not every reply can be checked by a program. The rest still need checking whenever a wrong answer
would cost something:

- look up the references: a citation, a link, a law, a function in a library each either exists
  or does not, and finding out takes a minute;
- ask a second question that should agree with the first: lesson 27 asks the same question several
  times and compares the answers, and disagreement is a sign the model is guessing;
- keep a person in the loop where an error would reach a customer, a patient or a court, so that
  the model drafts and somebody accountable signs.

## Turning the temperature down does not fix it

Temperature (lesson 13) controls how adventurous the draw is. At 0 the model always takes the
highest score, and that sounds like the safe setting:

```
ana@lab:~/pe$ toylm generate "the soup of the day is" --temperature 0 --samples 3
[seed 1] tomato.
[seed 2] tomato.
[seed 3] tomato.
```

Three identical answers, and **consistent is not the same as correct**. `tomato` has the highest
score because the file mentions it most often, and today's soup may still be the lentil. A low
temperature makes a model repeat its likeliest answer every time, including when the likeliest
answer is the invented one. It is the right setting for some jobs, and it is not a control for
truth.

All of the working remedies share one idea: **the model's output is evidence, not a fact**. Give
it the material to be right, give it a way to say it cannot be, and check what it returns against
something it did not write.
