---
title: The database enforces it
version: 2
---

The filter in `access.search` depends on every query remembering it. The query in this lesson does,
and the next one somebody writes, for a report, a debugging script, a new feature, may not. Lesson 13
met the same weakness in the memory table. The defence is to make the database apply the rule itself,
whatever the query says, with **row-level security**:

```schooling-example
{
  "language": "sql",
  "file": "policy.sql",
  "parts": [
    {
      "code": "-- The assistant reads through a role of its own, and the database decides which rows that role sees.\n-- Run by the loader, which owns the table and is not limited by the policy.\nDO $$ BEGIN CREATE ROLE assistant LOGIN PASSWORD 'reads-only'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;",
      "note": "A role for the assistant, created only if it does not exist yet: roles belong to the whole PostgreSQL server, not to one database. It logs in with a password, over `localhost`, because a role with no account on the machine cannot use the socket's peer authentication that your own login uses. On a machine of your own a password in a file is fine; in production it comes from a secret store."
    },
    {
      "code": "GRANT SELECT ON chunks TO assistant;\nALTER TABLE chunks ENABLE ROW LEVEL SECURITY;",
      "note": "It may read the table, and the table now checks a policy on every read."
    },
    {
      "code": "CREATE POLICY by_audience ON chunks FOR SELECT TO assistant\n    USING (audience = ANY (string_to_array(current_setting('rag.audiences', true), ',')));",
      "note": "The policy: a row is visible to `assistant` only if its audience is in the list the transaction set. With no list set, `current_setting(..., true)` is null, the comparison is never true, and no row is visible."
    }
  ]
}
```

The loader, your own login's role from lesson 1, owns the table and is not limited by the policy; the assistant
connects as `assistant`, a role that can only read, and every read it makes passes through
`by_audience`. A query from the assistant that forgets the `WHERE` entirely, counting every chunk by
audience:

```schooling-example
{
  "language": "python",
  "file": "asassistant.py",
  "parts": [
    {
      "code": "import sys\n\nimport psycopg\n\nwith psycopg.connect(host=\"localhost\", user=\"assistant\", password=\"reads-only\") as conn:\n    if len(sys.argv) > 1:\n        conn.execute(\"SELECT set_config('rag.audiences', %s, true)\", (sys.argv[1],))\n    rows = conn.execute(\"SELECT audience, count(*) FROM chunks GROUP BY audience ORDER BY audience\").fetchall()\n    print(rows or \"no rows\")",
      "note": "The assistant's own connection, counting every chunk it can see by audience, with no `WHERE` at all. An argument sets the audiences the transaction may read."
    }
  ]
}
```

```
ana@vm:~/rag$ psql -q -f policy.sql
ana@vm:~/rag$ python asassistant.py
no rows
ana@vm:~/rag$ python asassistant.py public
[('public', 86)]
ana@vm:~/rag$ python asassistant.py public,staff
[('public', 86), ('staff', 22)]
```

**With no audiences set, no rows at all.** With `public`, the 86 public chunks; with `public,staff`,
those and the 22 staff chunks. The finance chunks never appear, because nothing the assistant can do
on that connection names them. A query without a filter, which before this policy would have read
every row, now reads only what the transaction was told the reader may see.

Two details make the arrangement hold.

- **It fails closed.** A missing setting, a typo in the variable's name, a code path that forgot to
  set it: each makes `current_setting` return null, and null matches nothing. A permission system
  that opens on an unexpected input has a list of ways around it; this one has none.
- **The setting is per transaction**, set with `set_config(..., true)` from a value the program
  computed from the session. A setting that outlived its request would let the next request on a
  pooled connection inherit the last reader's permissions, which is the kind of bug that only appears
  under load.

The policy does not replace the `WHERE`; `access.search` keeps both. The `WHERE` makes the query
correct and fast, and the policy makes a query that forgot it safe. Lesson 13's memory table takes
the same kind of policy, with the account instead of the audience.
