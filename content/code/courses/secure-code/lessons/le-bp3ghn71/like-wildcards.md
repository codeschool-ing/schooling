---
title: LIKE has wildcards of its own
version: 1
---

One test still fails, and it is a different kind of problem. The placeholder made sure the value is
data. But the value is a **`LIKE` pattern**, and inside a pattern two characters have meanings of
their own: `%` matches any run of characters and `_` matches any single one. Search for `%`, and the
pattern `%%%` matches every patient in the portal:

```
(.venv) ana@vm:~/sc/search$ curl -s -G --data-urlencode 'surname=%' http://127.0.0.1:5000/patients
[{"clinic":"Pinheiros","first_name":"Marta","surname":"Avelar"},{"clinic":"Pinheiros","first_name":"Lucia","surname":"D'\u00c1vila"},{"clinic":"Santana","first_name":"Bruno","surname":"O'Neill"},{"clinic":"Moema","first_name":"Rafael","surname":"Souza"}]
```

No SQL was injected; the query did what a `LIKE` with that pattern does. Still, the receptionist
typed one character and received the whole patient list, and a search for `S_uza` finds `Souza`
when nobody typed an `o`. On a large table, a pattern full of wildcards is also slow. **Whatever a
value means inside the program that reads it, the code decides, not the person typing.**

The fix escapes the two wildcards, and the escape character itself, and tells SQLite which
character escapes with `ESCAPE '\'`:

```
(.venv) ana@vm:~/sc/search$ git diff
diff --git a/app.py b/app.py
index d768bf2..6b6c640 100644
--- a/app.py
+++ b/app.py
@@ -47,6 +47,11 @@ def init_db():
         db().commit()
 
 
+def like_pattern(term):
+    escaped = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
+    return f"%{escaped}%"
+
+
 @app.get("/patients")
 def search():
     term = request.args.get("surname", "")
@@ -55,8 +60,8 @@ def search():
         abort(400)
     rows = db().execute(
         "SELECT first_name, surname, clinic FROM patients "
-        f"WHERE surname LIKE ? ORDER BY {order}",
-        (f"%{term}%",),
+        f"WHERE surname LIKE ? ESCAPE '\\' ORDER BY {order}",
+        (like_pattern(term),),
     )
     return jsonify([dict(row) for row in rows])
 
```

```
(.venv) ana@vm:~/sc/search$ pytest -q
.....                                                                    [100%]
5 passed in 0.13s
```

**Five of five.** Commit, and look at the history:

```
(.venv) ana@vm:~/sc/search$ git commit -qam "Search for % and _ literally"
(.venv) ana@vm:~/sc/search$ git log --oneline
e44568f Search for % and _ literally
61f929c Pass the surname as a parameter, and allowlist the sort
ef40cab Search patients by surname, sorted
```

### Where else a value is a little program

`LIKE` is the case in this lesson; the habit is wider. A value placed into a regular expression
needs `re.escape`; a value placed into a shell command is lesson 6; a value placed into a page is
lesson 4. Each time, ask what reads the value next and what that reader treats as special.
