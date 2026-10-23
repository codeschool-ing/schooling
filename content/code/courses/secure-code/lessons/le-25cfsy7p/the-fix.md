---
title: The fix, at one boundary
version: 1
---

The fix replaces the denylist with an allowlist per field, and it moves all of the checking into
one place. **Validation belongs at the boundary**, where data from outside enters the program, and
it should happen there once. A check scattered through the code is a check somebody forgets on the
new route; a check at the boundary is the reason the rest of the code never has to ask.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l02-flow\" aria-label=\"Where validation sits in the booking application. A request arrives at the boundary, the route. One function, validate, turns the raw JSON into a Booking with typed fields, or refuses it with a 400 that names the field. Past the boundary, the rest of the code receives only Booking values and never looks at raw input again.\"><defs><marker id=\"l02-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request</text><text x=\"80\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">raw JSON: text, anything</text><rect x=\"220\" y=\"80\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">validate()</text><rect x=\"470\" y=\"40\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the rest of the code</text><text x=\"585\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">a Booking: typed, in range</text><rect x=\"470\" y=\"150\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">400, naming the field</text><path d=\"M140 102 L220 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-flow-ah-paper-dim)\"></path><path d=\"M360 95 L420 95 L420 62 L470 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-flow-ah-paper-dim)\"></path><path d=\"M360 110 L420 110 L420 172 L470 172\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-flow-ah-amber)\"></path><path d=\"M190 30 L190 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"190\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the boundary</text></svg>", "caption": "Validate once, where the data enters, and turn it into a type the rest of the code can trust."}
```

Here is the whole of `app.py` after the change. Replace the file with it:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import re\nfrom dataclasses import dataclass\nfrom datetime import date\n\nfrom flask import Flask, jsonify, request\n\napp = Flask(__name__)\nBOOKINGS = []\n", "note": "Same application; `looks_safe` and its list are gone."}, {"code": "CLINICS = {\"pinheiros\", \"moema\", \"tatuape\", \"santana\"}\nSLOTS = {f\"{hour:02d}:00\" for hour in range(7, 20)}\nPHONE = re.compile(r\"[0-9]{10,11}\")\n", "note": "The allowlists: four clinics, one slot an hour from 07:00 to 19:00, a phone of 10 or 11 ASCII digits. Each one describes what is good, so the next surprise is refused without anybody having predicted it."}, {"code": "\nclass Invalid(Exception):\n    def __init__(self, field):\n        super().__init__(field)\n        self.field = field\n\n\n@dataclass(frozen=True)\nclass Booking:\n    clinic: str\n    day: date\n    time: str\n    phone: str\n", "note": "What leaves the boundary is a `Booking`, with a real `date` in it, not a dictionary of strings."}, {"code": "\ndef validate(data):\n    if not isinstance(data, dict):\n        raise Invalid(\"body\")\n    clinic, day, time, phone = (data.get(k) for k in (\"clinic\", \"date\", \"time\", \"phone\"))\n    if clinic not in CLINICS:\n        raise Invalid(\"clinic\")\n    try:\n        parsed = date.fromisoformat(day)\n    except (TypeError, ValueError):\n        raise Invalid(\"date\") from None\n    if time not in SLOTS:\n        raise Invalid(\"time\")\n    if not isinstance(phone, str) or not PHONE.fullmatch(phone):\n        raise Invalid(\"phone\")\n    return Booking(clinic, parsed, time, phone)\n", "note": "One function, one check per field, and each refusal names the field. `fullmatch` tests the whole string, where `match` would accept a valid phone followed by anything. A field that is absent is `None`, and `None` is in no allowlist."}, {"code": "\n@app.post(\"/bookings\")\ndef create():\n    try:\n        booking = validate(request.get_json(silent=True))\n    except Invalid as e:\n        return jsonify(error=f\"invalid {e.field}\"), 400\n    BOOKINGS.append(booking)\n    return jsonify(clinic=booking.clinic, date=booking.day.isoformat(),\n                   time=booking.time, phone=booking.phone), 201", "note": "The route validates and then only touches the `Booking`. `silent=True` turns a body that is not JSON into `None`, which `validate` refuses like any other bad input instead of letting Flask answer on its own."}]}
```

Three decisions in that file are worth naming, because they are the habits that carry to any
other form:

- **The output of validation is a different type from its input.** `validate` takes whatever JSON
  arrived and returns a `Booking`, or raises. Code that receives a `Booking` knows its date is a
  real date, without checking again, and a function that still takes a raw dictionary stands out
  in a review.
- **The error names the field and nothing else.** It does not echo the value back, and it does not
  explain the rule in a way that helps somebody probe it one character at a time. `invalid phone`
  is enough for the form to highlight the right box.
- **Absent and wrong are refused by the same check.** `data.get("phone")` is `None` when the field
  is missing, and `None` is not in any allowlist, so the missing field needs no code of its own.

### Green

```
(.venv) ana@vm:~/sc/booking$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/booking
collected 9 items

test_app.py .........                                                    [100%]

============================== 9 passed in 0.12s ===============================
```

`git diff --stat` summarises the change: one file, 43 lines in and 9 out. The 9 are the denylist
and the function that applied it, gone entirely; the 43 are the allowlists, the `Booking` type and
`validate`.

```
(.venv) ana@vm:~/sc/booking$ git diff --stat
 app.py | 52 +++++++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 43 insertions(+), 9 deletions(-)
(.venv) ana@vm:~/sc/booking$ git commit -am "Validate bookings against allowlists, at one boundary"
[main 4bbe89f] Validate bookings against allowlists, at one boundary
 1 file changed, 43 insertions(+), 9 deletions(-)
```

### And from outside

The test client and a real request see the same answer. Start the application with
`flask --app app run`, and from a second terminal send the impossible date with `curl`:

```
(.venv) ana@vm:~/sc/booking$ curl -s -X POST http://127.0.0.1:5000/bookings -H 'Content-Type: application/json' -d '{"clinic": "moema", "date": "2026-11-31", "time": "09:00", "phone": "11987654321"}'
{"error":"invalid date"}
```

Validation does not make a value **safe to use everywhere**. A clinic name that passed the
allowlist is still text, and the moment it goes into HTML, SQL or a shell command it needs the
handling that belongs to that place. Lessons 4 to 6 are about those places. What validation buys
is narrower and still worth a lesson: the program only ever holds data that means what it claims
to mean.
