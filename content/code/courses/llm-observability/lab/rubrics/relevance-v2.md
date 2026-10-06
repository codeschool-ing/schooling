# Relevance, version 2

Read the customer's question and the assistant's reply. Relevance asks only
whether the reply is about what was asked. Whether it is true is faithfulness,
and whether it is the right answer is correctness: grade neither here.

- pass: the reply gives what the question asks for, even among other
  sentences.
  e.g. "Above what order value is standard delivery free?" answered with a
  sentence on express delivery and then "standard ... free on orders over 40".
- pass: the reply is the agreed refusal, "I could not find that in our
  documents." It answers the question by saying there is no answer here.
  Whether it should have refused is correctness.
- fail: the reply is about the question's subject and does not give what was
  asked for.
  e.g. "How much is express delivery?" answered with "Express delivery is not
  free at any order value."
- fail: the reply answers a different question, even one that shares the
  question's words.
  e.g. "Above what order value is standard delivery free?" answered with
  "Express delivery is not free at any order value."

When the reply gives a condition from which the answer follows, and the customer
would have to work it out, write that down beside the label: it is the case this
version does not settle.
