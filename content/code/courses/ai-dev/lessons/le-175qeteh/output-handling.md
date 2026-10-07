---
title: The reply is untrusted input
version: 2
---

A model's reply goes somewhere: into a page, a query, a shell command, a file. **Treat it like
anything else that came from outside**, because often it did: the model copies text from what it
read, and what it read was written by someone else.

## Into a page

A product review arrives with a script tag in it, `review.html`:

```html
<p>Love the lamp, the light is warm.</p><script>alert("hi")</script>
```

and the model is asked to rewrite it as HTML for the product page. `render.py` keeps the block of code
from the reply, on one line, and puts it into the page twice:

```python
"""Put a model's rewrite of a review into a page, twice: as it came, and escaped."""
import html
import re
import subprocess
import sys

reply = subprocess.run([sys.executable, "ask.py", "Rewrite this product review as HTML for the product page, "
                        "keeping its markup: " + open("review.html").read()], capture_output=True, text=True).stdout
block = re.search(r"```\w*\n(.*?)\n```", reply, re.S)
fragment = " ".join((block.group(1) if block else reply).split())
print("as it came: <div class=\"review\">" + fragment + "</div>")
print("escaped:    <div class=\"review\">" + html.escape(fragment) + "</div>")
```

```
ana@dev:~/shop$ python render.py
as it came: <div class="review"><p>Love the lamp, the light is warm.</p> <script>alert("hi")</script></div>
escaped:    <div class="review">&lt;p&gt;Love the lamp, the light is warm.&lt;/p&gt; &lt;script&gt;alert(&quot;hi&quot;)&lt;/script&gt;</div>
```

**The model kept the tag**, as it was asked to keep the markup. Put into the page as it came, it is a
script that runs in every visitor's browser. Escaped, it is text that shows what it says. A request
that sounded harmless, keep the review's formatting, is all it took. The escape is what makes it
harmless. It is one call, and it belongs at the point where text becomes HTML, the same as
for any other user content. Templating systems that escape by default do this for you; turning that
off for "trusted" model output is the mistake.

## Into a query

```python
"""Use a model's answer in a query, twice: pasted into the SQL, and as a parameter."""
import sqlite3
import subprocess
import sys

EMAIL = "The lamp from my last order flickers when I turn it on. Can you help?\n\nDara O'Brien"
name = subprocess.run([sys.executable, "ask.py", "Which customer wrote this email? Reply with the name only.\n\n" + EMAIL],
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

The model read the name off the email's signature, as asked: `Dara O'Brien`. **An apostrophe in a real
name breaks the pasted query.** Here it fails loudly. A reply shaped
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
