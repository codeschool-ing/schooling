---
title: Who runs it, and who pays
version: 1
---

It is tempting to compare vector databases by speed, and at Marginalia's size that comparison has
nothing to measure: forty articles are few enough for any of them to search, or for the NumPy line
of lesson 3. **The question that decides is where the database runs and who keeps it running**, and
the three products of this lesson answer it in three different ways.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three ways a vector database runs. In your process: one box, your program, holds your code and the Chroma library, which reads and writes the chroma directory on the same machine. On a server you run: your programs reach a server process, chroma run or Weaviate, over HTTP, and the server owns the files; all of it is inside the boundary of machines you operate. On the provider's machines: your program sends HTTPS requests with an API key across the boundary to a service such as Pinecone, Weaviate Cloud or Chroma Cloud, which you do not operate.\"><defs><marker id=\"shen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">in your process</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"250\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what you operate</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"130\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your program</text><rect x=\"55\" y=\"95\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your code</text><rect x=\"55\" y=\"140\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Chroma (library)</text><path d=\"M120 170 L120 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shen-ah0)\"></path><rect x=\"55\" y=\"222\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">chroma/ directory</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">on a server you run</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"250\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what you operate</text><rect x=\"280\" y=\"60\" width=\"160\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your programs</text><path d=\"M360 100 L360 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shen-ah0)\"></path><text x=\"368\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP</text><rect x=\"280\" y=\"140\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">server process</text><text x=\"360\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chroma run · Weaviate</text><path d=\"M360 190 L360 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shen-ah0)\"></path><rect x=\"295\" y=\"222\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">its files</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">on the provider's machines</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"80\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"600\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what you operate</text><rect x=\"520\" y=\"52\" width=\"160\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your program</text><path d=\"M600 84 L600 149\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shen-ah0)\"></path><text x=\"608\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTPS + API key</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"140\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"600\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">what they operate</text><rect x=\"520\" y=\"168\" width=\"160\" height=\"84\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the service</text><text x=\"600\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Pinecone</text><text x=\"600\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Weaviate Cloud</text><text x=\"600\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Chroma Cloud</text></svg>", "caption": "Three places a vector database can run. Everything inside a grey dashed line is yours to deploy, back up and restart; in the third shape the database sits inside the provider's line instead."}
```

**In your process**, the database is a library and a directory. Chroma's `PersistentClient` is
this shape. Nothing to deploy and nothing to connect to; the price is that one program owns the
files, and the database is only as available as that program and that disk. Backups are a copy of
the directory, made while nothing writes to it.

**On a server you run**, the database is a process that several programs reach over the network:
`chroma run`, or Weaviate in a container. Many clients can share one copy, and the server can live
on a machine sized for it. You now operate it: upgrades, restarts, disk space, backups and
monitoring are yours.

**On the provider's machines**, the database is an API with a key. Pinecone is only this shape;
Chroma Cloud and Weaviate Cloud offer it beside their open-source versions. Nobody on your side
operates anything, the index grows without you, and the bill grows with it. Your articles and their
vectors leave your machines. Lesson 1 said that a vector of a customer's message is personal data
like the message, so this is a contract and a privacy question before it is a technical one.

## Side by side

| | Chroma | Pinecone | Weaviate |
|---|---|---|---|
| where it runs | in your process, a server you run, or Chroma Cloud | Pinecone's service | a server you run, Weaviate Cloud, or embedded by the client |
| source | open source | a commercial service | open source |
| who embeds | the client, with a default model, or you | you, or an index tied to one of Pinecone's models | you, or a vectorizer module on the server |
| fixed at creation | the space | the dimension and the metric | the properties' types and the vector index's metric |
| what a query returns | a distance | a score, highest first for cosine | a distance |
| filters | `where` on metadata, `where_document` on text | a metadata filter, and namespaces | `Filter` on typed properties |
| keyword and vector together | not used in this lesson | not used in this lesson | `query.hybrid` with `alpha` |
| what you pay for | your machines, or Chroma Cloud | what you store, read and write | your machines, or Weaviate Cloud |

Read the table as a list of questions to ask any vector database, not as a ranking: these three
change often, and you will check the row that matters most to you against the current documentation
anyway.

## For Marginalia

The help centre is forty articles and one program. A Chroma directory beside that program does the
job, and the day the shop runs several web servers, `chroma run` serves the same directory without
a line of the search code changing. A hosted service starts to pay for itself when the collection is
large, the traffic is uneven, and nobody on the team wants to be woken up by a database. None of
those is true at Marginalia yet.

Two more shapes are left. Lesson 13 meets FAISS, a library that is only an index; LanceDB, an
embedded database that keeps its data in columnar files; and Qdrant. Lesson 14 puts the vectors in
PostgreSQL, the database a shop like this one is probably running already.
