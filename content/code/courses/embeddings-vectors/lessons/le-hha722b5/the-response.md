---
title: The response
version: 1
---

A response is a small envelope around a list. The list, `data`, holds one embedding object per
input text; around it sit the model's name and a `usage` count. Sending three texts shows all of
it:

```schooling-example
{
  "language": "python",
  "file": "response.py",
  "parts": [
    {
      "code": "import base64\nimport numpy as np\nfrom openai import OpenAI\n\nclient = OpenAI()\ntexts = [\"When your refund arrives\", \"Tracking a parcel\", \"Two-step sign-in\"]",
      "note": "Three texts in one request."
    },
    {
      "code": "r = client.embeddings.create(model=\"lab-minilm\", input=texts)\nprint(r.object, r.model, r.usage)\nfor d in r.data:\n    print(\" \", d.object, d.index, len(d.embedding), texts[d.index])",
      "note": "The response is a list of embedding objects, each carrying its `index`: the position of its text in `input`. Print each one beside the text it belongs to."
    },
    {
      "code": "raw = client.embeddings.with_raw_response.create(model=\"lab-minilm\", input=texts[0])\nprint(raw.http_request.content.decode())\nwire = raw.http_response.json()[\"data\"][0][\"embedding\"]\nprint(wire[:40], \"...\", len(wire), \"characters\")",
      "note": "`with_raw_response` keeps the HTTP exchange the SDK normally hides. The request body shows what the SDK added on its own, and the response body shows what came back over the wire."
    },
    {
      "code": "v = np.frombuffer(base64.b64decode(wire), dtype=\"<f4\")\nprint(v.shape, v.dtype, \"largest difference from the SDK's list:\",\n      np.abs(v - raw.parse().data[0].embedding).max())",
      "note": "Decode that string as four-byte little-endian floats and compare it with the list the SDK handed over."
    }
  ]
}
```

```
ana@lab:~/emb$ python response.py
list lab-minilm Usage(prompt_tokens=14, total_tokens=14)
  embedding 0 384 When your refund arrives
  embedding 1 384 Tracking a parcel
  embedding 2 384 Two-step sign-in
{"model":"lab-minilm","input":"When your refund arrives","encoding_format":"base64"}
/DixvTxsabzYtpK7rhQePU+9Jj3W8qw88OqPPbXB ... 2048 characters
(384,) float32 largest difference from the SDK's list: 0.0
```

## Match by index, not by position

Each embedding object carries an **`index`**, the position of its text in the `input` list. The
lines above came back in order, 0, 1, 2, and it is tempting to rely on that and zip `data` with
the inputs. That relies on an arrangement; the index is the field whose job is to say which text a
vector belongs to. Sorting by it, or looking texts up by it as `response.py` does, costs
one line and removes a way to file a vector under the wrong article without any error at all. The next section's batching function does exactly that.

**`usage.prompt_tokens`** is what the request is billed on. An embedding has no output tokens, so
`total_tokens` is the same number. The section on cost comes back to how those tokens are counted.

## What actually crossed the wire

The second part of the program asked for the raw HTTP exchange, and its first line shows something
the code never asked for: the SDK added **`"encoding_format": "base64"`** to the request body.
labembed's log said the same thing in the previous section.

So the server did not send 384 decimal numbers. It sent the vector's 1,536 bytes of `float32`,
encoded as base64 text, and the SDK decoded them back into a list of floats before handing it over.
The last line checks that: the decoded bytes and the SDK's list differ by nothing at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Four boxes left to right, one vector's journey. The server's 384 float32 numbers, 1,536 bytes, are written as 2048 characters of base64 inside the JSON answer. The SDK decodes the base64 back into 1,536 bytes and reads them as little-endian float32, handing over a list of 384 floats.\"><defs><marker id=\"wireen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">on the server</text><text x=\"90\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">384 float32</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in the JSON</text><text x=\"270\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2048 characters</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">decoded</text><text x=\"450\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1,536 bytes</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what you get</text><text x=\"630\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">list of 384 floats</text><path d=\"M162 68 L198 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wireen-ah0)\"></path><text x=\"180\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base64</text><path d=\"M342 68 L378 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wireen-ah0)\"></path><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base64 decode</text><path d=\"M522 68 L558 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wireen-ah0)\"></path><text x=\"540\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">read as &lt;f4</text><path d=\"M 340 124 L 340 134 L 558 134 L 558 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"449\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the SDK does these two steps</text><path d=\"M 160 124 L 160 134 L 198 134 L 198 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"179\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the server does this one</text></svg>", "caption": "What the SDK's default encoding does to one vector of lab-minilm. The same 1,536 bytes leave the server and reach your list; base64 is only how they travel inside JSON."}
```

The reason is size. Sending the same request with `curl`, once with the default and once asking
for base64:

```
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | wc -c
8594
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request-b64.json | wc -c
2203
```

The answer as decimal numbers is 8,594 bytes; as base64 it is 2,203, about a quarter. Written out
as text, each number takes over twenty characters; in base64 it takes under six. Multiply that by
every vector in a batch of two thousand texts, then by every batch, and the saving is why the SDK
asks for base64 without being told. If you call the endpoint without the SDK, ask for base64
yourself and decode it as little-endian `float32`, as `response.py` did.
