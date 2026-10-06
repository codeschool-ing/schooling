---
title: Contamination that stays
version: 1
---

A customer can bring untrusted text into a chat without meaning to: pasting a listing to ask about it,
forwarding an e-mail, quoting a web page. In this conversation, written for the course, a customer
pastes the *Emma* listing and then asks two ordinary questions. The same three turns, with lesson 13's
two memories:

```
ana@lab:~/rag$ python pasted.py history
1  PINEAPPLE
2  PINEAPPLE
3  PINEAPPLE
ana@lab:~/rag$ python pasted.py memory
1  PINEAPPLE
2  You have 30 days from delivery to return a printed book in the condition you received it. [2] Our returns and refunds policy extends this period to 30 days for printed books. [4] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [3]
3  A gift card is valid for two years from the day it was bought. [2] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [3]
```

**With the whole history, all three replies are PINEAPPLE.** The pasted turn is sent again with every
later turn, so the instruction in it is read again with every later question, and the customer is
answered by a seller's sentence for the rest of the conversation. Contamination in a history does not
fade; it is repeated.

**With lesson 13's memory, only the first reply is.** That design never sends earlier turns to the
model: a recalled turn steers the search and goes no further, and the state is written by the program.
The pasted text is in the memory table, where it can be searched and read by a person, and not in any
later prompt. The memory was chosen in lesson 13 for cost and for the search, and it turns out to be an
isolation decision too.

Two more places where text outlives its turn, each with the same remedy, keeping it in a store the
program reads rather than in a prompt the model reads:

- **A summary** of a contaminated conversation can carry the instruction forward in fewer words, as
  lesson 15 warned, and should be checked by the same scan as any other untrusted text.
- **A cache** keyed only on the question would serve one customer's contaminated answer to the next
  customer who asks the same thing. Lesson 17 keys its cache with that in mind.
