---
title: What a model knows, and what it does not
version: 2
---

A language model knows what its training text taught it, and nothing else. That knowledge is
stored in its weights, which is why it is called **parametric knowledge**: it was fixed on the day
training stopped, and nothing a user does afterwards adds to it. The model does not look anything
up when it answers. It produces the text its training made most likely to follow the question.

The picture most people arrive with is different. They imagine the model consulting something, the
way a search engine consults an index, and they expect it to notice when the thing it consulted had
no answer. Neither happens. There is nothing to consult and nothing to notice: a question about a
subject the model never saw gets an answer shaped exactly like an answer about a subject it did.

## Three ways a fact is missing

A company's documents are missing from a model for three different reasons, and the third is the
dangerous one.

- **Private.** Marginalia's support handbook was never published, so no training run ever read it.
  The model has no idea what an agent may refund without approval.
- **New.** Anything written after the training cutoff is absent, however public it is. A policy
  published last month does not exist for a model trained last year.
- **Changed.** A fact that was true when the training text was written and is false now. The model
  learnt it, learnt it well, and repeats it with complete confidence.

The first two at least produce an answer with nothing behind it. The third produces an answer with
something behind it that used to be right, which is much harder to catch.

## Asking without a source

`ask.py` sends one question to llama3.2:3b, alone, and prints the reply:

```schooling-example
{
  "language": "python",
  "file": "ask.py",
  "parts": [
    {
      "code": "import sys\nfrom openai import OpenAI\n\nclient = OpenAI()",
      "note": "The client finds Ollama through `OPENAI_BASE_URL`, which `env.sh` sets."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[{\"role\": \"user\", \"content\": sys.argv[1]}],\n)\nprint(reply.choices[0].message.content)",
      "note": "The question from the command line, alone: no system message, no document. `temperature=0` makes the same question get the same reply on the same machine."
    }
  ]
}
```

```
ana@vm:~/rag$ python ask.py "How many days do I have to return a printed book?"
The number of days you have to return a printed book depends on the library's return policy, which can vary depending on the library and the type of book.

Typically, most public libraries have a return policy that allows you to return books within a certain timeframe, usually 1-3 weeks, without any fines. However, if you keep a book for longer than the allowed time, you may be charged a fine.

Here are some general guidelines:

* Most public libraries: 1-2 weeks (7-14 days) without fines
* Some libraries: 2-3 weeks (14-21 days) without fines
* Interlibrary loan books: 1-2 weeks (7-14 days) without fines

It's always best to check with your local library's return policy to confirm their specific rules and deadlines.
ana@vm:~/rag$ python ask.py "What is the phone number for customer service?"
I don't have have access to real-time information, but I can suggest some options to help you find the customer service phone number for a specific company:

1. Check the company's website: Most companies list their customer service phone number on their official website.
2. Search online: You can search for the company's name along with "customer service phone number" to find the information.
3. Check the packaging or documentation: If you have the product or documentation, you can check the packaging or instructions for the customer service phone number.
4. Contact the company directly: You can try contacting the company directly through their website's contact form or by sending an email.

If you provide me with the name of the company, I can try to help you find the customer service phone number.
ana@vm:~/rag$ python ask.py "Can I get my money back for an e-book I downloaded yesterday?"
I can't provide information about a specific e-book or purchase. If you're unhappy with an e-book you've downloaded, I can offer general guidance on returning or refunding an e-book purchase. Would that help?
```

**None of the three replies is about Marginalia, and only one of them says so.** The first is the
dangerous one. A model that has never heard of the shop met a question about returning a printed
book and answered the question it knew, about returning a book to a library: one to three weeks,
fines, interlibrary loans. It is fluent, specific and confident, and it is about a different
business altogether. A customer skimming it for a number finds one, "7-14 days", and the number is
wrong for this shop, whose policy gives thirty.

The other two do what a careful model does with a question it cannot answer. The phone question gets
an admission that it has no access to the information and advice on finding it, and the e-book
question gets an offer of general guidance. That is the behaviour training pushes models towards,
and llama3.2:3b shows it twice out of three. **The trouble is the third time: nothing in the text of
the first reply tells it apart from a right one.**

A bigger model knows more and hedges more, which makes the failure rarer and harder to spot. The
shape stays the same, and it is the one that matters for a company's own documents: **a fluent
answer, no source, and no signal in the text that tells a right one from a wrong one.**

## Why the model cannot just say it does not know

It refused twice above, and it would be convenient if it refused every time it lacked the fact.
Training does push models towards admitting ignorance, and modern models do it more than older ones.
But a model has no record of what it read, so it cannot check whether a fact was in its training
text; all it has is how likely each next word is. After a question about returning a printed book,
a library's loan rules are very likely text. **The model's confidence
measures how plausible the answer sounds, not whether it is true.**

That is the problem this course solves. Not by making the model know more, which only moves the
cutoff, but by giving it the right text at the moment it answers and making it say where the answer
came from.
