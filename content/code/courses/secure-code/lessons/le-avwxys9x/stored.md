---
title: Stored: the value marked safe
version: 1
---

The inbox template writes each message like this:

```
{{ m.text|replace("\n", "<br>")|safe }}
```

The intention was reasonable. Messages have line breaks, HTML ignores line breaks, so the template
turns each `\n` into `<br>`, and then marks the result `safe` so that Jinja does not escape the
`<br>` tags it just added. **`safe` does not apply to the `<br>` tags alone; it applies to the whole
value**, so everything else lucia typed is trusted as HTML too. Lesson 18's review found the same
line in a diff and marked it as finding 3.

The fix keeps the line breaks without any HTML. The text is written as an ordinary escaped value, and
one line of CSS tells the browser to show its line breaks: `white-space: pre-line`.

```
(.venv) ana@vm:~/sc/messages$ git diff
diff --git a/app.py b/app.py
index 5936458..de8e65b 100644
--- a/app.py
+++ b/app.py
@@ -9,12 +9,15 @@ MESSAGES = [
 
 INBOX = """<!doctype html>
 <html lang="en">
-<head><meta charset="utf-8"><title>Inbox</title></head>
+<head>
+<meta charset="utf-8"><title>Inbox</title>
+<style>.message { white-space: pre-line; }</style>
+</head>
 <body>
 <h1 id="reply">Inbox</h1>
 <form action="/search"><input name="q"><button>Search</button></form>
 {% for m in messages %}
-<p class="message"><strong>{{ m.patient }}</strong>: {{ m.text|replace("\\n", "<br>")|safe }}</p>
+<p class="message"><strong>{{ m.patient }}</strong>: {{ m.text }}</p>
 {% endfor %}
 <script src="/static/inbox.js"></script>
 </body>
```

```
(.venv) ana@vm:~/sc/messages$ pytest -q --tb=no
...FF                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_search_term_is_shown_as_text - AssertionError: ass...
FAILED test_app.py::test_the_script_writes_text_not_markup - assert 'innerHTM...
2 failed, 3 passed in 0.11s
```

**Two fewer failures.** lucia's `<b>` is now the six characters she sent, shown as written.

### Where `safe` hides

Every template engine has a way to switch escaping off for one value, and each is a place to look in
review: `|safe` and `Markup(...)` in Jinja, `{% autoescape false %}`, `mark_safe` and `|safe` in
Django, `dangerouslySetInnerHTML` in React (named, deliberately, to make a reviewer stop), `v-html` in
Vue, `{{{ }}}` in Handlebars. The question each time is the same: **could any part of this value have
come from a person?** If the answer is yes, the value is not safe, whatever the reason for marking it.

When some formatting really is needed, a message editor with bold and lists for instance, the answer
is a **sanitiser**: a library that parses the HTML and keeps only an allowlist of tags and attributes,
such as `nh3` in Python or DOMPurify in the browser. It is the allowlist idea of lesson 2, applied to
markup, and it belongs to the feature that needs it rather than to every message.

Commit:

```
(.venv) ana@vm:~/sc/messages$ git commit -qam "Show messages as text, with line breaks kept by CSS"
```
