---
title: Placeholders for values, an allowlist for the rest
version: 1
---

The fix has two halves, because the query had two holes.

**The surname is a value**, so it goes through a placeholder. The SQL text says `LIKE ?`, and the
pattern travels in the tuple beside it: `(f"%{term}%",)`. Building the pattern `%D'Ávila%` in Python
is safe, because it is still one value; what matters is that it never becomes part of the SQL text.

**The sort is not a value.** `ORDER BY ?` would sort by a constant string, the same for every row,
which sorts nothing. A column name has to be written into the SQL, so the request is not allowed to
supply it. It chooses a **key** from `SORTS`, and the SQL gets the text the code wrote for that key.
An unknown key is `400 Bad Request`, which is what a sort nobody offered is.

```
(.venv) ana@vm:~/sc/search$ git diff
diff --git a/app.py b/app.py
index 121204c..d768bf2 100644
--- a/app.py
+++ b/app.py
@@ -20,6 +20,7 @@ SAMPLE = [
     ("Marta", "Avelar", "Pinheiros"),
     ("Bruno", "O'Neill", "Santana"),
 ]
+SORTS = {"surname": "surname", "clinic": "clinic, surname"}
 
 
 def db():
@@ -49,10 +50,13 @@ def init_db():
 @app.get("/patients")
 def search():
     term = request.args.get("surname", "")
-    order = request.args.get("sort", "surname")
+    order = SORTS.get(request.args.get("sort", "surname"))
+    if order is None:
+        abort(400)
     rows = db().execute(
-        f"SELECT first_name, surname, clinic FROM patients "
-        f"WHERE surname LIKE '%{term}%' ORDER BY {order}"
+        "SELECT first_name, surname, clinic FROM patients "
+        f"WHERE surname LIKE ? ORDER BY {order}",
+        (f"%{term}%",),
     )
     return jsonify([dict(row) for row in rows])
 
```

```
(.venv) ana@vm:~/sc/search$ pytest -q --tb=no
....F                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_percent_and_underscore_are_searched_for_literally - ...
1 failed, 4 passed in 0.22s
```

**Four of five.** The apostrophe test passes with lucia found, and `sort=age` is refused before
any SQL is built. The `f` in `f"WHERE surname LIKE ? ORDER BY {order}"` is still there, and it is
safe for one reason that a reviewer can check in one line: `order` can only be one of the two
strings in `SORTS`.

Commit this step:

```
(.venv) ana@vm:~/sc/search$ git commit -qam "Pass the surname as a parameter, and allowlist the sort"
```

### What the placeholder did

`sqlite3` sent the database two things: the text `SELECT … WHERE surname LIKE ? ORDER BY surname`,
and the value `%D'Ávila%`. The database prepared the text first, with a hole where `?` was, and
then compared each surname with the value. **No character of the value was ever parsed as SQL**,
so there is no character for anybody to escape, strip or worry about. That is why the fix needs no
list of dangerous characters, and why it works the same for every database and every language that
has a driver with placeholders, which is all of them.

Each driver spells the placeholder its own way: `?` in `sqlite3`, `%s` in `psycopg` for
PostgreSQL, `:name` in SQLAlchemy's `text()`, `$1` in Go's `pgx`. `%s` deserves a warning of its
own: in `psycopg` it is a placeholder, passed to `execute` with the values beside it, and **the same
two characters with Python's `%` operator are string formatting**, which is the flaw again.
