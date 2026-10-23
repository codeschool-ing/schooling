---
title: One value, four places
version: 1
---

Lesson 2 refused to decide at the input whether a character is dangerous, because the answer
depends on where the value goes next. This lesson is where it goes next. **Output handling means encoding a value for the exact place it is written into**, at the moment it is written. The reader of that place, whether a browser's HTML parser, its JavaScript engine or a URL parser, then reads it as data and never as part of the page's own structure.

The commonest wrong idea is that there is one function called *escape* and that calling it once is
enough. There are several encodings, one per context, and they are not interchangeable. Here is
one value, `Lu "B" <3 & co`, a perfectly ordinary nickname, and what it must become in each of four
places:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-four\" aria-label=\"The same value, Lu &quot;B&quot; &lt;3 &amp; co, written into four places in a page, with what it must become in each. In the text of an HTML element it becomes Lu &amp;#34;B&amp;#34; &amp;lt;3 &amp;amp; co. In a quoted attribute it becomes the same, and the quotes around the attribute are what make that enough. Inside a script it becomes a JavaScript string literal written by tojson, with the angle bracket and the ampersand as \\u003c and \\u0026. In a URL query it becomes Lu+%22B%22+%3C3+%26+co.\"><defs><marker id=\"l04-four-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"14\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Lu \"B\" &lt;3 &amp; co</text><rect x=\"20\" y=\"80\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTML text</text><rect x=\"200\" y=\"80\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lu &amp;#34;B&amp;#34; &amp;lt;3 &amp;amp; co</text><text x=\"515\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written by</text><text x=\"590\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">escape()</text><path d=\"M170 100 L200 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path><rect x=\"20\" y=\"132\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quoted attribute</text><rect x=\"200\" y=\"132\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lu &amp;#34;B&amp;#34; &amp;lt;3 &amp;amp; co</text><text x=\"515\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written by</text><text x=\"590\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">escape()</text><path d=\"M170 152 L200 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path><rect x=\"20\" y=\"184\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inside &lt;script&gt;</text><rect x=\"200\" y=\"184\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"Lu \\\"B\\\" \\u003c3 \\u0026 co\"</text><text x=\"515\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written by</text><text x=\"590\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">|tojson</text><path d=\"M170 204 L200 204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path><rect x=\"20\" y=\"236\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">URL query</text><rect x=\"200\" y=\"236\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lu+%22B%22+%3C3+%26+co</text><text x=\"515\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written by</text><text x=\"590\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">quote_plus()</text><path d=\"M170 256 L200 256\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path></svg>", "caption": "One value, four places, four encodings. The place decides the encoding, and nothing about the value does."}
```

Each row answers to a different reader:

- **HTML text.** Between tags, `<` would start a tag and `&` an entity. HTML escaping replaces
  them with `&lt;` and `&amp;`, and the browser shows the characters again.
- **A quoted attribute.** Inside `value="…"`, a `"` would end the attribute early and whatever
  followed would be read as more markup. HTML escaping turns it into `&#34;`. **The quotes around
  the attribute are part of the defence**: an unquoted attribute ends at a space, and escaping does
  not touch spaces.
- **Inside a `<script>`.** A JavaScript string needs its own escaping for `"` and `\`, and it
  also sits inside HTML, where `</script>` ends the script whatever the JavaScript thinks.
  Flask's `tojson` writes a JavaScript literal and turns `<`, `>`, `&` and `'` into `\u` escapes,
  so the HTML parser never sees a tag.
- **A URL query.** In `/search?q=…`, a space, `&` or `#` would end the value or start another
  parameter. URL encoding, `%26` for `&`, keeps the value one parameter.

### The four encodings, from Python

None of this needs a framework to see. This lesson's folder is `~/sc/profile`; make it and its
repository as in lesson 2, and save this beside it as `contexts.py`:

```python
# contexts.py
import json
from urllib.parse import quote_plus

from jinja2.utils import htmlsafe_json_dumps
from markupsafe import escape

value = 'Lu "B" <3 & co'
print("HTML text and quoted attribute:", escape(value))
print("JavaScript, json.dumps:        ", json.dumps(value))
print("JavaScript, as tojson writes it:", htmlsafe_json_dumps(value))
print("URL query:                     ", quote_plus(value))
```

```
(.venv) ana@vm:~/sc/profile$ python3 contexts.py
HTML text and quoted attribute: Lu &#34;B&#34; &lt;3 &amp; co
JavaScript, json.dumps:         "Lu \"B\" <3 & co"
JavaScript, as tojson writes it: "Lu \"B\" \u003c3 \u0026 co"
URL query:                      Lu+%22B%22+%3C3+%26+co
```

The second and third lines are the instructive pair. `json.dumps` writes a correct JavaScript
string, and **it leaves `<` alone**, because `<` means nothing to JavaScript. Inside `<script>` it
means a great deal to the HTML parser, which runs first. `htmlsafe_json_dumps`, the function behind
Flask's `tojson` filter, is `json.dumps` plus that one extra layer.

### Contexts nest

A link to the search page with the patient's name in it is a URL inside an attribute: two
contexts, one inside the other. **Encode from the inside out**: URL-encode the value for the query,
then HTML-escape the whole URL for the attribute. The browser undoes them in the opposite order.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-layers\" aria-label=\"A URL inside an HTML attribute needs two encodings, applied from the inside out. First the value is URL-encoded to go into the query string. Then the whole URL is HTML-escaped to go into the attribute. Reading the page, the browser undoes them in the opposite order: it decodes the attribute first, then the URL.\"><defs><marker id=\"l04-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"140\" y=\"20\" width=\"440\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTML-escaped: goes into href=\"…\"</text><rect x=\"190\" y=\"52\" width=\"340\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">URL-encoded: goes into the query</text><rect x=\"260\" y=\"90\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the value</text><path d=\"M40 190 L330 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-layers-ah-paper-dim)\"></path><text x=\"185\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the server writes, inside out</text><path d=\"M680 190 L390 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-layers-ah-paper-dim)\"></path><text x=\"535\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the browser reads, outside in</text></svg>", "caption": "Contexts nest. Each layer gets its own encoding, innermost first."}
```

Get the order wrong, or skip a layer, and the page still renders correctly for ordinary names.
That is why these flaws survive: the test that would catch them has to use a value with the
characters that matter in that context, and nobody's real name has all of them.
