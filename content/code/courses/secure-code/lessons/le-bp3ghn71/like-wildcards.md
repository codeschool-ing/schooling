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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l05-like\" aria-label=\"The same search term read by two interpreters in turn. Above, the term % is passed as a placeholder, so SQL reads it as a value and not as code; then LIKE reads the same value as a pattern, where % means any run of characters, and every surname matches. Below, like_pattern turns the term into a backslash and a percent sign; SQL still reads it as a value, and LIKE, told that the backslash escapes, reads a literal percent sign, which no surname contains.\"><defs><marker id=\"l05-like-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">typed</text><text x=\"330\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">read by SQL</text><text x=\"580\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">read by LIKE</text><rect x=\"20\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">%</text><path d=\"M140 75 L240 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"240\" y=\"50\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a value, not code</text><path d=\"M420 75 L480 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"480\" y=\"50\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">any run of characters</text><text x=\"590.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">every patient matches</text><rect x=\"20\" y=\"124\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\\%</text><path d=\"M140 149 L240 149\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"240\" y=\"124\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a value, not code</text><path d=\"M420 149 L480 149\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"480\" y=\"124\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"142.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a literal %</text><text x=\"590.0\" y=\"155.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no patient matches</text><text x=\"190\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">like_pattern()</text></svg>", "caption": "The placeholder settles the first reader and nothing more. The pattern needs its own escape, because LIKE is a second reader."}
```

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
