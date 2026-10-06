#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py and answer.py live in ../../lab/code and
# build and search lesson 5's index, which the comparison at the end measures
# against. The other programs are written by `put`, and they import LangChain
# and LlamaIndex at the versions pinned in RAGLIBS in ../../lab.sh. Every
# embedding is all-MiniLM-L6-v2 through labembed, and every reply comes from
# extract-1, the lab's stand-in generator, which is not a language model
# (lab/labgen.py says what it does). Nothing here reaches a real provider: the
# address LlamaIndex would have used is printed, not called.
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
put lc_split.py <<'EOF_FILE'
import glob
import inspect

from langchain_text_splitters import RecursiveCharacterTextSplitter, TextSplitter

defaults = inspect.signature(TextSplitter.__init__).parameters
print({k: defaults[k].default for k in ("chunk_size", "chunk_overlap", "length_function")})
texts = [open(p).read() for p in sorted(glob.glob("data/docs/*.md"))]
for splitter in (RecursiveCharacterTextSplitter(), RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50)):
    chunks = splitter.create_documents(texts)
    words = sum(len(c.page_content.split()) for c in chunks) / len(chunks)
    print(f"{len(chunks):3} chunks, {words:3.0f} words on average")
print(chunks[0].page_content)
EOF_FILE
put lc_embed.py <<'EOF_FILE'
from langchain_openai import OpenAIEmbeddings

question = "How long is a gift card valid?"
try:
    OpenAIEmbeddings(model="lab-minilm").embed_query(question)
except Exception as e:
    print(type(e).__name__, e)
plain = OpenAIEmbeddings(model="lab-minilm", check_embedding_ctx_length=False)
print(len(plain.embed_query(question)), "dimensions")
EOF_FILE
put lc_load.py <<'EOF_FILE'
import glob
import hashlib
import sys

from langchain_core.documents import Document
from langchain_openai import OpenAIEmbeddings
from langchain_postgres import PGVector
from langchain_text_splitters import RecursiveCharacterTextSplitter

URL = "postgresql+psycopg:///rag?host=/run/emb-pg"
embeddings = OpenAIEmbeddings(model="lab-minilm", check_embedding_ctx_length=False)
store = PGVector(embeddings=embeddings, collection_name="docs", connection=URL)


def document(path):
    """The text after the front matter, with the front matter as metadata."""
    _, head, body = open(path).read().split("---\n", 2)
    meta = dict(line.split(": ", 1) for line in head.splitlines())
    return Document(page_content=body, metadata=meta)


docs = [document(p) for p in sorted(glob.glob("data/docs/*.md"))]
chunks = RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50).split_documents(docs)
ids = None
if "--ids" in sys.argv:
    ids = [c.metadata["id"] + ":" + hashlib.sha256(c.page_content.encode()).hexdigest()[:12] for c in chunks]
store.add_documents(chunks, ids=ids)
print(len(chunks), "chunks added")
EOF_FILE
put lc_search.py <<'EOF_FILE'
import sys

from langchain_openai import OpenAIEmbeddings
from langchain_postgres import PGVector

store = PGVector(embeddings=OpenAIEmbeddings(model="lab-minilm", check_embedding_ctx_length=False),
                 collection_name="docs", connection="postgresql+psycopg:///rag?host=/run/emb-pg")
for doc, score in store.similarity_search_with_score(sys.argv[1], k=3):
    print(f"{score:.3f}  {doc.metadata['id']:22} {doc.page_content[:40]!r}")
EOF_FILE
put lc_chain.py <<'EOF_FILE'
import sys

from answer import REFUSAL, SYSTEM
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_postgres import PGVector

store = PGVector(embeddings=OpenAIEmbeddings(model="lab-minilm", check_embedding_ctx_length=False),
                 collection_name="docs", connection="postgresql+psycopg:///rag?host=/run/emb-pg")
search = {"k": 3, "score_threshold": 0.5}
if "--all" not in sys.argv:
    search["filter"] = {"status": "current", "audience": "public"}
retriever = store.as_retriever(search_type="similarity_score_threshold", search_kwargs=search)
prompt = ChatPromptTemplate.from_messages([("system", SYSTEM), ("user", "{sources}\n\nQuestion: {question}")])
chain = prompt | ChatOpenAI(model="extract-1") | StrOutputParser()


def numbered(found):
    return "\n\n".join(f"[{n}] {d.metadata['title']} (updated {d.metadata['updated']})\n{d.page_content}"
                       for n, d in enumerate(found, 1))


question = sys.argv[-1]
found = retriever.invoke(question)
print(chain.invoke({"sources": numbered(found), "question": question}) if found else REFUSAL)
for n, d in enumerate(found, 1):
    print(f"  [{n}] {d.metadata['id']}, {d.metadata['status']}")
EOF_FILE
put li_where.py <<'EOF_FILE'
import os

from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI

print("OPENAI_BASE_URL is", os.environ["OPENAI_BASE_URL"])
print("OpenAIEmbedding will call", OpenAIEmbedding(model_name="lab-minilm").api_base)
try:
    OpenAI(model="extract-1").metadata
except ValueError as e:
    print("OpenAI(model='extract-1'):", str(e).split(".")[0])
EOF_FILE
put li_setup.py <<'EOF_FILE'
import os

from llama_index.core import Settings, SimpleDirectoryReader
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai_like import OpenAILike

BASE = os.environ["OPENAI_BASE_URL"]
Settings.embed_model = OpenAIEmbedding(model_name="lab-minilm", api_base=BASE)
Settings.llm = OpenAILike(model="extract-1", api_base=BASE, is_chat_model=True, context_window=8192)
docs = SimpleDirectoryReader("data/docs").load_data()
EOF_FILE
put li_ask.py <<'EOF_FILE'
import sys

from li_setup import docs
from llama_index.core import VectorStoreIndex
from llama_index.core.prompts.chat_prompts import CHAT_TEXT_QA_PROMPT

index = VectorStoreIndex.from_documents(docs)
nodes = list(index.docstore.docs.values())
print(len(docs), "documents,", len(nodes), "nodes,",
      round(sum(len(n.get_content().split()) for n in nodes) / len(nodes)), "words on average")
print("the system prompt it sends:")
print(CHAT_TEXT_QA_PROMPT.message_templates[0].content)
print()
engine = index.as_query_engine(similarity_top_k=3)
for question in sys.argv[1:]:
    print(">", question)
    print(engine.query(question).response)
EOF_FILE
put li_cite.py <<'EOF_FILE'
import sys

from li_setup import docs
from llama_index.core import VectorStoreIndex
from llama_index.core.query_engine import CitationQueryEngine

engine = CitationQueryEngine.from_args(VectorStoreIndex.from_documents(docs), similarity_top_k=3)
reply = engine.query(sys.argv[1])
print(reply.response)
for node in reply.source_nodes:
    print(" ", " ".join(node.node.get_content().split())[:64])
EOF_FILE
put li_window.py <<'EOF_FILE'
import sys

from li_setup import docs
from llama_index.core import VectorStoreIndex
from llama_index.core.node_parser import SentenceWindowNodeParser

nodes = SentenceWindowNodeParser.from_defaults(window_size=3).get_nodes_from_documents(docs)
hit = VectorStoreIndex(nodes).as_retriever(similarity_top_k=1).retrieve(sys.argv[1])[0]
print(len(nodes), "sentences indexed")
print("matched:", hit.node.get_content().strip())
print("window: ", " ".join(hit.node.metadata["window"].split()))
EOF_FILE
put li_merge.py <<'EOF_FILE'
import sys

from li_setup import docs
from llama_index.core import StorageContext, VectorStoreIndex
from llama_index.core.node_parser import HierarchicalNodeParser, get_leaf_nodes
from llama_index.core.retrievers import AutoMergingRetriever

nodes = HierarchicalNodeParser.from_defaults().get_nodes_from_documents(docs)
leaves = get_leaf_nodes(nodes)
storage = StorageContext.from_defaults()
storage.docstore.add_documents(nodes)
index = VectorStoreIndex(leaves, storage_context=storage)
print(len(nodes), "nodes,", len(leaves), "of them leaves")
for name, retriever in (("leaves", index.as_retriever(similarity_top_k=6)),
                        ("merged", AutoMergingRetriever(index.as_retriever(similarity_top_k=6), storage))):
    found = retriever.retrieve(sys.argv[1])
    print(f"{name}: {len(found)} returned, {sum(len(n.node.get_content().split()) for n in found)} words")
EOF_FILE
put frameworks.py <<'EOF_FILE'
import glob
import json

import tiktoken
from langchain_core.documents import Document
from langchain_core.vectorstores import InMemoryVectorStore
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from li_setup import docs
from llama_index.core import StorageContext, VectorStoreIndex
from llama_index.core.node_parser import HierarchicalNodeParser, SentenceWindowNodeParser, get_leaf_nodes
from llama_index.core.postprocessor import MetadataReplacementPostProcessor
from llama_index.core.retrievers import AutoMergingRetriever
from search import vector

enc = tiktoken.get_encoding("cl100k_base")
questions = [q for q in map(json.loads, open("data/eval.jsonl")) if q["facts"]]
norm = lambda t: " ".join(t.replace("|", " ").split())


def measure(name, retrieve):
    found, tokens = 0, 0
    for q in questions:
        top = retrieve(q["question"])
        found += any(f in norm(t) for t in top for f in q["facts"])
        tokens += len(enc.encode("\n".join(top)))
    print(f"{name:34} {found:3}/{len(questions)} {tokens / len(questions):7.0f}")


print(f"{'pipeline':34} {'found':>6} {'tokens':>7}")
texts = [Document(page_content=open(p).read()) for p in sorted(glob.glob("data/docs/*.md"))]
embeddings = OpenAIEmbeddings(model="lab-minilm", check_embedding_ctx_length=False)
for size, overlap in ((4000, 200), (400, 50)):
    store = InMemoryVectorStore(embeddings)
    store.add_documents(RecursiveCharacterTextSplitter(chunk_size=size, chunk_overlap=overlap).split_documents(texts))
    measure(f"LangChain, {size} characters", lambda q: [d.page_content for d in store.similarity_search(q, k=3)])

plain = VectorStoreIndex.from_documents(docs).as_retriever(similarity_top_k=3)
measure("LlamaIndex, defaults", lambda q: [n.node.get_content() for n in plain.retrieve(q)])

windows = VectorStoreIndex(SentenceWindowNodeParser.from_defaults(window_size=3).get_nodes_from_documents(docs))
sentence = windows.as_retriever(similarity_top_k=3)
widen = MetadataReplacementPostProcessor(target_metadata_key="window")
measure("LlamaIndex, sentences alone", lambda q: [n.node.get_content() for n in sentence.retrieve(q)])
measure("LlamaIndex, sentence window", lambda q: [n.node.get_content() for n in widen.postprocess_nodes(sentence.retrieve(q))])

nodes = HierarchicalNodeParser.from_defaults().get_nodes_from_documents(docs)
storage = StorageContext.from_defaults()
storage.docstore.add_documents(nodes)
leaves = VectorStoreIndex(get_leaf_nodes(nodes), storage_context=storage)
merging = AutoMergingRetriever(leaves.as_retriever(similarity_top_k=6), storage)
measure("LlamaIndex, auto-merging", lambda q: [n.node.get_content() for n in merging.retrieve(q)])

measure("lesson 5's index", lambda q: [r[2] for r in vector(q, 3)])
EOF_FILE

block split
on 'python lc_split.py | head -n 20'
block embed
on 'python lc_embed.py'
block load
on 'python lc_load.py'
on 'psql -c "\dt"'
on 'python lc_load.py'
on 'psql -Atc "SELECT count(*) FROM langchain_pg_embedding"'
on 'psql -qc "DELETE FROM langchain_pg_embedding"'
on 'python lc_load.py --ids'
on 'python lc_load.py --ids'
on 'psql -Atc "SELECT count(*) FROM langchain_pg_embedding"'
block search
on 'python lc_search.py "How long is a gift card valid?"'
block chain
on 'python lc_chain.py --all "How many days do I have to return a printed book?"'
on 'python lc_chain.py "How many days do I have to return a printed book?"'
on 'python lc_chain.py "Can I pay with cryptocurrency?"'
block where
on 'python li_where.py'
block ask
on 'python li_ask.py "How long is a gift card valid?" "How many days do I have to return a printed book?"'
block cite
on 'python li_cite.py "How long is a gift card valid?"'
block window
on 'python li_window.py "How much is express delivery?"'
block merge
on 'python li_merge.py "On how many devices can I read my e-books?"'
block measure
on 'python frameworks.py'
