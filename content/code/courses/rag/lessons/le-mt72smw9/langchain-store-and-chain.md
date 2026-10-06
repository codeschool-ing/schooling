---
title: A LangChain store and chain
version: 1
---

The store is `PGVector`, from `langchain-postgres`, on the same PostgreSQL and pgvector that
lesson 5's `chunks` table lives in. The loading program reads the front matter itself, splits at
the size the previous section chose, and hands the chunks over:

```schooling-example
{
  "language": "python",
  "file": "lc_load.py",
  "parts": [
    {
      "code": "import glob\nimport hashlib\nimport sys\n\nfrom langchain_core.documents import Document\nfrom langchain_openai import OpenAIEmbeddings\nfrom langchain_postgres import PGVector\nfrom langchain_text_splitters import RecursiveCharacterTextSplitter",
      "note": "LangChain's pieces: a document type, the OpenAI embedding client, the Postgres store and a splitter."
    },
    {
      "code": "URL = \"postgresql+psycopg:///rag?host=/run/emb-pg\"\nembeddings = OpenAIEmbeddings(model=\"lab-minilm\", check_embedding_ctx_length=False)\nstore = PGVector(embeddings=embeddings, collection_name=\"docs\", connection=URL)",
      "note": "The store is told which embedding client to use and which collection to fill. It creates its own tables on first use. `check_embedding_ctx_length=False` is the previous section's fix."
    },
    {
      "code": "def document(path):\n    \"\"\"The text after the front matter, with the front matter as metadata.\"\"\"\n    _, head, body = open(path).read().split(\"---\\n\", 2)\n    meta = dict(line.split(\": \", 1) for line in head.splitlines())\n    return Document(page_content=body, metadata=meta)",
      "note": "The front matter becomes metadata instead of text. The splitter would have left it at the top of the first chunk; reading it is the program's job."
    },
    {
      "code": "docs = [document(p) for p in sorted(glob.glob(\"data/docs/*.md\"))]\nchunks = RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50).split_documents(docs)\nids = None\nif \"--ids\" in sys.argv:\n    ids = [c.metadata[\"id\"] + \":\" + hashlib.sha256(c.page_content.encode()).hexdigest()[:12] for c in chunks]\nstore.add_documents(chunks, ids=ids)\nprint(len(chunks), \"chunks added\")",
      "note": "400 characters with 50 of overlap, about lesson 4's 60 words. With `--ids`, each chunk gets lesson 5's kind of id, its document and a hash of its text; without it, `ids` stays `None` and the store makes up its own."
    }
  ]
}
```

## A store that loads twice

```
ana@lab:~/rag$ python lc_load.py
126 chunks added
ana@lab:~/rag$ psql -c "\dt"
                List of relations
 Schema |          Name           | Type  | Owner 
--------+-------------------------+-------+-------
 public | chunks                  | table | ana
 public | langchain_pg_collection | table | ana
 public | langchain_pg_embedding  | table | ana
(3 rows)
ana@lab:~/rag$ python lc_load.py
126 chunks added
ana@lab:~/rag$ psql -Atc "SELECT count(*) FROM langchain_pg_embedding"
252
```

The store created **two tables of its own** beside lesson 5's: `langchain_pg_collection` names
collections, and `langchain_pg_embedding` holds every chunk's text, vector and metadata, the
metadata as one JSON column instead of lesson 5's typed columns. That is a schema somebody else
designed, and whatever reads it later (a report, an export, an erasure request) has to learn it.

Running the load a second time **doubled the table, to 252 rows**: each call to `add_documents`
gives every chunk a new random id unless it is given ids, so the same text went in twice. Every
search would now find two copies of the best chunk, with the same score, and fill two of its three places
with them. Lesson 5
solved this with ids built from the document and the text, and the store takes them:

```
ana@lab:~/rag$ psql -qc "DELETE FROM langchain_pg_embedding"
ana@lab:~/rag$ python lc_load.py --ids
126 chunks added
ana@lab:~/rag$ python lc_load.py --ids
126 chunks added
ana@lab:~/rag$ psql -Atc "SELECT count(*) FROM langchain_pg_embedding"
126
```

With ids, a second load writes over the first and the count stays at 126. What it still does not do
is notice a chunk that has gone: a document deleted from the corpus keeps its chunks in the store
until something deletes them. LangChain has an indexing API for that, `index()` with a record
manager, which keeps a table of the hashes it has loaded and removes the ones a new load no longer
has. It is lesson 5's comparison of wanted and existing ids, with another name and another table.

## A score that points the other way

```
ana@lab:~/rag$ python lc_search.py "How long is a gift card valid?"
0.253  gift-cards             '## Validity\n\nA gift card is valid for tw'
0.287  payments-and-invoices  'Gift cards are valid for two years from '
0.377  gift-cards             '## Using a gift card\n\nEach card has a si'
```

The best chunk scored **0.253, and the worst of the three 0.377**. These are **distances**, where
lower is better: pgvector's cosine distance, which is 1 minus the similarity lesson 6 printed. A
distance of 0.253 is a similarity of 0.747. Copy lesson 6's floor into this method as "keep scores
above 0.5" and it keeps exactly the chunks that should have been dropped.

The retriever, one layer up, turns the number back. Its `similarity_score_threshold` search
converts each distance into a relevance of 1 minus the distance before comparing it with the
threshold, so `score_threshold: 0.5` there is the same floor as lesson 6. Two methods of one library,
both calling their number a score, pointing in opposite directions. **Read what a number is before
you put a threshold on it.**

## The chain

The answering program uses lesson 7's instructions, lesson 6's filter and floor, and LangChain's way
of joining steps, the `|` of its expression language:

```schooling-example
{
  "language": "python",
  "file": "lc_chain.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import REFUSAL, SYSTEM\nfrom langchain_core.output_parsers import StrOutputParser\nfrom langchain_core.prompts import ChatPromptTemplate\nfrom langchain_openai import ChatOpenAI, OpenAIEmbeddings\nfrom langchain_postgres import PGVector",
      "note": "The instructions and the refusal sentence are lesson 7's, imported from `answer.py`, not LangChain's."
    },
    {
      "code": "store = PGVector(embeddings=OpenAIEmbeddings(model=\"lab-minilm\", check_embedding_ctx_length=False),\n                 collection_name=\"docs\", connection=\"postgresql+psycopg:///rag?host=/run/emb-pg\")\nsearch = {\"k\": 3, \"score_threshold\": 0.5}\nif \"--all\" not in sys.argv:\n    search[\"filter\"] = {\"status\": \"current\", \"audience\": \"public\"}\nretriever = store.as_retriever(search_type=\"similarity_score_threshold\", search_kwargs=search)\nprompt = ChatPromptTemplate.from_messages([(\"system\", SYSTEM), (\"user\", \"{sources}\\n\\nQuestion: {question}\")])\nchain = prompt | ChatOpenAI(model=\"extract-1\") | StrOutputParser()",
      "note": "`similarity_score_threshold` turns the distance into a relevance of 1 minus the distance before comparing it with 0.5, so this is lesson 6's floor. The filter is lesson 6's too, written as a dictionary that the store turns into a condition on its JSON column. The chain is three pieces joined by `|`: fill the prompt, call the model, take the text out of the reply."
    },
    {
      "code": "def numbered(found):\n    return \"\\n\\n\".join(f\"[{n}] {d.metadata['title']} (updated {d.metadata['updated']})\\n{d.page_content}\"\n                       for n, d in enumerate(found, 1))",
      "note": "Numbered sources with their title and date, as lesson 7's prompt has them."
    },
    {
      "code": "question = sys.argv[-1]\nfound = retriever.invoke(question)\nprint(chain.invoke({\"sources\": numbered(found), \"question\": question}) if found else REFUSAL)\nfor n, d in enumerate(found, 1):\n    print(f\"  [{n}] {d.metadata['id']}, {d.metadata['status']}\")",
      "note": "Nothing above the floor, no model call: lesson 7's refusal. The chain only runs when there is something to answer from."
    }
  ]
}
```

First without the filter, by passing `--all`, then with it:

```
ana@lab:~/rag$ python lc_chain.py --all "How many days do I have to return a printed book?"
You have 30 days from delivery to return a printed book in the condition you received it. [2] You may return a printed book within 14 days of delivery if it is unread and in the condition in which you received it. [1] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [3]
  [1] returns-policy-2025, superseded
  [2] returns-policy, current
  [3] returns-policy, current
ana@lab:~/rag$ python lc_chain.py "How many days do I have to return a printed book?"
You have 30 days from delivery to return a printed book in the condition you received it. [1] Our returns and refunds policy extends this period to 30 days for printed books. [3] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [2]
  [1] returns-policy, current
  [2] returns-policy, current
  [3] terms-of-sale, current
```

Without the filter, the second sentence of the reply, **14 days, comes from the 2025 policy**, which
the store holds because nothing told it otherwise; the reply cites it as [1], and its status says
`superseded`. With the filter, all three sources are current. The replies come from extract-1, the
lab's stand-in, which copies the source sentences closest to the question; a language model given
the same three sources would have the same two numbers in front of it.

```
ana@lab:~/rag$ python lc_chain.py "Can I pay with cryptocurrency?"
No relevant docs were retrieved using the relevance score threshold 0.5
I could not find that in our documents.
```

The first line of that output is LangChain's: a warning that **nothing passed the threshold**. The
second is the program's own refusal, sent without calling the model. A chain built only from `|`
would have called the model with no sources at all, and lesson 1 showed what a model says when it is
asked a question about Marginalia with nothing in front of it. The `if` at the end of the program is
lesson 7's decision, and LangChain did not make it.
