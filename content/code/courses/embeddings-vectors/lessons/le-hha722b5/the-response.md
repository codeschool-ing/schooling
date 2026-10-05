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
vector belongs to. Sorting by it, or looking texts up by it as `response.py` does,
costs one line and removes a way to file a vector under the wrong article without any error at
all. The next section's batching function does exactly that.

**`usage.prompt_tokens`** is what the request is billed on. An embedding has no output tokens, so
`total_tokens` is the same number. The section on cost comes back to how those tokens are counted.

## What actually crossed the wire

The second part of the program asked for the raw HTTP exchange, and its first line shows something
the code never asked for: the SDK added **`"encoding_format": "base64"`** to the request body.
labembed's log said the same thing in the previous section.

So the server did not send 384 decimal numbers. It sent the vector's 1,536 bytes of `float32`,
encoded as base64 text, and the SDK decoded them back into a list of floats before handing it over.
The last line checks that: the decoded bytes and the SDK's list differ by nothing at all.

The reason is size. Sending the same request with `curl`, once with the default and once asking
for base64:

```
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | wc -c
8594
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request-b64.json | wc -c
2203
```

Written out as decimal text, each number takes about twenty characters; as base64, each takes
under six. Multiply that by every vector in a batch of two thousand texts, then by
every batch, and the saving is why the SDK asks for base64 without being told. If you call the endpoint without the SDK, ask for base64
yourself and decode it as little-endian `float32`, as `response.py` did.
