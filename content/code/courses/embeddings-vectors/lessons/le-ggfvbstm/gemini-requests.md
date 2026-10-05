---
title: Calling Gemini's embedding endpoint
version: 1
---

Every provider's embedding call has the same shape: text goes in, one vector per text comes back,
and the details that differ are the names of things. Lesson 7 met that shape through OpenAI's SDK.
This section meets it through Google's, `google-genai`, and three later sections through Cohere's.

**Neither SDK talks to Google or Cohere here.** Both talk to **labembed**, a small server written for this course that listens on `127.0.0.1:8500`.
It answers the same URLs with the same JSON the providers answer with, closely enough that their own
libraries accept it unmodified. Its vectors are
real, from the two models that run on this machine, served under the lab's own names `lab-minilm`
(384 numbers) and `lab-wordllama` (256). What it is not is Google's model: it refuses the name
`gemini-embedding-001` rather than answer with something else wearing it. Against Google the code
below changes in three places — no `http_options`, the model's real name, and your own key — and in
nothing else.

```schooling-example
{
  "language": "python",
  "file": "gemini.py",
  "parts": [
    {
      "code": "import os\nimport numpy as np\nfrom google import genai\nfrom google.genai import types",
      "note": "The SDK installs as `google.genai`; `types` holds the classes a request is built from."
    },
    {
      "code": "client = genai.Client(\n    api_key=os.environ[\"GEMINI_API_KEY\"],\n    http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]),\n)",
      "note": "`genai.Client` takes the key and, through `http_options`, the address to send requests to. Here that is labembed; leave `http_options` out and the SDK goes to Google."
    },
    {
      "code": "r = client.models.embed_content(model=\"lab-minilm\", contents=\"When your refund arrives\")\nv = np.array(r.embeddings[0].values, dtype=np.float32)\nprint(len(r.embeddings), v.shape)",
      "note": "One text in. The response holds a list of embeddings, one per text, and each has its numbers in `values`."
    },
    {
      "code": "titles = [\"Tracking a parcel\", \"Payment methods we accept\", \"Audiobooks\"]\nr = client.models.embed_content(\n    model=\"lab-wordllama\",\n    contents=titles,\n    config=types.EmbedContentConfig(\n        task_type=\"RETRIEVAL_DOCUMENT\",\n        output_dimensionality=128,\n    ),\n)",
      "note": "Three texts in one call, with a `config` that says what they are for and how many numbers to return. `lab-wordllama` returns 256 unless asked for fewer."
    },
    {
      "code": "V = np.array([e.values for e in r.embeddings], dtype=np.float32)\nprint(V.shape, np.linalg.norm(V, axis=1).round(4))\nV = V / np.linalg.norm(V, axis=1, keepdims=True)",
      "note": "Print the lengths as they arrived, then divide each vector by its own length. Google documents that only its full-size output comes back normalised, so a truncated vector needs this line before a dot product is a cosine."
    }
  ],
  "output": "ana@lab:~/emb$ python gemini.py\n1 (384,)\n(3, 128) [1. 1. 1.]\nana@lab:~/emb$ jq -c '{path, inputs, dims, task_type}' /var/log/labembed/requests.jsonl\n{\"path\":\"/v1beta/models/lab-minilm:batchEmbedContents\",\"inputs\":1,\"dims\":384,\"task_type\":null}\n{\"path\":\"/v1beta/models/lab-wordllama:batchEmbedContents\",\"inputs\":3,\"dims\":128,\"task_type\":\"RETRIEVAL_DOCUMENT\"}"
}
```

**One method takes one text or a list of them.** `embed_content` returned one embedding for the
single title and three for the list, in the order the titles went in. There is no `index` field to
match on, as OpenAI's response has; the position in `r.embeddings` is the only link back to the
text, so keep the list you sent.

The log line labembed wrote for each request shows something the code does not. **The SDK sent
both calls to `:batchEmbedContents`**, the endpoint for several texts, even the one with a single
title: the method name is singular and the request on the wire is a batch of one. It also shows
`task_type` arriving as `null` on the first call and as `RETRIEVAL_DOCUMENT` on the second, which
is the next section's subject.

## Fewer dimensions on request

`output_dimensionality=128` asked for 128 numbers instead of the model's 256, and got them. The
server keeps the first 128 coordinates and drops the rest, which only works for a model trained so
that its leading coordinates carry most of the meaning on their own; lesson 7 measured what that
costs `lab-wordllama` on the 24 queries. `lab-minilm` was not trained that way, and asking it for
128 is refused, as the second refusal at the end of this section shows.

Google's own model, **gemini-embedding-001**, returns 3,072 numbers by default and is documented as
trained for exactly this truncation, with 768 and 1,536 as the recommended smaller sizes. Its
documentation adds a detail that is easy to miss: **only the full 3,072-number output comes back
normalised.** A shorter one is the first coordinates of a unit vector, which is no longer of length
1, so a dot product between two of them is not a cosine any more. The last part of `gemini.py`
divides every vector by its length for that reason. labembed renormalises after truncating, which is why the
lengths printed before that line are already 1.0, and here the line changes nothing; against Google it is the line that keeps every score in lesson 2's
range.

## When a request is refused

The SDK turns a refusal into a `ClientError` carrying the HTTP code, Google's status word and the
message:

```schooling-example
{
  "language": "python",
  "file": "gemini_errors.py",
  "parts": [
    {
      "code": "import os\nfrom google import genai\nfrom google.genai import errors, types\n\nclient = genai.Client(\n    api_key=os.environ[\"GEMINI_API_KEY\"],\n    http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]),\n)\ntries = [\n    (\"gemini-embedding-001\", None),\n    (\"lab-minilm\", types.EmbedContentConfig(output_dimensionality=128)),\n    (\"lab-minilm\", types.EmbedContentConfig(task_type=\"SEARCH_QUERY\")),\n]\nfor model, config in tries:\n    try:\n        client.models.embed_content(model=model, contents=\"Audiobooks\", config=config)\n    except errors.ClientError as e:\n        print(e.code, e.status, \"|\", e.message)",
      "note": "Three requests the server refuses, each for a different reason. `errors.ClientError` is what the SDK raises for any 4xx answer, and it carries the code, Google's status word and the message."
    }
  ],
  "output": "ana@lab:~/emb$ python gemini_errors.py\n404 NOT_FOUND | The model `gemini-embedding-001` does not exist or you do not have access to it. This lab serves lab-minilm and lab-wordllama.\n400 INVALID_ARGUMENT | This model does not support specifying dimensions.\n400 INVALID_ARGUMENT | Invalid value at 'requests[0].task_type' (SEARCH_QUERY)"
}
```

The first is the name check: a provider's model name gets a 404 here, never a stand-in. The second
is the fixed-dimension model refusing `output_dimensionality`, the same refusal lesson 7 met from
the OpenAI endpoint. The third is a task type that does not exist; Google's list of valid ones is in
the next section, and `SEARCH_QUERY` is not on it.
