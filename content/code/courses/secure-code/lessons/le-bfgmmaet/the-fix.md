---
title: A template that knows where it is writing
version: 1
---

The fix is not six escape calls in the f-string. It is **a template engine that escapes by
default**, so that the safe thing happens without anybody remembering it, and the two contexts the
default does not cover (inside `<script>` and inside a URL) written with the tool made for each.

Flask renders Jinja2 templates with **autoescaping on** for HTML, and `render_template_string`
counts as HTML. Every `{{ … }}` is HTML-escaped unless something says otherwise. Here is the new
`app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "from urllib.parse import urlsplit\n\nfrom flask import Flask, render_template_string\n\nfrom profiles import PROFILES\n\napp = Flask(__name__)\n", "note": "The data moves to `profiles.py`, unchanged, so the diff shows only the page."}, {"code": "PAGE = \"\"\"<h1>{{ p.name }}</h1>\n<input name=\"nickname\" value=\"{{ p.nickname }}\">\n{% if website %}<a href=\"{{ website }}\">website</a>{% endif %}\n<a href=\"{{ url_for('search', q=p.name) }}\">bookings of {{ p.name }}</a>\n<script>const note = {{ p.note|tojson }};</script>\n\"\"\"\n", "note": "One template, four contexts. Jinja escapes `{{ … }}` for HTML in the text and in the **quoted** attribute; `url_for` builds the query; `tojson` writes a JavaScript literal safe inside `<script>`."}, {"code": "\ndef web_link(url):\n    return url if urlsplit(url).scheme in (\"http\", \"https\") else None\n", "note": "Escaping makes a link's text harmless and says nothing about where it goes. Only web addresses become links."}, {"code": "\n@app.get(\"/patients/<user>\")\ndef profile(user):\n    p = PROFILES[user]\n    return render_template_string(PAGE, p=p, website=web_link(p[\"website\"]))\n\n\n@app.get(\"/search\")\ndef search():\n    return \"\"", "note": "`/search` exists so `url_for` has a route to name; what it does is lesson 5's."}]}
```

Four details in that template carry the lesson:

- **`{{ p.name }}` is escaped** in the heading and in the link text, the way the first row of the
  figure says.
- **`value="{{ p.nickname }}"` is quoted.** Autoescaping escapes `"` as `&#34;`, which is enough
  only because the attribute has quotes to protect. Write `value={{ p.nickname }}` without them and
  a space in the nickname would end the attribute, escaped or not.
- **`url_for('search', q=p.name)` builds the query**, URL-encoding the value, and autoescaping
  then HTML-escapes the whole URL for the attribute: the two layers from the second figure, in the
  right order, with no code written for either.
- **`{{ p.note|tojson }}` has no quotes around it.** `tojson` writes the quotes itself, as part of
  the JavaScript literal. Quotes around it would produce `""…""`, which is a different bug.

### Green

```
(.venv) ana@vm:~/sc/profile$ pytest -q
......                                                                   [100%]
6 passed in 0.11s
```

```
(.venv) ana@vm:~/sc/profile$ git commit -am "Render the profile with an autoescaping template, tojson and url_for"
[main 40e37e0] Render the profile with an autoescaping template, tojson and url_for
 1 file changed, 15 insertions(+), 8 deletions(-)
```

### The page, as it is written now

```
(.venv) ana@vm:~/sc/profile$ curl -s http://127.0.0.1:5000/patients/lucia
<h1>Lucia &amp; Bia &lt;3</h1>
<input name="nickname" value="Lu &#34;the fast&#34;">
<a href="https://lucia.example/blog?a=1&amp;b=2">website</a>
<a href="/search?q=Lucia+%26+Bia+%3C3">bookings of Lucia &amp; Bia &lt;3</a>
<script>const note = "back pain \u003c/script\u003e again";</script>
```

Every value is where its context expects it, in the encoding its reader expects. In a browser the
page shows exactly what the patient typed: `Lucia & Bia <3` in the heading, `Lu "the fast"` in the
box, `back pain </script> again` in the note. **Correct escaping is invisible to the person
reading the page**, which is also why its absence is so rarely reported.
