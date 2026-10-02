---
title: The reply is untrusted input
version: 1
---

A model's reply goes somewhere: into a page, a query, a shell command, a file. **Treat it like
anything else that came from outside**, because often it did: the model copies text from what it
read, and what it read was written by someone else.

## Into a page

A product review, with a script tag in it, is summarised for the product page:

```python
"""Put a model's summary into a page, twice: as it came, and escaped."""
import html
import subprocess
import sys

summary = subprocess.run([sys.executable, "ask.py", "Summarise this product review: " + open("review.html").read()],
                         capture_output=True, text=True).stdout.strip()
print("as it came: <div class=\"summary\">" + summary + "</div>")
print("escaped:    <div class=\"summary\">" + html.escape(summary) + "</div>")
```

```
ana@dev:~/shop$ python render.py
as it came: <div class="summary">Customers like the lamp's warm light. One review ends with: <script>alert("hi")</script></div>
escaped:    <div class="summary">Customers like the lamp&#x27;s warm light. One review ends with: &lt;script&gt;alert(&quot;hi&quot;)&lt;/script&gt;</div>
```

**The model copied the tag from the review into its summary.** Put into the page as it came, it is
a script that runs in every visitor's browser. Escaped, it is text that shows what it says. The
escaping is one call, and it belongs at the point where text becomes HTML, the same as for any
other user content. Templating systems that escape by default do this for you; turning that off
for "trusted" model output is the mistake.

## Into a query

```python
"""Use a model's answer in a query, twice: pasted into the SQL, and as a parameter."""
import sqlite3
import subprocess
import sys

name = subprocess.run([sys.executable, "ask.py", "Which customer wrote this email? Reply with the name only."],
                      capture_output=True, text=True).stdout.strip()
db = sqlite3.connect(":memory:")
db.execute("create table customers (name text, email text)")
db.execute("insert into customers values (?, ?)", ("Dara O'Brien", "dara@example.com"))
try:
    print("pasted:   ", db.execute(f"select email from customers where name = '{name}'").fetchall())
except sqlite3.Error as e:
    print("pasted:    sqlite3 error:", e)
print("parameter:", db.execute("select email from customers where name = ?", (name,)).fetchall())
```

```
ana@dev:~/shop$ python lookup.py
pasted:    sqlite3 error: near "Brien": syntax error
parameter: [('dara@example.com',)]
```

**An apostrophe in a real name breaks the pasted query.** Here it fails loudly. A reply shaped
differently would change what the query does instead of breaking it. A parameter is never part of
the SQL, so the same answer finds Dara's email.

## The rule, every time

- **HTML**: escape, or use a template that escapes by default.
- **SQL**: parameters, never string formatting.
- **Shell**: an argument list, never a command string; better still, no shell.
- **Markdown rendered as HTML**: sanitise the result, because Markdown allows raw HTML through.
- **File paths**: resolve and check that they stay inside the folder, as lesson 7's handbook tool
  did.

None of this is new. **What is new is that the untrusted text arrives looking like your own
program's output**, from a function you wrote, and that is when people forget.
