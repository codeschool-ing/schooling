#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py and search.py live in ../../lab/code and build and
# search lesson 5's index, which the comparison measures against; answer.py
# gives the instructions and the refusal. The other programs are written by
# `put` and import Haystack at the version pinned in RAGLIBS in ../../lab.sh.
# Every embedding is all-MiniLM-L6-v2 through labembed, and every reply comes
# from extract-1, the lab's stand-in generator, which is not a language model
# (lab/labgen.py says what it does). RAGFlow, the lesson's other subject, is a
# server application of its own and is described, not run.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
use chunking.py ingest.py search.py answer.py
lab exec 'python ingest.py' >/dev/null
put hs_docs.py <<'EOF_FILE'
import glob

from haystack import Document


def document(path):
    """The text after the front matter, with the front matter as metadata."""
    _, head, body = open(path).read().split("---\n", 2)
    return Document(content=body, meta=dict(line.split(": ", 1) for line in head.splitlines()))


docs = [document(p) for p in sorted(glob.glob("data/docs/*.md"))]
EOF_FILE
put hs_index.py <<'EOF_FILE'
import sys

from haystack import Pipeline
from haystack.components.embedders import OpenAIDocumentEmbedder
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.writers import DocumentWriter
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.document_stores.types import DuplicatePolicy
from hs_docs import docs

store = InMemoryDocumentStore()
policy = DuplicatePolicy.OVERWRITE if "--overwrite" in sys.argv else DuplicatePolicy.NONE
indexing = Pipeline()
indexing.add_component("split", DocumentSplitter(split_by="word", split_length=60))
indexing.add_component("embed", OpenAIDocumentEmbedder(model="lab-minilm", progress_bar=False))
indexing.add_component("write", DocumentWriter(store, policy=policy))
indexing.connect("split", "embed")
indexing.connect("embed", "write")


def load(documents):
    try:
        print("written:", indexing.run({"split": {"documents": documents}})["write"]["documents_written"])
    except Exception as e:
        print(type(e).__name__ + ":", [line for line in str(e).splitlines() if line.startswith("Error:")][0][:110])


load(docs)
load(docs)
docs[7].meta["owner"] = "customer-service"
load(docs[7:8])
print("in the store:", store.count_documents())
store.save_to_disk("store.json")
EOF_FILE
put hs_floor.py <<'EOF_FILE'
from answer import REFUSAL
from haystack import Document, component


@component
class Floor:
    """Pass on the documents that reach lesson 6's floor, or the refusal if none does."""

    def __init__(self, floor: float = 0.5):
        self.floor = floor

    @component.output_types(documents=list[Document], refusal=str)
    def run(self, documents: list[Document]):
        kept = [d for d in documents if d.score >= self.floor]
        return {"documents": kept} if kept else {"refusal": REFUSAL}
EOF_FILE
put hs_ask.py <<'EOF_FILE'
import sys

from answer import SYSTEM
from haystack import Pipeline
from haystack.components.builders import ChatPromptBuilder
from haystack.components.embedders import OpenAITextEmbedder
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.dataclasses import ChatMessage
from haystack.document_stores.in_memory import InMemoryDocumentStore
from hs_floor import Floor

store = InMemoryDocumentStore.load_from_disk("store.json")
public = {"operator": "AND", "conditions": [
    {"field": "meta.status", "operator": "==", "value": "current"},
    {"field": "meta.audience", "operator": "==", "value": "public"}]}
sources = ("{% for d in documents %}[{{ loop.index }}] {{ d.meta.title }} (updated {{ d.meta.updated }})\n"
           "{{ d.content }}\n\n{% endfor %}Question: {{ question }}")

rag = Pipeline()
rag.add_component("embed", OpenAITextEmbedder(model="lab-minilm"))
rag.add_component("retrieve", InMemoryEmbeddingRetriever(store, top_k=3, filters=public))
rag.add_component("floor", Floor(0.5))
rag.add_component("prompt", ChatPromptBuilder(template=[ChatMessage.from_system(SYSTEM),
                                                        ChatMessage.from_user(sources)],
                                              required_variables=["documents", "question"]))
rag.add_component("generate", OpenAIChatGenerator(model="extract-1"))
rag.connect("embed.embedding", "retrieve.query_embedding")
rag.connect("retrieve", "floor")
rag.connect("floor.documents", "prompt.documents")
rag.connect("prompt", "generate")

if __name__ == "__main__":
    question = sys.argv[1]
    out = rag.run({"embed": {"text": question}, "prompt": {"question": question}},
                  include_outputs_from={"retrieve"})
    print(out["generate"]["replies"][0].text if "generate" in out else out["floor"]["refusal"])
    for d in out["retrieve"]["documents"]:
        print(f"  {d.score:.3f}  {d.meta['id']}")
EOF_FILE
put hs_wrong.py <<'EOF_FILE'
from haystack import Pipeline
from haystack.components.embedders import OpenAITextEmbedder
from haystack.components.generators.chat import OpenAIChatGenerator

p = Pipeline()
p.add_component("embed", OpenAITextEmbedder(model="lab-minilm"))
p.add_component("generate", OpenAIChatGenerator(model="extract-1"))
try:
    p.connect("embed.embedding", "generate.messages")
except Exception as e:
    print(type(e).__name__ + ":", " ".join(str(e).split()))
EOF_FILE
put hs_dump.py <<'EOF_FILE'
from hs_ask import rag

print(rag.dumps())
EOF_FILE
put hs_measure.py <<'EOF_FILE'
import json

import tiktoken
from haystack.components.embedders import OpenAIDocumentEmbedder, OpenAITextEmbedder
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore
from hs_docs import docs
from search import vector

enc = tiktoken.get_encoding("cl100k_base")
questions = [q for q in map(json.loads, open("data/eval.jsonl")) if q["facts"]]
norm = lambda t: " ".join(t.replace("|", " ").split())
query = OpenAITextEmbedder(model="lab-minilm")


def measure(name, retrieve):
    found, tokens = 0, 0
    for q in questions:
        top = retrieve(q["question"])
        found += any(f in norm(t) for t in top for f in q["facts"])
        tokens += len(enc.encode("\n".join(top)))
    print(f"{name:30} {found:3}/{len(questions)} {tokens / len(questions):7.0f}")


print(f"{'pipeline':30} {'found':>6} {'tokens':>7}")
for name, splitter in (("Haystack, defaults", DocumentSplitter()),
                       ("Haystack, 60 words", DocumentSplitter(split_by="word", split_length=60)),
                       ("Haystack, passages", DocumentSplitter(split_by="passage", split_length=1))):
    store = InMemoryDocumentStore()
    chunks = splitter.run(documents=docs)["documents"]
    store.write_documents(OpenAIDocumentEmbedder(model="lab-minilm", progress_bar=False).run(chunks)["documents"])
    retriever = InMemoryEmbeddingRetriever(store, top_k=3)
    measure(name, lambda q: [d.content for d in retriever.run(query.run(q)["embedding"])["documents"]])
measure("lesson 5's index", lambda q: [r[2] for r in vector(q, 3)])
EOF_FILE

block index
on 'python hs_index.py'
on 'python hs_index.py --overwrite'
block ask
on 'python hs_ask.py "How many days do I have to return a printed book?"'
on 'python hs_ask.py "Can I pay with cryptocurrency?"'
block wrong
on 'python hs_wrong.py'
block dump
on 'python hs_dump.py > rag.yaml; wc -l rag.yaml'
on 'head -n 18 rag.yaml'
on 'grep -n -A 11 "      filters:" rag.yaml'
on 'sed -n "/^connections:/,\$p" rag.yaml'
block measure
on 'python hs_measure.py'
