---
title: Tenants and permissions
version: 1
---

Every filter so far has been about relevance: a wrong language gives a worse answer. One kind of
filter is about something else. When one system holds the data of several customers, its
**tenants**, the tenant filter is what keeps one customer's documents out of another's results. A
missing language filter is a bad search. **A missing tenant filter is a data leak**, and it looks
exactly like a working search, because the results are relevant. They are just somebody else's.

## The filter must not come from the request

The tempting design is the one the previous sections used: the search function takes a filter, and
whoever calls it passes `shop = 'folio'`. That puts the boundary in every caller. One endpoint that
forgets it, one client that sends `shop = 'marginalia'` instead, and the boundary is gone. Two rules
follow:

- the tenant comes from the session, never from the request body. The server knows who signed
  in; a filter value sent by the client is a claim, and a client can claim anything;
- the place that enforces it should be one place, below every query, so that a query written
  without it fails rather than leaks.

PostgreSQL has that place built in: **row-level security**. A policy on a table is a condition that
PostgreSQL adds to every query on it, for every role the policy applies to. Here a second shop,
Folio, shares the `articles` table with Marginalia:

```schooling-example
{
  "language": "python",
  "file": "shops.py",
  "parts": [
    {
      "code": "import psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\nfrom store import help, D\n\nfolio = [(\"f01\", \"Returning a book to Folio\", \"Post it back within 30 days with the slip from the parcel.\"),\n         (\"f02\", \"Folio delivery times\", \"Orders leave our shop in two working days.\"),\n         (\"f03\", \"Your Folio account\", \"Change your password from the account page.\")]\nF = embed([title + \". \" + body for _, title, body in folio])",
      "note": "A second shop, Folio, with three articles of its own, embedded with the same model."
    },
    {
      "code": "with psycopg.connect(autocommit=True) as conn:\n    conn.execute(\"CREATE EXTENSION IF NOT EXISTS vector\")\n    register_vector(conn)\n    conn.execute(\"\"\"CREATE TABLE articles (id text PRIMARY KEY, shop text NOT NULL,\n                    title text, embedding vector(384))\"\"\")\n    for h, v in zip(help, D):\n        conn.execute(\"INSERT INTO articles VALUES (%s, 'marginalia', %s, %s)\", (h[\"id\"], h[\"title\"], v))\n    for (id, title, _), v in zip(folio, F):\n        conn.execute(\"INSERT INTO articles VALUES (%s, 'folio', %s, %s)\", (id, title, v))",
      "note": "One table for both shops, with a `shop` column that every row has to fill."
    }
  ]
}
```

```sql
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
CREATE POLICY one_shop ON articles USING (shop = current_setting('app.shop'));
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'helpdesk') THEN
    CREATE ROLE helpdesk;
  END IF;
END $$;
GRANT SELECT ON articles TO helpdesk;
```

The policy compares each row's shop with the setting `app.shop`, which the application sets once
per connection from the signed-in session. The search itself has no `WHERE` at all:

```schooling-example
{
  "language": "python",
  "file": "tenant_search.py",
  "parts": [
    {
      "code": "import sys\nimport psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\n\nshop = sys.argv[1] if len(sys.argv) > 1 else None\nwith psycopg.connect() as conn:\n    register_vector(conn)\n    conn.execute(\"SET ROLE helpdesk\")\n    if shop:\n        conn.execute(\"SELECT set_config('app.shop', %s, false)\", (shop,))",
      "note": "Connect, become the `helpdesk` role and, if a shop was named, record it in the setting `app.shop` for this connection."
    },
    {
      "code": "    rows = conn.execute(\"\"\"SELECT id, title FROM articles\n                           ORDER BY embedding <=> %s LIMIT 3\"\"\",\n                        (embed(\"how do I return a book\")[0],)).fetchall()\n    for id, title in rows:\n        print(id, title)",
      "note": "The search has no `WHERE`. Which rows it may see is the policy's business."
    }
  ]
}
```

```
ana@lab:~/emb$ python shops.py
ana@lab:~/emb$ psql -f policy.sql
ALTER TABLE
CREATE POLICY
DO
GRANT
ana@lab:~/emb$ python tenant_search.py marginalia
h14 How to return a book
h33 Refunds for e-books
h17 Items that cannot be returned
ana@lab:~/emb$ python tenant_search.py folio
f01 Returning a book to Folio
f03 Your Folio account
f02 Folio delivery times
ana@lab:~/emb$ python tenant_search.py
Traceback (most recent call last):
  File "/home/ana/emb/tenant_search.py", line 12, in <module>
    rows = conn.execute("""SELECT id, title FROM articles
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/emb/lib/python3.11/site-packages/psycopg/connection.py", line 304, in execute
    raise ex.with_traceback(None)
psycopg.errors.UndefinedObject: unrecognized configuration parameter "app.shop"
```

**The same query, with no filter in it, returned only Marginalia's articles for Marginalia and only
Folio's for Folio.** The Folio search returned all three Folio articles, including two that have
nothing to do with returns, because those are all it can see. And with no shop set, the query
**failed** with an error instead of returning everything. That is the property worth having: a
connection that forgot to say who it is gets nothing.

Two cautions about the demonstration. `ana` owns the table and is the database's superuser, and
both of those skip row-level security, which is why the search runs as `helpdesk`, a role with only
`SELECT`. And the policy is a condition PostgreSQL applies to the rows the plan produces. On a
large table with an HNSW index it behaves like the filters in the post-filtering section: a small
tenant in a big table gets fewer than k rows. The fixes there apply here too.

## One collection, or one per tenant

Row-level security is one way to draw the boundary inside a shared table. The other is not to share:
**one collection, table or index per tenant**, so that a query for Folio cannot reach Marginalia's
vectors because they are somewhere else. Each has its place:

| | shared, with a tenant filter | one per tenant |
|---|---|---|
| a small tenant's results | can be cut short by post-filtering | searched in its own index, no filter to cut them |
| many small tenants | one index to build and keep | thousands of indexes, each with overhead |
| a forgotten filter | leaks, unless the database enforces it | cannot leak across tenants |
| deleting a tenant | a delete over many rows | dropping one collection |

The vector databases have their own terms for both options. Qdrant documents both a payload field
per tenant and a collection per tenant, Pinecone has namespaces inside an index, and Chroma has
tenants and databases above its collections. Lesson 14 met Supabase recommending row-level
security for the same purpose. None of those hosted options was run here.

Whichever you choose, the test is the same as everywhere in this lesson: write the query that should
return nothing, a search from one tenant for a phrase that only appears in another's documents, and
check that it does.
