---
title: Reflected: HTML built outside the template
version: 1
---

The search returns the inbox when something matches. When nothing does, it answers with a sentence
built by an f-string:

```python
        return f"<p>No messages match {term}.</p>"
```

The rest of the application uses templates, which escape. This one line does not use one, so the term
reaches the page exactly as it arrived (`-w '\n'` only prints a line break after the answer):

```
(.venv) ana@vm:~/sc/messages$ curl -s -w '\n' -G --data-urlencode 'q=<i>knee</i>' http://127.0.0.1:5000/search
<p>No messages match <i>knee</i>.</p>
```

`<i>knee</i>` came back as `<i>knee</i>`, and a browser would show **knee** in italics. Here the
term only ever reaches the person who typed it, so the risk is a link somebody else wrote, with the
term already in it, which the receptionist opens. That is why reflected XSS is often found in error
pages and "no results" messages: they are written in a hurry, often by hand, and they quote the
request.

The fix puts the sentence in a template, where `term` is a variable and is escaped like every other:

```
(.venv) ana@vm:~/sc/messages$ git diff
diff --git a/app.py b/app.py
index de8e65b..6ed83f1 100644
--- a/app.py
+++ b/app.py
@@ -35,5 +35,5 @@ def search():
     term = request.args.get("q", "")
     found = [m for m in MESSAGES if term.lower() in m["text"].lower()]
     if not found:
-        return f"<p>No messages match {term}.</p>"
+        return render_template_string("<p>No messages match {{ term }}.</p>", term=term)
     return render_template_string(INBOX, messages=found)
```

```
(.venv) ana@vm:~/sc/messages$ pytest -q --tb=no
....F                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_script_writes_text_not_markup - assert 'innerHTM...
1 failed, 4 passed in 0.12s
```

**One failure left**, and it is the one no server-side test can see in the page. Commit:

```
(.venv) ana@vm:~/sc/messages$ git commit -qam "Write the no-match sentence through the template"
```

The rule this applies is the one from lesson 4: **HTML is produced by the template engine, never by
joining strings**. A route that returns a string with a tag in it, built from anything the request
carried, is the thing to look for in review. JSON is the safer default for a response that is not a
page, and Flask's `jsonify` sends it with a content type browsers do not render as HTML.
