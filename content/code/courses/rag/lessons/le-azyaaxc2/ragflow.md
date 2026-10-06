---
title: RAGFlow, a pipeline you deploy
version: 1
---

The three libraries so far are code a team imports. **RAGFlow is an application a team runs.** It
is an open-source retrieval engine under the Apache 2.0 licence, maintained by InfiniFlow, and it
comes as a set of servers: a web interface where people upload documents and chat with them, an
API for programs, and the storage behind both. This course does not run it, and the reason is part
of the lesson: its README in October 2026 recommends starting with 4 CPU cores, 16 GB of memory
and 50 GB of disk, with Docker, and the stack it starts includes a search engine (Elasticsearch, or
InfiniFlow's own Infinity), MySQL, MinIO for files, and a message queue and a cache beside them.
That is more machine than this lab, and more machinery than a team adds without deciding to.

What follows is what the project says it does, and what each claim means against the decisions
this course has made by hand. Everything here moves faster than the rest of the course; check it
against the current documentation before relying on any of it.

## What it is built around

**Parsing hard documents.** RAGFlow's part called DeepDoc does layout analysis, OCR and table
recognition. That is the problem this course could leave aside, because Marginalia's documents are
Markdown that a program can read line by line. A real corpus is often PDFs with two columns, scanned
contracts and spreadsheets pasted as images, and the text a parser pulls out of those is the text
every later step works on. A table read as a stream of cells, or a footnote read into the middle of
a paragraph, cannot be repaired by any chunk size.

**Chunking by template.** Instead of one splitter with a size, a dataset in RAGFlow is configured
with a template for its kind of document, among them papers, books, laws, Q&A pairs and tables.
Each template encodes what lesson 4 had to work out: a law is cut by its articles, a table by its
rows, a list of questions and answers by its pairs. It is lesson 4's "follow the document's own
structure", decided per kind of document by people who looked at many of them.

**Chunks a person can see and correct.** The interface shows how each document was cut and lets a
person edit a chunk, add keywords to it, or switch it off. Lesson 5 changed the index only by
re-running a program on the source files; here a person can change the index directly. That fixes a
bad chunk in a minute, and it also means the index is no longer derived only from the documents,
so the next re-parse of that document has to keep the edit or lose it.

**Answers with their references.** A reply in the chat shows which chunks it drew on, and the person
reading can open them. That is lesson 7's citation, built into the screen.

## What it changes for the team

Everything in the earlier lessons of this course still applies, and some of it moves somewhere else:

- **The corpus lives in another system.** Documents, chunks and vectors sit in RAGFlow's storage,
  not in the team's database. Lesson 14's question, which documents may this person see, has to be
  answered inside RAGFlow's own model of users and datasets, and an erasure request has to reach it.
- **The test still belongs to the team.** RAGFlow's API answers questions, so lesson 8's
  `eval.jsonl` can be run against it from outside, the same way `frameworks.py` measured two
  libraries. Nothing about a product with a screen makes its retrieval right for your documents.
- **An upgrade is a deployment.** A library upgrade changes a lock file; an application upgrade
  changes a running service, its storage format and possibly its parsing, which is to say every
  chunk. Re-run the test after it as after anything else.

RAGFlow fits a team whose documents are the hard part, PDFs, scans and tables, and whose users are
not developers: support staff who need to upload a manual and ask it questions this afternoon. It
fits less well where the pipeline is a part of a product, behind the product's own permissions and
inside its own database, which is the case this course has been building.
