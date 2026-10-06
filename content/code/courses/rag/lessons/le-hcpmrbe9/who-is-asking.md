---
title: Who is asking
version: 1
---

Lesson 2 ended on a leak. A support agent asked when an order is held for manual fraud review, and
the pipeline, searching every document for everybody, answered with the threshold the finance team
had written down as not for agents: 0.82. Nothing in the pipeline failed. It did not know who was
asking, so it could not know what the asker was allowed to read.

Every chunk has carried its document's `audience` since lesson 5: `public`, `staff`, `finance`,
`sellers` or `developers`. What was missing is the other half, **a decision about which audiences
each reader opens**, made once and written where it can be reviewed:

```schooling-example
{
  "language": "python",
  "file": "access.py",
  "parts": [
    {
      "code": "\"\"\"Who may read what: the audiences each role opens, decided by the system and never by the question.\"\"\"\nimport psycopg\nfrom minilm import embed\nfrom pgvector.psycopg import register_vector\n\nROLES = {\n    \"customer\":  [\"public\"],\n    \"seller\":    [\"public\", \"sellers\"],\n    \"developer\": [\"public\", \"developers\"],\n    \"agent\":     [\"public\", \"staff\"],\n    \"finance\":   [\"public\", \"staff\", \"finance\"],\n}",
      "note": "Who may read what, written once. Each role opens a list of audiences, the values of the `audience` field every chunk has carried since lesson 5."
    },
    {
      "code": "def audiences(role):\n    \"\"\"The audiences a role may read. A role nobody wrote down reads nothing.\"\"\"\n    return ROLES.get(role, [])",
      "note": "A role that is not in the dictionary gets an empty list, and an empty list matches no row. A typo in a role name closes the door instead of opening it."
    }
  ]
}
```

The role comes from the session: the account that signed in, its permissions in the shop's own
system. It never comes from the request or the question. In this lab a dictionary stands in for that
system, and a program names the role it plays.

```
ana@lab:~/rag$ python roles.py "When does an order get held for manual fraud review?" customer agent finance
When does an order get held for manual fraud review?
customer  Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          I could not find that in our documents.
agent     Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          I could not find that in our documents.
finance   Refund controls and chargebacks > Automatic holds (finance, 0.644), Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516)
          An order with a score of 0.82 or more is held before dispatch and goes to manual review. [1] The payment provider gives every order a fraud score from 0 to 1. [1]
```

The same question, three readers, three sets of sources. **Only finance gets the finance document**
and the 0.82 in the reply. The agent's first source is the handbook's section on suspected fraud,
which is what an agent should be told; the customer's sources are two public sections that pass the
floor without being about fraud holds. Both replies are the refusal: extract-1 found no sentence in
what those readers may see close enough to "when does an order get held", and for the customer that
is the right answer. For the agent, a question about what to do rather than about the rule shows what
the handbook gives them:

```
ana@lab:~/rag$ python roles.py "What happens to an order that looks fraudulent?" agent finance
What happens to an order that looks fraudulent?
agent     Customer support handbook > Suspected fraud (staff, 0.678), Terms of sale > 2. Placing an order (public, 0.516)
          If an order looks wrong to you, for example a new account ordering many copies of one expensive title to an address that is not the billing address, do not accuse the customer and do not cancel the order yourself. [1]
finance   Customer support handbook > Suspected fraud (staff, 0.678), Refund controls and chargebacks > Automatic holds (finance, 0.554), Terms of sale > 2. Placing an order (public, 0.516)
          If an order looks wrong to you, for example a new account ordering many copies of one expensive title to an address that is not the billing address, do not accuse the customer and do not cancel the order yourself. [1] The payment provider gives every order a fraud score from 0 to 1. [2]
```

The agent is told not to accuse the customer and not to cancel the order, the handbook's instruction.
Finance gets the same sentence and, as source 2, the fact about fraud scores from its own document.
**Each reader got the best answer their permissions allow**, and nobody got an answer built from text
they may not read.
