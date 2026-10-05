---
title: Supabase
version: 1
---

Supabase is a hosted platform built around a PostgreSQL database. Every project gets a whole
database, and pgvector is one of the extensions it offers, so everything in the last three sections
works there unchanged: the same column type, the same operators, the same `CREATE INDEX`. What is
different is the way an application usually reaches it. **A Supabase client does not send SQL.** It
talks over HTTPS to an API that Supabase generates from your schema, and that API can filter and
sort by columns but has no way to say `ORDER BY embedding <=> $1`.

**Supabase was not run for this lesson.** It is a hosted service and this machine cannot reach it.
The SQL below is plain PostgreSQL and did run, in the lab's database; the Python that calls it over
the network is shown from Supabase's documentation and was not run.

## The search becomes a function

The documented answer is to put the search inside a SQL function and call the function through the
API. Supabase's guide to semantic search calls it `match_documents`. Here is the same shape with this
lesson's table, run in the lab:

```schooling-example
{
  "language": "sql",
  "file": "match.sql",
  "parts": [
    {
      "code": "CREATE FUNCTION match_articles(\n    query_embedding vector(384),\n    match_threshold float,\n    match_count int\n)\nRETURNS TABLE (id text, title text, similarity float)\nLANGUAGE sql STABLE",
      "note": "A function that takes the query's vector, a minimum similarity and a maximum number of rows, and returns a table. This is the shape Supabase's guide to semantic search uses, with this lesson's table and column names."
    },
    {
      "code": "AS $$\n    SELECT a.id, a.title, 1 - (a.embedding <=> query_embedding)\n    FROM articles a\n    WHERE a.embedding <=> query_embedding < 1 - match_threshold\n    ORDER BY a.embedding <=> query_embedding\n    LIMIT match_count;\n$$;",
      "note": "The body is the query from `search.py` with one more condition: a distance below one minus the threshold is a similarity above it."
    },
    {
      "code": "SELECT * FROM match_articles(\n    (SELECT embedding FROM queries WHERE id = 'q01'), 0.4, 3);",
      "note": "Called from SQL with the stored vector of q01, which is the question `search.py` was asked."
    }
  ],
  "output": "ana@lab:~/emb$ psql -f match.sql\nCREATE FUNCTION\n id  |          title           |     similarity     \n-----+--------------------------+--------------------\n h18 | Returning a gift         | 0.4455630513690092\n h15 | When your refund arrives | 0.4375660717487335\n(2 rows)"
}
```

**The function asked for three rows and returned two.** h22, *Charged twice for one order*, scored
`0.399` in `search.py`, just under the threshold of 0.4, so the `WHERE` dropped it. A threshold
beside the count is what lesson 16 argues for, and this function has both.

`LANGUAGE sql STABLE` tells PostgreSQL the function only reads, which lets the planner treat it like
the query inside it. The function is ordinary schema: it goes in a migration with the table, and
it changes when the query does.

From the application, the call names the function and passes its arguments as JSON. The vector
travels as a JSON array of 384 numbers and arrives as a `vector`, because that is the type of the
parameter:

```python
import os
from supabase import create_client
from minilm import embed

supabase = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_KEY"])
q = embed("how do I get my money back")[0]

result = supabase.rpc("match_articles", {
    "query_embedding": q.tolist(),
    "match_threshold": 0.4,
    "match_count": 3,
}).execute()
for row in result.data:
    print(row["id"], row["title"], row["similarity"])
```

The program would embed the question on the caller's side, with the same model as the stored
articles, exactly as `search.py` did. Supabase stores and searches; it does not choose the model or
check that the two vectors came from the same one. And the `384` in the parameter's type is not the
check it looks like. PostgreSQL ignores the size written on a function's parameter, so a vector of
another length gets into the function and is refused one step later, by the operator:

```
ana@lab:~/emb$ psql -c "SELECT * FROM match_articles(array_fill(0.1::real, ARRAY[256])::vector, 0.4, 3)"
ERROR:  different vector dimensions 384 and 256
```

**The column refused a wrong vector on the way in; the function refuses it only at the
comparison.** Either way a vector from WordLlama's 256 dimensions cannot be scored against the
articles, and either way two models with the same dimension would pass.

## Row-level security decides what a search can see

The API is reachable from a browser, and a browser holds whatever key the page was given. So the
boundary cannot be in the client. Supabase's documentation recommends **row-level security** on
every table the API exposes: a policy on the table, enforced by PostgreSQL itself, that decides which
rows each request may read. Its guide to retrieval with permissions uses exactly that to keep one
user's documents out of another user's searches.

The policy reaches inside `match_articles` too. A SQL function runs by default with the rights of
whoever calls it, PostgreSQL's `SECURITY INVOKER`, so the rows the function sorts are already the
rows the caller may see. A function declared `SECURITY DEFINER` runs with its owner's rights and
skips the caller's policies, which turns a search function into a way round them.

Two keys matter. The **anon** key is meant for the browser and is subject to the policies. The
**service_role** key bypasses row-level security entirely, so it belongs on a server and never in a
page. Lesson 17 builds a row-level security policy for two shops in the lab's PostgreSQL and shows
the same query returning each shop only its own articles.
