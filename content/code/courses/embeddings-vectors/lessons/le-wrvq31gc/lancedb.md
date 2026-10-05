---
title: LanceDB, a table in files
version: 1
---

LanceDB is embedded like Chroma's `PersistentClient`: no server, a directory, a library in your
process. **What it keeps there is a table**, with typed columns, and the vector is one column among
them. The files are in Lance, a columnar format that reads and writes Apache Arrow data, the in-memory
format pandas and many other data tools exchange.

```schooling-example
{
  "language": "python",
  "file": "lance_load.py",
  "parts": [
    {
      "code": "import json\nimport lancedb\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "The articles and their vectors, as before."
    },
    {
      "code": "db = lancedb.connect(\"lance\")\ntable = db.create_table(\"help\", data=[\n    {\"id\": h[\"id\"], \"category\": h[\"category\"], \"lang\": h[\"lang\"],\n     \"title\": h[\"title\"], \"vector\": v} for h, v in zip(help, X)])\nprint(table.count_rows(), \"rows, version\", table.version)\nprint(table.schema.field(\"vector\"))",
      "note": "`connect` opens a directory, not a server. The table is created from a list of dictionaries, and the column named `vector` holds the embeddings."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0]\nfor r in table.search(q).limit(3).to_list():\n    print(f\"{r['_distance']:.4f}  {r['id']}  {r['title']}\")",
      "note": "A search with nothing else said, top three with their `_distance`."
    },
    {
      "code": "for r in (table.search(q).distance_type(\"cosine\")\n          .where(\"category = 'ebooks'\").limit(3).to_list()):\n    print(f\"{r['_distance']:.4f}  {r['id']}  {r['title']}\")",
      "note": "The same search measuring cosine distance, with a SQL condition on another column."
    }
  ],
  "output": "ana@lab:~/emb$ python lance_load.py\n40 rows, version 1\npyarrow.Field<vector: fixed_size_list<item: float>[384]>\n1.1089  h18  Returning a gift\n1.1249  h15  When your refund arrives\n1.2013  h22  Charged twice for one order\n0.6095  h33  Refunds for e-books\n0.8367  h35  Lending and sharing e-books\n0.8376  h37  Audiobooks"
}
```

The schema line says what the vector column is: a fixed-size list of 384 floats, declared by the
first rows that went in. A row with a vector of another length would not fit the column.

## The default is L2 again

**The first search returned 1.1089 for h18**, the number Chroma gave in its `l2` space in lesson 12.
LanceDB measures squared Euclidean distance unless it is told otherwise, which is also Chroma's
default. With `distance_type("cosine")` the numbers become cosine distances, 0.6095 for
*Refunds for e-books*, which is one minus the similarity again. The ranking of unit vectors is the
same either way; a threshold is not.

`where` takes a SQL condition on the other columns, `category = 'ebooks'` here, so the filter
language is one you already know. How that condition and the vector search are combined, before or
after the nearest neighbours are found, is lesson 17's subject.

## Every write is a version

**LanceDB never changes a file it has written.** A write adds new files and a new version of the
table that lists which files make it up, and that is visible from Python:

```schooling-example
{
  "language": "python",
  "file": "lance_versions.py",
  "parts": [
    {
      "code": "import lancedb\nfrom minilm import embed\n\ntable = lancedb.connect(\"lance\").open_table(\"help\")",
      "note": "Open the table the previous program made."
    },
    {
      "code": "table.add([{\"id\": \"h41\", \"category\": \"payments\", \"lang\": \"en\",\n            \"title\": \"Gift cards by email\", \"vector\": embed(\"Gift cards by email\")[0]}])\nprint(\"after add:   \", table.count_rows(), \"rows, version\", table.version)\ntable.delete(\"id = 'h41'\")\nprint(\"after delete:\", table.count_rows(), \"rows, version\", table.version)",
      "note": "Add a row, then delete it, and print the count and the version after each."
    },
    {
      "code": "for v in table.list_versions():\n    m = v[\"metadata\"]\n    print(\"version\", v[\"version\"], \":\", m[\"total_rows\"], \"rows in\", m[\"total_data_files\"], \"data file(s)\")",
      "note": "Every version the table has kept, with what its manifest records."
    },
    {
      "code": "table.checkout(2)\nprint(\"checked out version 2:\", table.count_rows(), \"rows\")\ntable.checkout_latest()",
      "note": "Go back to version 2 and count, then return to the latest."
    }
  ],
  "output": "ana@lab:~/emb$ python lance_versions.py\nafter add:    41 rows, version 2\nafter delete: 40 rows, version 3\nversion 1 : 40 rows in 1 data file(s)\nversion 2 : 41 rows in 2 data file(s)\nversion 3 : 40 rows in 1 data file(s)\nchecked out version 2: 41 rows"
}
```

The add made version 2, with 41 rows in two data files. The delete made version 3, with 40 rows in
one, and version 2 is still there: `checkout(2)` counted its 41 rows. The directory shows how:

```
ana@lab:~/emb$ find lance -type f | sort
lance/help.lance/_transactions/0-4692446b-a88b-41ab-8324-6d54f642fd99.txn
lance/help.lance/_transactions/1-0906e05f-9fda-44c5-b3ba-d71085bc1307.txn
lance/help.lance/_transactions/2-c9672946-c519-4cb1-8856-97574b72b86e.txn
lance/help.lance/_versions/18446744073709551612.manifest
lance/help.lance/_versions/18446744073709551613.manifest
lance/help.lance/_versions/18446744073709551614.manifest
lance/help.lance/_versions/latest_version_hint.json
lance/help.lance/data/010001110001111101101100d025274b918f5b95fbf82865c9.lance
lance/help.lance/data/111000101001111111110001cc51b347a3a213c5871aca4232.lance
```

One manifest per version in `_versions`, one transaction record per write, and two data files. The
second data file holds h41 alone, and nothing current uses it; it stays because version 2 does.
**Old versions are not free.** A table that is rewritten every night keeps every night's files until
you clean them up, which in this version of the library is `table.optimize(cleanup_older_than=...)`.
In return you get what the other stores of this lesson do not have: a way to look at the table as it
was before last night's import, and a reader that has opened one version is not disturbed by a
writer making the next.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three versions of the LanceDB table help, each a manifest listing data files. Version 1 lists data file A with 40 rows. Version 2, after an add, lists A and a new file B holding h41, 41 rows. Version 3, after the delete, lists A alone, 40 rows. File B stays on disk because version 2 still lists it.\"><defs><marker id=\"veen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">create</text><rect x=\"30\" y=\"36\" width=\"180\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">version 1</text><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40 rows</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after add</text><rect x=\"270\" y=\"36\" width=\"180\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">version 2</text><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">41 rows</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after delete</text><rect x=\"510\" y=\"36\" width=\"180\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">version 3</text><text x=\"600\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40 rows</text><rect x=\"150\" y=\"200\" width=\"180\" height=\"56\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">data file A</text><text x=\"240\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the 40 articles</text><rect x=\"420\" y=\"200\" width=\"180\" height=\"56\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"510\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">data file B</text><text x=\"510\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">h41 only</text><text x=\"510\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">kept while version 2 exists</text><path d=\"M120 90 L220 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#veen-ah0)\"></path><path d=\"M345 90 L250 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#veen-ah0)\"></path><path d=\"M375 90 L490 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#veen-ah0)\"></path><path d=\"M600 90 L270 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#veen-ah0)\"></path></svg>", "caption": "Each write made a version, and a version is a list of data files. The delete did not touch a file: it made version 3, which lists only the first one."}
```

For forty rows the search reads every vector. A large table gets an approximate index with
`table.create_index(...)`, built from the same families as FAISS's names, and lesson 15 is where
they are explained.
