---
title: Saying the sources do not say
version: 2
---

The third line of the system message tells the model what to reply when the sources do not answer.
It is the most important instruction in the prompt, because the alternative is the closed-book answer
of lesson 1: fluent, confident and invented. And it is the one this lesson trusts least.

## The instruction, with nothing to apply it to

`no_floor.py` sends what `ask` would send if the code called the model whatever the search found: the
system message, the question, and no sources, because nothing scored above the floor.

```schooling-example
{
  "language": "python",
  "file": "no_floor.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import ask\n\n# What the model is sent when the search found nothing above the floor and the\n# code calls it anyway: the instructions and the question, and no sources.\nprint(ask(sys.argv[1], []))",
      "note": "`ask` with an empty list of sources: the system message and the question, and nothing to answer from."
    }
  ]
}
```

```
ana@vm:~/rag$ python no_floor.py "Can I place an order by phone?"
I could not find that in our documents.
```

**With nothing to answer from, the model obeyed**, word for word. That is the instruction working
once, on one question, on one machine, and it is worth exactly that much. Lesson 1 asked the same
model about returning a book with no sources and no instruction, and got library loan rules,
fluent and confident and about another business. An instruction is followed most of the time. *Most of the time*
is the honest description of every instruction a model is given, and a phone number for a phone line
that does not exist is the kind of answer that ends up in a screenshot.

So `answer` does not ask:

```
ana@vm:~/rag$ python answer.py "Can I place an order by phone?"
I could not find that in our documents.
ana@vm:~/rag$ python answer.py "Is there a student discount?"
I could not find that in our documents.
ana@vm:~/rag$ python answer.py "Can I pay in instalments?"
I could not find that in our documents.
```

**When nothing clears the floor, the code returns the refusal and the model is never called.** The
first two are right: no document mentions ordering by phone or a student discount. The third is the
price lesson 6 named in advance: the answer is in the payments document, but its chunk scored 0.445,
below the floor of 0.5, so a customer asking about instalments is told the documents do not say. The
floor and its errors were chosen together, and the floor is the cheaper place to put the decision,
because it is a number in code, not a sentence a model may or may not obey.

## How well a floor can do on this test set

Lesson 6 chose 0.5 by looking at what the search returned. This list asks the same question from the
other side. It embeds every sentence of every document and prints the best similarity each test
question finds anywhere:

```schooling-example
{
  "language": "python",
  "file": "floor.py",
  "parts": [
    {
      "code": "import glob\nimport json\n\nfrom chunking import sentences\nfrom vectors import embed\n\npool = [s for path in sorted(glob.glob(\"data/docs/*.md\")) for s in sentences(open(path).read())]\nvectors = embed(pool)\nfor line in open(\"data/eval.jsonl\"):\n    q = json.loads(line)\n    best = float((vectors @ embed(q[\"question\"])[0]).max())\n    print(f\"{best:.2f}  {'answerable  ' if q['facts'] else 'unanswerable'}  {q['question']}\")",
      "note": "Every sentence of every document, cut by lesson 4's `sentences`, and for each test question the best similarity it finds among them."
    }
  ]
}
```

```
ana@vm:~/rag$ python floor.py | sort -r | sed -n "22,30p"
0.56  answerable    How often are sellers paid?
0.55  answerable    What must I check before changing a customer's order?
0.55  answerable    What does error E-4102 mean in the affiliate API?
0.52  unanswerable  Can I place an order by phone?
0.52  answerable    When is the contract of sale formed?
0.49  unanswerable  Which carrier do you use in Portugal?
0.47  answerable    Can I pay in instalments?
0.44  unanswerable  Do you have a shop in Porto Alegre where I can pick up books?
0.36  unanswerable  Is there a student discount?
```

The middle of the list is printed, where the two kinds meet, and **they overlap**. *Can I place an
order by phone?*, which no document answers, finds a sentence at 0.52, as close as *When is the
contract of sale formed?*, which the terms of sale answer, and closer than *Can I pay in
instalments?* at 0.47. No number separates the two kinds: every floor refuses some answerable
questions or lets some unanswerable ones through, and moving it only chooses which. A floor fitted to
these thirty questions would also look better on them than on the questions that arrive next, which
is why lesson 8 keeps part of the test set aside.

## Refusing well

A refusal is an answer, and it can be a good or a bad one. **Say what is not covered**, so a customer
who asked two things knows which one failed. **Offer a next step**, the contact form, a person, the
help centre's search, because a customer who is refused has still not had the question answered.
**And log it**: refusals are the cheapest list a team will ever get of documents it has not written.
