---
title: Task types and asymmetric search
version: 1
---

The obvious picture of search is two texts compared like with like: embed the question, embed the
article, and the closer the two vectors the better the match. That picture treats both sides as
the same kind of text. **In search they are not.** The question is short, written by a customer,
and asks; the article is long, written by the shop, and explains. *can I pay in three parts* and
*Payment methods we accept* share almost no words and are not paraphrases of each other. One is
the other's answer.

A model can be trained for that difference. Its training pairs are questions and the passages that
answer them, and it is told during training which side of each pair a text is on. Such a model
embeds a text **differently depending on whether it is a query or a document**, so that a question
lands near its answers rather than near other questions that sound like it. This is called
**asymmetric** search, and Google's `task_type` is how you tell its model which side a text is on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two rows. When you index: each help-centre article is embedded as a document, with task type RETRIEVAL_DOCUMENT for Gemini or input type search_document for Cohere, and the vectors are stored. When a customer asks: the question can I pay in three parts is embedded as a query, with RETRIEVAL_QUERY or search_query, and compared with the stored vectors to give the top three. Both kinds of vector land in one space.\"><defs><marker id=\"sidesen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sidesen-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">when you index</text><rect x=\"20\" y=\"44\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"26\" y=\"50\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"32\" y=\"56\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"127\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Payment methods we accept</text><path d=\"M222 70 L262 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidesen-ah0)\"></path><rect x=\"264\" y=\"48\" width=\"210\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">RETRIEVAL_DOCUMENT</text><text x=\"369\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">search_document</text><path d=\"M474 70 L528 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidesen-ah0)\"></path><rect x=\"530\" y=\"52\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"538\" y=\"58\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"546\" y=\"64\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"554\" y=\"70\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">stored vectors</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">when a customer asks</text><rect x=\"20\" y=\"194\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">can I pay in three parts</text><path d=\"M210 214 L262 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidesen-ah0)\"></path><rect x=\"264\" y=\"192\" width=\"210\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">RETRIEVAL_QUERY</text><text x=\"369\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">search_query</text><path d=\"M474 214 L528 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidesen-ah0)\"></path><rect x=\"530\" y=\"196\" width=\"90\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">compare</text><path d=\"M590 124 L590 194\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidesen-ah1)\"></path><path d=\"M620 214 L642 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidesen-ah0)\"></path><rect x=\"644\" y=\"196\" width=\"70\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"679\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">top 3</text><text x=\"700\" y=\"284\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one space, two kinds of text</text></svg>", "caption": "The two sides of a search are different kinds of text, and a model trained for that difference is told which side each text is on. The labels go in at both ends; the vectors still meet in one space. labembed accepts the labels and ignores them."}
```

## The task types Google documents

| `task_type` | use it for |
|---|---|
| `RETRIEVAL_DOCUMENT` | the texts you store and search: articles, chunks, product pages |
| `RETRIEVAL_QUERY` | the question a search is run for |
| `QUESTION_ANSWERING` | a query when the documents are answers to questions |
| `FACT_VERIFICATION` | a query that is a claim, against documents that confirm or refute it |
| `CODE_RETRIEVAL_QUERY` | a question in words, against code embedded as documents |
| `SEMANTIC_SIMILARITY` | two texts of the same kind, compared with each other |
| `CLASSIFICATION` | texts that will be features for a classifier, as in lesson 4 |
| `CLUSTERING` | texts that will be grouped, with no labels |

The first five are the two sides of a search, one document type and four query types, and that is the rule that matters: **index with
`RETRIEVAL_DOCUMENT`, search with one of the query types, and never index with a query type.** The
last three are symmetric. Every text is the same kind of thing, so both sides get the same type.

Which type a vector was made with is part of what the vector is, in the same way lesson 1 made the
model part of the data. A document indexed with `SEMANTIC_SIMILARITY` and searched with
`RETRIEVAL_QUERY` is a mismatch the API will not report, because each call on its own was valid.

## What the lab does with it

**Nothing, and you can see that it does nothing.** Both of the lab's models are symmetric: neither
was trained with a query side and a document side, so there is no second way for them to embed a
text. labembed checks the task type against Google's list, records it, and embeds the text the same
way whatever it says:

```schooling-example
{
  "language": "python",
  "file": "tasks.py",
  "parts": [
    {
      "code": "import os\nimport numpy as np\nfrom google import genai\nfrom google.genai import types\n\nclient = genai.Client(\n    api_key=os.environ[\"GEMINI_API_KEY\"],\n    http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]),\n)\ntext = \"can I pay in three parts\"",
      "note": "The same client as `gemini.py`, and one customer question."
    },
    {
      "code": "def as_task(task):\n    r = client.models.embed_content(\n        model=\"lab-minilm\", contents=text,\n        config=types.EmbedContentConfig(task_type=task),\n    )\n    return np.array(r.embeddings[0].values, dtype=np.float32)",
      "note": "Embed the same question with a given task type and return the vector as a NumPy array."
    },
    {
      "code": "q = as_task(\"RETRIEVAL_QUERY\")\nfor task in [\"RETRIEVAL_DOCUMENT\", \"SEMANTIC_SIMILARITY\", \"CLASSIFICATION\"]:\n    d = as_task(task)\n    print(f\"{task:20} max difference from RETRIEVAL_QUERY: {np.abs(q - d).max()}\")",
      "note": "The question as a query, then as three other task types, and the largest difference between any coordinate of the two vectors."
    }
  ],
  "output": "ana@lab:~/emb$ python tasks.py\nRETRIEVAL_DOCUMENT   max difference from RETRIEVAL_QUERY: 0.0\nSEMANTIC_SIMILARITY  max difference from RETRIEVAL_QUERY: 0.0\nCLASSIFICATION       max difference from RETRIEVAL_QUERY: 0.0\nana@lab:~/emb$ jq -c '{inputs, task_type}' /var/log/labembed/requests.jsonl | tail -n 4\n{\"inputs\":1,\"task_type\":\"RETRIEVAL_QUERY\"}\n{\"inputs\":1,\"task_type\":\"RETRIEVAL_DOCUMENT\"}\n{\"inputs\":1,\"task_type\":\"SEMANTIC_SIMILARITY\"}\n{\"inputs\":1,\"task_type\":\"CLASSIFICATION\"}"
}
```

The four vectors for *can I pay in three parts* are identical to the last bit, and the log shows
that the server received four different task types. gemini-embedding-001 is documented to
embed them differently; how much was not measured here, because no request reached Google, and no
number in this course stands in for one.

The consequence for what you write is the opposite of the lab's behaviour. **Pass the task type
everywhere, even where it makes no difference today.** Code that indexes with `RETRIEVAL_DOCUMENT`
and searches with `RETRIEVAL_QUERY` is correct against a symmetric model and against an asymmetric
one. Switching models later then changes one name rather than every call site. The invalid type in the previous section, `SEARCH_QUERY`, is refused with a 400 for the same
reason: a type the model does not know is a mistake worth hearing about at the first request.
