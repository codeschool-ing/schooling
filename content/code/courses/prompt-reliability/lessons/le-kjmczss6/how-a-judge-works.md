---
title: How a judge works
version: 1
---

Lesson 12 ended where rules run out: whether a reply answers the question, whether it sounds like
somebody who cares. The obvious next step is to ask a model. **A judge is a prompt like any other,
and its verdict is a reply like any other**, with a format, an error rate and habits. The common
mistake is to treat it as a neutral reader standing outside the system, when it is one more part of
the system that needs measuring.

## The prompt

`prompts/judge.txt` shows a customer's message and two replies, and asks which is better:

```
ana@lab:~/triage$ cat prompts/judge.txt
You compare two replies to a customer of Folio, an online bookshop.

<message>
{{message}}
</message>

<reply_a>
{{reply_a}}
</reply_a>

<reply_b>
{{reply_b}}
</reply_b>

Which reply answers the customer better? Answer A or B and nothing else.
```

It asks for a comparison rather than a mark out of ten. A comparison has one question in it, *which
of these two*, where a mark also needs an agreed meaning for 7. It also needs pairs, and
`cases/pairs.jsonl` holds sixteen of them, written by the course, each with the verdict a person
gave:

```
ana@lab:~/triage$ head -n 1 cases/pairs.jsonl
{"id": "j01", "message": "I was charged twice for order 4471.", "a": "Thank you for contacting Folio. We take billing very seriously and our team is committed to resolving every issue our customers raise. Please be assured that your message has been passed to the relevant department, who will review your account and be in touch in due course.", "b": "Sorry about that. I can see two payments for order 4471 and I've refunded the second one; it will reach your card in 3 to 5 working days.", "human": "b"}
```

In `j01` the person chose `b`: it says what happened and what was done about it. `a` is a paragraph
of reassurance in which nothing happens.

## What the stand-in's judge does

The stand-in recognises the judge's prompt by its tags and scores each reply against a short rubric:
a point for an apology or thanks, a point for saying what will be done, a point for naming the thing
at stake, such as the order or the refund, and a penalty for exclamation marks. **Then it adds two
things the rubric never asked for**, and declares them:

```
ana@lab:~/triage$ grep -nE "^(FIRST_SEAT|PER_CHARACTER)" promptlab/standin.py
442:FIRST_SEAT = 0.6        # what being shown first is worth to a reply
443:PER_CHARACTER = 0.006   # what each character of length is worth
```

The reply shown first gets 0.6 extra, and every character of length adds 0.006, so a reply a
hundred characters longer gains the same as one shown first. Those two numbers are the course's
choice, put there so that the next two sections have something to find. Whether a real judge has
biases like them, and how large, is a question you answer the same way: by measuring it against a
person.
