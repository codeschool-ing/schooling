---
title: Who is asking
version: 2
---

Lesson 2 ended on a leak. A support agent asked when an order is held for manual fraud review, and
the pipeline, searching every document for everybody, answered with the threshold the finance team
had written down as not for agents: 0.82. Nothing in the pipeline failed. It did not know who was
asking, so it could not know what the asker was allowed to read.

Every chunk has carried its document's `audience` since lesson 5: `public`, `staff`, `finance`,
`sellers` or `developers`. What was missing is the other half, **a decision about which audiences
each reader opens**, made once and written where it can be reviewed. It is the first part of
`access.py`, whose other functions the next sections take apart; save the whole module now, because
every program in this lesson imports it:

```schooling-example
{
  "language": "python",
  "file": "access.py",
  "parts": [
    {
      "code": "\"\"\"Who may read what: the audiences each role opens, decided by the system and never by the question.\"\"\"\nimport psycopg\nfrom vectors import embed\nfrom pgvector.psycopg import register_vector\n\nROLES = {\n    \"customer\":  [\"public\"],\n    \"seller\":    [\"public\", \"sellers\"],\n    \"developer\": [\"public\", \"developers\"],\n    \"agent\":     [\"public\", \"staff\"],\n    \"finance\":   [\"public\", \"staff\", \"finance\"],\n}",
      "note": "Who may read what, written once. Each role opens a list of audiences, the values of the `audience` field every chunk has carried since lesson 5."
    },
    {
      "code": "def audiences(role):\n    \"\"\"The audiences a role may read. A role nobody wrote down reads nothing.\"\"\"\n    return ROLES.get(role, [])",
      "note": "A role that is not in the dictionary gets an empty list, and an empty list matches no row. A typo in a role name closes the door instead of opening it."
    },
    {
      "code": "def connect():\n    \"\"\"The assistant's own connection: a role that can only SELECT, and only what the policy lets through.\"\"\"\n    conn = psycopg.connect(host=\"localhost\", user=\"assistant\", password=\"reads-only\", autocommit=True)\n    register_vector(conn)\n    return conn",
      "note": "The assistant connects as its own database role, `assistant`, which can read the table and nothing else."
    },
    {
      "code": "def search(conn, role, question, k=3, only=None):\n    \"\"\"Lesson 6's search with the role's audiences in the WHERE, inside a transaction that also tells\n    the database whose search it is, so its policy applies the same limit a second time. ONLY, a\n    narrowing the reader asked for, is intersected with what the role allows and can never add to it.\"\"\"\n    allowed = [a for a in audiences(role) if only is None or a in only]\n    q = embed(question)[0]\n    with conn.transaction():\n        conn.execute(\"SELECT set_config('rag.audiences', %s, true)\", (\",\".join(allowed),))\n        return conn.execute(\n            \"SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks\"\n            \" WHERE status = 'current' AND audience = ANY(%s)\"\n            \" ORDER BY embedding <=> %s LIMIT %s\", (q, allowed, q, k)).fetchall()",
      "note": "The role's audiences go into the `WHERE`, so the search ranks only what the reader may see. The same list is set for the transaction as `rag.audiences`, which the database's policy reads in the next section; `true` makes the setting end with the transaction, so it cannot leak into the next request on the same connection."
    }
  ]
}
```

The role comes from the session: the account that signed in, its permissions in the shop's own
system. It never comes from the request or the question. In this course a dictionary stands in for that
system, and a program names the role it plays.

```schooling-example
{
  "language": "python",
  "file": "roles.py",
  "parts": [
    {
      "code": "import sys\n\nimport access\nfrom answer import FLOOR, REFUSAL, ask\nfrom search import conn as loader\n\nquestion = sys.argv[1]\nprint(question)\nfor role in sys.argv[2:]:\n    found = [r for r in access.search(loader, role, question) if r[4] >= FLOOR]\n    updated = dict(loader.execute(\"SELECT id, updated FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],)))\n    sources = [{\"path\": p, \"text\": t, \"updated\": updated[i]} for i, p, t, _, _ in found]\n    print(f\"{role:9} {', '.join(f'{r[1]} ({r[3]}, {r[4]:.3f})' for r in found) or 'nothing above the floor'}\")\n    print(f\"{'':9} {ask(question, sources) if sources else REFUSAL}\")",
      "note": "One question asked in the name of each role on the command line, through the filtered search: what each role's search found, and the reply it got."
    }
  ]
}
```

```
ana@vm:~/rag$ python roles.py "When does an order get held for manual fraud review?" customer agent finance
When does an order get held for manual fraud review?
customer  Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          I could not find that in our documents.
agent     Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          According to [1], an order is held for manual fraud review when it looks suspicious, such as a new account ordering many copies of one expensive title to an address that is not the billing address.
finance   Refund controls and chargebacks > Automatic holds (finance, 0.644), Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516)
          According to [1], an order with a fraud score of 0.82 or more is held before dispatch and goes to manual review.
```

The same question, three readers, three sets of sources. **Only finance gets the finance document**
and the 0.82 in the reply. The agent's first source is the handbook's section on suspected fraud,
and the reply is what the handbook tells an agent: an order that looks suspicious, such as a new
account ordering many copies of one expensive title, is held for review. No number, because the
agent's sources have none. The customer's sources are two public sections that pass the floor
without being about fraud holds, and the model refused, which for the customer is the right answer.
A question about what to do rather than about the rule shows what the handbook gives an agent:

```
ana@vm:~/rag$ python roles.py "What happens to an order that looks fraudulent?" agent finance
What happens to an order that looks fraudulent?
agent     Customer support handbook > Suspected fraud (staff, 0.678), Terms of sale > 2. Placing an order (public, 0.516)
          According to the customer support handbook [1], if an order looks suspicious, you should open a finance review with the reason "fraud" and continue to answer the customer normally, allowing the finance team to decide on the course of action. 

Additionally, according to the terms of sale [2], if an order is suspected to be fraudulent, the company may refuse to dispatch the order, and if they do, they will refund any amount already taken within three working days.
finance   Customer support handbook > Suspected fraud (staff, 0.678), Refund controls and chargebacks > Automatic holds (finance, 0.554), Terms of sale > 2. Placing an order (public, 0.516)
          According to [1], if an order looks suspicious, you should open a finance review with the reason "fraud" and continue to answer the customer normally. Finance will then decide on the order and inform you what to say.

However, it's also worth noting that the payment provider gives every order a fraud score, and if the score is 0.82 or more, the order is held before dispatch and goes to manual review [2]. This suggests that the order is indeed flagged for potential fraud, but it's up to finance to make the final decision.

It's also worth noting that the terms of sale state that you may refuse an order before dispatch if it's out of stock, has an obvious error in price, or the payment is not confirmed [3]. However, this doesn't necessarily mean that the order is fraudulent, but rather that it's not valid for dispatch.

In any case, the most up-to-date information on handling suspicious orders comes from [1], which advises to open a finance review with the reason "fraud" and let finance decide.
```

The agent is told what the handbook tells agents: open a finance review with the reason *fraud*, and
keep answering the customer normally. Finance gets the same instruction and, as source 2, the fact
about fraud scores from its own document; both replies also drew on the terms of sale, which anybody
may read. **Each reader got the best answer their permissions allow**, and nobody got an answer
built from text they may not read.