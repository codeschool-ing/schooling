---
title: The window is a budget
version: 1
---

Every lesson so far has been about finding the right text. This one and the four after it are about
a different question: **of everything that could go in front of the model, what should?** That is
what has come to be called context engineering. The context window is everything the model reads in
one call: the instructions, the sources, any earlier turns of the conversation, the question, and the
room left for the reply. It has a hard limit, and well before the limit it has a price.

Here is one real prompt, the one lesson 7's pipeline sends for a gift card question, counted part by
part:

```
ana@lab:~/rag$ python window.py "How long is a gift card valid?"
   71  instructions
   19  header [1]
   39  text   [1] Gift card terms > Validity
   22  header [2]
   69  text   [2] Payments, invoices and gift cards > Gift cards
   22  header [3]
   59  text   [3] Payments, invoices and gift cards > Gift cards
   10  question
  311  sent, of a window of 8192
```

**311 tokens, of a window of 8,192.** It looks like a problem that does not exist yet, and three
things make it one anyway.

- **Every token is paid for**, on every query, and lesson 17 multiplies that by a week of traffic.
  A prompt twice the size is twice the bill for the input.
- **Every token is read before the first word comes back.** Lesson 9's streaming hid the time to
  write the reply; nothing hides the time to read the prompt, and it grows with its length.
- **Every token competes for the model's attention.** That is the one this lab cannot measure, since
  extract-1 is not a model, and the section after next quotes the research that has.

And the 311 is the smallest it will ever be. Lesson 13 adds the conversation so far, a support
assistant may add the customer's account details, an agent in `agents-mcp` adds the descriptions of
its tools, and each of them arrives with a reason to be there. **A window is never filled by one
decision; it is filled by many reasonable ones**, and the sum is nobody's choice unless somebody
makes it one.

The anatomy above is also the agenda of this lesson. The instructions, 71 tokens, are fixed. The
question is the customer's. Everything else is a decision: how many sources (the next two sections),
which ones (duplicates), how much of each (compression), in what order (placement), and with what
around them (headers). The last section puts the decisions into one function, `pack`, and measures it
against lesson 7's prompt.
