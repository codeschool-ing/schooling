---
title: The filter goes inside the search
version: 2
---

`access.search` puts the role's audiences in the query's `WHERE`, so PostgreSQL ranks only the rows
the reader may see:

```schooling-example
{
  "language": "python",
  "parts": [
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

The tempting alternative is to search as before and remove what the reader may not see afterwards. It
is easy to add to a pipeline that already works, and it is wrong in two ways at once:

```schooling-example
{
  "language": "python",
  "file": "after.py",
  "parts": [
    {
      "code": "import sys\n\nimport access\nfrom vectors import embed\nfrom search import conn\n\nrole, question = sys.argv[1], sys.argv[2]\nq = embed(question)[0]\ntop = conn.execute(\"SELECT path, audience, 1 - (embedding <=> %s) FROM chunks WHERE status = 'current'\"\n                   \" ORDER BY embedding <=> %s LIMIT 3\", (q, q)).fetchall()\nprint(\"the three nearest, for anybody:\")\nfor path, audience, score in top:\n    print(f\"  {score:.3f}  {audience:8} {path}\")\nkept = [row for row in top if row[1] in access.audiences(role)]\nprint(f\"then dropped for {role}: {len(kept)} of 3 left\")",
      "note": "The three nearest chunks for anybody, and what is left of them once the ones a role may not read are dropped afterwards."
    }
  ]
}
```

```
ana@vm:~/rag$ python after.py agent "When does an order get held for manual fraud review?"
the three nearest, for anybody:
  0.644  finance  Refund controls and chargebacks > Automatic holds
  0.586  staff    Customer support handbook > Suspected fraud
  0.516  public   Returns and refunds policy > Damaged, faulty and wrong items
then dropped for agent: 2 of 3 left
```

**Two of three left.** The finance chunk was the best match, so it took a place in the top three
and was then thrown away, and the agent gets two sources where the filter inside the query gave three.
On a question that matches finance's documents strongly, every one of the top three can be thrown
away, and the agent gets nothing, while the same agent with the filter in the `WHERE` would have
three handbook sections. Fetching more to make up for it is guessing how many will be dropped.

The second way is worse. **Between the search and the drop, the forbidden text is in the program's
memory**, and every line of code in between can leak it: a log line that prints the sources, a cache
keyed on the question, a trace sent to an observability service, an exception message that includes
the row. The filter inside the query means the text the reader may not see is never read out of the
database for them at all.

Lesson 6 made the same argument for the `status` filter, on grounds of quality: a superseded chunk
dropped after the search costs a place. With permissions, the argument is about who has seen what.
