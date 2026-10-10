---
title: A contract test
version: 1
---

**A contract test sends real requests to the running API and holds every answer up against the
document.** If the status code is not one the operation lists, if a required header is missing, if
the body does not fit its schema, the test fails and says which. That is what turns `openapi.yaml`
from a description into living documentation: the day `rest.py` and the document disagree, a
program says so.

For each request it asks five questions, one before sending and four after:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"What check_contract.py does for each request, in order. One: if there is a body, check it against the requestBody schema, and expect a refusal if the spec refuses it. Two: send it to rest.py. Three: look the status code up in the operation&#x27;s responses. Four: check the required headers. Five: check the Content-Type against content. Six: validate the body against the schema. Any step that does not hold adds a line under a FAIL for that request.\"><defs><marker id=\"l06-seq-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  the body</text><text x=\"65.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">requestBody</text><rect x=\"128\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"179.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  send</text><text x=\"179.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rest.py</text><line x1=\"116\" y1=\"65\" x2=\"127\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"242\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"293.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  the status</text><text x=\"293.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">responses</text><line x1=\"230\" y1=\"65\" x2=\"241\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"356\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"407.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  headers</text><text x=\"407.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">required</text><line x1=\"344\" y1=\"65\" x2=\"355\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"470\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"521.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5  media type</text><text x=\"521.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">content</text><line x1=\"458\" y1=\"65\" x2=\"469\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"584\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">6  the body</text><text x=\"635.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">schema</text><line x1=\"572\" y1=\"65\" x2=\"583\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><text x=\"14\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before the request</text><text x=\"242\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after the answer, against the operation it belongs to</text><line x1=\"65\" y1=\"90\" x2=\"65\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"293\" y1=\"90\" x2=\"293\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"407\" y1=\"90\" x2=\"407\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"521\" y1=\"90\" x2=\"521\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"635\" y1=\"90\" x2=\"635\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"14\" y=\"142\" width=\"672\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">FAIL, and one line saying which step did not hold</text><text x=\"14\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the server accepted what the spec refuses</text><text x=\"686\" y=\"204\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the server answered what the spec does not describe</text></svg>", "caption": "One request, five questions. The first is about what was sent, and the other four about what came back."}
```

The first question is the easy one to forget. Checking only what comes back would never notice a
server that accepts what the document forbids, and that is where the more serious of shelf's two
disagreements turns out to be.

## The test

Save it as `check_contract.py` beside the others. It needs `python3-yaml` and `python3-jsonschema`,
both from lesson 1, and nothing from the venv.

```schooling-example
{
  "language": "python",
  "file": "shelf/check_contract.py",
  "parts": [
    {
      "code": "# shelf/check_contract.py\n\"\"\"Call the running rest.py and check every answer against openapi.yaml.\n\nStart the server first, then run `python3 check_contract.py`. It exits with 1\nwhen the API and its description disagree anywhere.\n\"\"\"\nimport json\nimport os\nimport re\nimport sys\nimport urllib.error\nimport urllib.request\n\nimport jsonschema\nimport yaml",
      "note": "Two packages from lesson 1's `apt-get` line, `python3-yaml` and `python3-jsonschema`, and the standard library for the rest. The test runs with Ubuntu's `python3` and needs nothing from the venv."
    },
    {
      "code": "\nHERE = os.path.dirname(os.path.abspath(__file__))\nwith open(os.path.join(HERE, \"openapi.yaml\"), encoding=\"utf-8\") as f:\n    SPEC = yaml.safe_load(f)\nBASE = SPEC[\"servers\"][0][\"url\"]\nNEW = {\"isbn\": \"9786500000085\", \"title\": \"Esaú e Jacó\", \"author_id\": 1,\n       \"year\": 1904, \"price_cents\": 3790}\nfailures = 0",
      "note": "The address comes from the spec's own `servers`, so the test calls whatever the document says the API is. `NEW` is a book db.py does not have, which the test creates and deletes again."
    },
    {
      "code": "\n\ndef deref(node):\n    \"\"\"Follow a $ref such as #/components/responses/NotFound to its object.\"\"\"\n    while \"$ref\" in node:\n        target = SPEC\n        for key in node[\"$ref\"].removeprefix(\"#/\").split(\"/\"):\n            target = target[key]\n        node = target\n    return node",
      "note": "A `$ref` such as `#/components/responses/NotFound` is a path through the document, one key per segment."
    },
    {
      "code": "\n\ndef problems(value, schema):\n    \"\"\"What is wrong with value under schema, as sentences; [] if nothing.\"\"\"\n    whole = dict(schema, components=SPEC[\"components\"])\n    return [e.message for e in jsonschema.Draft202012Validator(whole).iter_errors(value)]",
      "note": "The schemas point at each other with `$ref`, and those references start at the root of a document. Copying `components` into the schema being checked gives them a root where `#/components/schemas/Book` exists."
    },
    {
      "code": "\n\ndef operation(method, path):\n    \"\"\"The spec's path template for a real path, and its operation for method.\"\"\"\n    bare = path.split(\"?\")[0]\n    for template, item in SPEC[\"paths\"].items():\n        if re.fullmatch(re.sub(r\"\\{\\w+\\}\", \"[^/]+\", template), bare):\n            return template, item.get(method.lower())\n    return path, None",
      "note": "Which template a real path belongs to: `{id}` becomes \"anything up to the next slash\", and the query string is left out."
    },
    {
      "code": "\n\ndef send(method, path, body):\n    data = None if body is None else json.dumps(body).encode()\n    request = urllib.request.Request(BASE + path, data=data, method=method)\n    if data is not None:\n        request.add_header(\"Content-Type\", \"application/json\")\n    try:\n        with urllib.request.urlopen(request) as answer:\n            return answer.status, answer.headers, answer.read()\n    except urllib.error.HTTPError as answer:\n        return answer.code, answer.headers, answer.read()",
      "note": "One request with Python's own client. `urlopen` raises an exception for any 4xx or 5xx, and the exception carries the status, the headers and the body like a normal answer, which is all a contract test wants from it."
    },
    {
      "code": "\n\ndef check(method, path, body=None):\n    \"\"\"Send one request, compare the answer with the spec, print a verdict.\"\"\"\n    global failures\n    template, op = operation(method, path)\n    status, headers, raw = send(method, path, body)\n    kind = headers.get(\"Content-Type\", \"\")\n    wrong = []\n    if op is None:\n        wrong.append(f\"the spec has no {method} {template}; the answer was {kind or 'empty'}\")\n    else:\n        if body is not None:\n            schema = op[\"requestBody\"][\"content\"][\"application/json\"][\"schema\"]\n            refused = problems(body, schema)\n            if refused and status < 400:\n                wrong.append(\"accepted a body the spec refuses: \" + refused[0])",
      "note": "The check has two directions. First the request: a body the spec refuses should be refused by the server too, and an answer below 400 means it was not."
    },
    {
      "code": "        documented = op[\"responses\"].get(str(status))\n        if documented is None:\n            wrong.append(f\"{status} is not an answer the spec lists\")\n        else:\n            documented = deref(documented)\n            for name, header in documented.get(\"headers\", {}).items():\n                if header.get(\"required\") and name not in headers:\n                    wrong.append(f\"no {name} header\")\n            content = documented.get(\"content\")\n            if content is None:\n                if raw:\n                    wrong.append(\"a body, where the spec says there is none\")\n            elif kind not in content:\n                wrong.append(f\"{kind or 'no body'}, where the spec says {', '.join(content)}\")\n            else:\n                for problem in problems(json.loads(raw), content[kind][\"schema\"]):\n                    wrong.append(\"the answer: \" + problem)\n    print(f\"{'FAIL' if wrong else 'ok':4}  {method} {path} -> {status}\")\n    for line in wrong:\n        print(f\"      {line}\")\n    failures += bool(wrong)\n    return status, headers",
      "note": "Then the answer: is the status code listed, are the required headers there, is the `Content-Type` one the spec names, and does the body fit its schema? A status the document never mentions is a failure even when the body looks fine."
    },
    {
      "code": "\n\ncheck(\"GET\", \"/books\")\ncheck(\"GET\", \"/books?author_id=3\")\ncheck(\"GET\", \"/books/1\")\ncheck(\"GET\", \"/books/99\")\ncheck(\"GET\", \"/authors/2\")\ncheck(\"GET\", \"/authors/2/books\")",
      "note": "Six reads, an existing book and a missing one among them."
    },
    {
      "code": "status, headers = check(\"POST\", \"/books\", NEW)\nif status != 201:\n    sys.exit(\"could not create the test book; is shelf.db as db.py made it?\")\nmade = headers[\"Location\"].rsplit(\"/\", 1)[1]\ncheck(\"POST\", \"/books\", NEW)\ncheck(\"PATCH\", f\"/books/{made}\", {\"stock\": 4})\ncheck(\"PUT\", f\"/books/{made}\", {\"stock\": 4})",
      "note": "The writes, on a book of the test's own, so nothing of db.py's six is touched: create it, create it again, change it, and replace it with a body missing most of its fields."
    },
    {
      "code": "status, headers = check(\"POST\", \"/books\", dict(NEW, isbn=\"978-65-00000-08-5\"))\nif status == 201:\n    check(\"DELETE\", headers[\"Location\"].removeprefix(\"/v1\"))\ncheck(\"DELETE\", f\"/books/{made}\")\ncheck(\"DELETE\", f\"/books/{made}\")\ncheck(\"OPTIONS\", \"/books\")",
      "note": "The same book with its ISBN written the way it is printed, with hyphens, then the cleaning up, and a method the spec does not describe at all."
    },
    {
      "code": "\nprint(f\"{failures} disagreement{'' if failures == 1 else 's'}\")\nsys.exit(1 if failures else 0)",
      "note": "The exit status is the verdict, so a script or a CI job can run the test and stop on a disagreement without reading a line of it."
    }
  ]
}
```

## Running it

The server has to be running in the second terminal, as in lesson 1: `cd ~/shelf && python3
rest.py`. Then, in the first:

```
ana@api:~/shelf$ python3 check_contract.py; echo "exit $?"
ok    GET /books -> 200
ok    GET /books?author_id=3 -> 200
ok    GET /books/1 -> 200
ok    GET /books/99 -> 404
ok    GET /authors/2 -> 200
ok    GET /authors/2/books -> 200
ok    POST /books -> 201
ok    POST /books -> 409
ok    PATCH /books/7 -> 200
ok    PUT /books/7 -> 422
FAIL  POST /books -> 201
      accepted a body the spec refuses: '978-65-00000-08-5' does not match '^[0-9]{13}$'
      the answer: '978-65-00000-08-5' does not match '^[0-9]{13}$'
ok    DELETE /books/8 -> 204
ok    DELETE /books/7 -> 204
ok    DELETE /books/7 -> 404
FAIL  OPTIONS /books -> 501
      the spec has no OPTIONS /books; the answer was text/html;charset=utf-8
2 disagreements
exit 1
```

Thirteen requests agreed with the document and two did not, and the exit status of 1 says so to
anything that runs the test. Your ids may differ from `7` and `8` if your shelf has had books added
since lesson 1; the verdicts will not. The test also left the shop as it found it:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books | jq length
6
```

## The first disagreement: a rule the server does not keep

The document says an ISBN is thirteen digits. The test sent `978-65-00000-08-5`, which is the same
book as `9786500000085` written the way ISBNs are printed, and `rest.py` answered 201. Two lines
explain the failure. The first says the server accepted a body the document refuses. The
line starting `the answer:` says that the book it sent back breaks the document too, because the
`Book` schema has the same pattern.

**And the consequence is worse than a format.** Look at the order of the requests. The hyphenated
copy was created as book 8 while book 7, the same book with its plain ISBN, still existed. The 409
that the document promises for a second book with the same ISBN never came, because the database's
`UNIQUE` compares strings, and the two strings differ. With the rule in the document enforced, the
second copy would have been refused at the door.

Which side is wrong is a decision, not a fact the test can know. Here it is the code: the document
states the shop's rule and `rest.py` forgot to check it. In a real project you would fix it the
same day, by adding the pattern to the checks every write already goes through, and that line of
the test would turn to `ok`. shelf's `rest.py` stays as it is, because every lesson of this course builds on it; the
failing line stays as a known disagreement for the rest of the course.

## The second: an answer nobody described

`OPTIONS /books` got the 501 and the HTML page from lesson 1. The document has no `options`
operation, so the test reports the method as undescribed and names the media type that came back,
`text/html`, in an API that answers JSON everywhere else. This disagreement is in the other
direction: the document is silent and the server answers anyway. Either the server should answer
`OPTIONS` properly, which lesson 13 comes back to for browsers, or the document should describe
what it does.

## What it cannot see

**A contract test checks the requests it sends, and no others.** This one sends fifteen. It never
asks for `/v1/books?author_id=abc`, although the document says `author_id` is an integer:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' 'localhost:8000/v1/books?author_id=abc'
[]
200
```

`rest.py` took the text, found no author by that id and answered 200 with an empty list. A client
that sent a name where an id belongs is told there are no books, rather than that it asked wrongly.
Nothing in the run above could see it.

Writing more requests by hand helps, and so does the other approach: tools that read the document
and generate the requests themselves, many of them, aimed at every edge the schemas describe.
Schemathesis is one and Dredd another; neither is run in this course. They find more than a hand
list does, and they find it against the same document, which is the point. The document is the one
place the contract is stated, and every check, by hand or generated, is a check against it.
