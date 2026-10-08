---
title: What a customer must not learn
version: 2
---

The finance document's warning was about agents, but the strongest case for permissions is a
customer. A refund rule that exists to catch abuse stops working the moment the people it is meant to
catch can read it:

```
ana@vm:~/rag$ python roles.py "How many refunds can I get before my account is flagged?" customer finance
How many refunds can I get before my account is flagged?
customer  nothing above the floor
          I could not find that in our documents.
finance   Refund controls and chargebacks > Automatic holds (finance, 0.669)
          According to [1], a customer can receive up to three refunds in 90 days before their account is flagged.
```

The finance team gets the rule word for word, which is what the document is for: **more than three
refunds in 90 days** flags an account. The customer gets the refusal, because no public document
answers the question and the finance document is not among what a customer's search can reach. A
customer who learned the number would know to ask for three refunds every quarter, and nothing in a
prompt could have prevented it once the text was in front of the model.

A refusal is the right answer here and it is worth saying why. "I could not find that in our
documents" is true from where the customer stands: nothing they may read answers it. It reveals
neither that the rule exists nor where it lives. A reply like "that information is restricted" would
tell the customer there is something to find, and on a question about getting around a fraud control,
that is itself a leak.

## The same question, asked indirectly

Permissions decide what is retrieved, so they hold however the question is phrased. A customer who
asks "what happens if I return a lot of books?" or "is there a limit on refunds?" reaches the same
public documents and nothing else, because the boundary is on the chunks and not on the words. This
is the difference from lesson 2's tempting fix, an instruction in the prompt not to reveal thresholds:
an instruction is checked against the question's wording by the model, and a permission is checked
against the reader by the database.
