---
title: One set of rules, read by both sides
version: 1
---

The fix has two halves. **The server checks every field itself**, which is the security half,
and **the form is generated from the server's rules**, which keeps the browser's check honest
instead of merely present.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l03-one\" aria-label=\"One set of rules, FIELDS, written once on the server. An arrow goes from it to the HTML form, where it becomes the attributes maxlength, type and max. Another arrow goes to the validate function, where it becomes the checks. Because both come from the same place, the form and the server cannot disagree about a limit.\"><defs><marker id=\"l03-one-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">FIELDS (one place)</text><rect x=\"330\" y=\"20\" width=\"250\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"40.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the form's attributes</text><text x=\"455.0\" y=\"53.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">maxlength, type, max</text><rect x=\"330\" y=\"120\" width=\"250\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"140.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">validate()</text><text x=\"455.0\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same limits, enforced</text><path d=\"M210 85 L270 85 L270 47 L330 47\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-one-ah-paper-dim)\"></path><path d=\"M210 105 L270 105 L270 147 L330 147\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-one-ah-paper-dim)\"></path></svg>", "caption": "Write each limit once, on the server, and generate the form from it."}
```

Here is the whole of the new `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import re\nfrom datetime import date\n\nfrom flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nPATIENTS = []\nTODAY = date(2026, 11, 1)\nEMAIL = re.compile(r\"[^@\\s]+@[^@\\s]+\\.[^@\\s]+\")\n", "note": "`TODAY` is fixed so the transcripts repeat; a real portal uses `date.today()`. The e-mail pattern checks the shape and no more."}, {"code": "FIELDS = {\n    \"name\": {\"label\": \"Name\", \"type\": \"text\", \"maxlength\": 60},\n    \"email\": {\"label\": \"E-mail\", \"type\": \"email\", \"maxlength\": 120},\n    \"birth\": {\"label\": \"Birth date\", \"type\": \"date\", \"max\": TODAY.isoformat()},\n}\n", "note": "Every limit, written once. The form and the check both read this dictionary, so they cannot disagree."}, {"code": "PAGE = \"\"\"<form method=\"post\" action=\"/signup\">\n{%- for name, f in fields.items() %}\n  <label>{{ f.label }} <input name=\"{{ name }}\" type=\"{{ f.type }}\" required\n    {%- if f.maxlength %} maxlength=\"{{ f.maxlength }}\"{% endif %}\n    {%- if f.max %} max=\"{{ f.max }}\"{% endif %}></label>\n  {%- if name in errors %} <strong>{{ errors[name] }}</strong>{% endif %}\n{%- endfor %}\n  <button>Sign up</button>\n</form>\"\"\"\n\n", "note": "The form is generated from `FIELDS`. An error is shown beside the field it is about, which helps the person; the refusal itself is the server's."}, {"code": "def validate(form):\n    errors, patient = {}, {}\n    for name, f in FIELDS.items():\n        value = form.get(name, \"\").strip()\n        if not value:\n            errors[name] = \"required\"\n        elif len(value) > f.get(\"maxlength\", 10):\n            errors[name] = \"too long\"\n        elif f[\"type\"] == \"email\" and not EMAIL.fullmatch(value):\n            errors[name] = \"not an e-mail address\"\n        elif f[\"type\"] == \"date\":\n            try:\n                if not date(1900, 1, 1) <= date.fromisoformat(value) <= TODAY:\n                    errors[name] = \"out of range\"\n            except ValueError:\n                errors[name] = \"not a date\"\n        patient[name] = value\n    return errors, patient\n\n", "note": "The same limits, enforced. `patient` is built from the names in `FIELDS` and nothing else, so a field the form never had is never stored. A date has no `maxlength`, so 10 characters, the length of `YYYY-MM-DD`, stands in."}, {"code": "@app.get(\"/signup\")\ndef form():\n    return render_template_string(PAGE, fields=FIELDS, errors={})\n\n\n@app.post(\"/signup\")\ndef signup():\n    errors, patient = validate(request.form)\n    if errors:\n        return render_template_string(PAGE, fields=FIELDS, errors=errors), 400\n    PATIENTS.append(patient)\n    return \"Welcome\", 201", "note": "A refusal is the same page with the errors in it and status 400, so a browser shows it and a script can tell it failed."}]}
```

The form keeps every attribute it had. A patient in a browser sees the same instant feedback as
before, now with the server's own message beside the field when something gets past the browser.
What changed is where the numbers live.

### Green

```
(.venv) ana@vm:~/sc/signup$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/signup
collected 8 items

test_app.py ........                                                     [100%]

============================== 8 passed in 0.15s ===============================
```

```
(.venv) ana@vm:~/sc/signup$ git commit -am "Check every field on the server, and draw the form from the same rules"
[main d3e87bc] Check every field on the server, and draw the form from the same rules
 1 file changed, 42 insertions(+), 5 deletions(-)
```

### The form, as the server now writes it

`curl` with no `-d` sends a `GET`, and prints the page the browser would receive. Every
`maxlength` and the `max` on the date come from `FIELDS`:

```
(.venv) ana@vm:~/sc/signup$ curl -s -w '\n' http://127.0.0.1:5000/signup
<form method="post" action="/signup">
  <label>Name <input name="name" type="text" required maxlength="60"></label>
  <label>E-mail <input name="email" type="email" required maxlength="120"></label>
  <label>Birth date <input name="birth" type="date" required max="2026-11-01"></label>
  <button>Sign up</button>
</form>
```

And the request from the previous section, sent again to the new server, is refused with a 400
and the reason beside each field:

```
(.venv) ana@vm:~/sc/signup$ curl -s -w '\n%{http_code}\n' -d 'name=&email=lucia&birth=2031-01-01' http://127.0.0.1:5000/signup
<form method="post" action="/signup">
  <label>Name <input name="name" type="text" required maxlength="60"></label> <strong>required</strong>
  <label>E-mail <input name="email" type="email" required maxlength="120"></label> <strong>not an e-mail address</strong>
  <label>Birth date <input name="birth" type="date" required max="2026-11-01"></label> <strong>out of range</strong>
  <button>Sign up</button>
</form>
400
```

### What this does not settle

The e-mail pattern checks that there is something, an `@`, something, a dot and something.
Addresses are far more varied than any pattern, and **the only real check of an e-mail address is
sending a message to it** with a link to confirm. A pattern that tried to be complete would refuse
real addresses and still accept ones that do not exist. Keep the syntactic check loose, and let the
confirmation link decide.
