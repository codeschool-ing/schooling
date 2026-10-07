#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of multimodal, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: setup.sh from lesson 1, as ana
#   sudo bash captures.sh
#
# A line that starts with ana@lab:~/mm$ is what ana typed and what it printed.
# What is STAGED rather than typed, and not shown in the lesson: the lab itself
# (lab.sh reset) and the files ana wrote (put below), whose contents the lesson
# shows in full.
#
# EVERYTHING HERE IS REAL. The frameworks: langchain-core 1.6.6,
# langchain-openai 1.6.7, llama-index-core 0.14.25 and its OpenAI integrations,
# at the versions setup.sh pins. The replies about the cover are qwen2.5vl:3b's
# and the ticket is llama3.2:3b's, both through Ollama 0.40.0 at temperature 0
# and seed 1, taken on 2026-10-07. The transcripts are Whisper base's, through
# lesson 10's audio_server.py (lab.sh serve starts it from that lesson's
# fence), the OCR is Tesseract 5's, and the embeddings are all-MiniLM-L6-v2's,
# served by Ollama as all-minilm.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/mm, and what it printed.
on() { printf 'ana@lab:~/mm$ %s\n' "$*"; lab exec "$*" </dev/null 2>&1 || true; }
# put PATH: a file ana wrote in ~/mm, from stdin, which a fence in this lesson
# (or in $SHOWN, another lesson's .md) must show byte for byte.
put() {
  local tmp; tmp=$(mktemp)
  cat >"$tmp"
  python3 ../../lab/shown.py check ./*.md ${SHOWN:-} <"$tmp" || { echo "put $1: not shown" >&2; exit 1; }
  lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'" <"$tmp"
  rm -f "$tmp"
}
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/mm from nothing.
exec 9>/var/tmp/multimodal-capture.lock; flock 9
lab reset >/dev/null

put lc_cover.py <<'PY'
"""The cover, sent through LangChain twice: once in OpenAI's own block, once in LangChain's."""
import base64

from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI

data = base64.b64encode(open("media/cover-b39.png", "rb").read()).decode()
openai_block = {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{data}"}}
standard_block = {"type": "image", "base64": data, "mime_type": "image/png"}

llm = ChatOpenAI(model="qwen2.5vl:3b", temperature=0, seed=1)
for name, block in (("openai", openai_block), ("standard", standard_block)):
    message = HumanMessage(content=[{"type": "text", "text": "Describe this cover."}, block])
    sent = llm._get_request_payload([message])["messages"][0]["content"][1]   # what goes on the wire
    print(name, "->", sent["type"], sent["image_url"]["url"][:30])
    reply = llm.invoke([message])
    print("   ", reply.usage_metadata["input_tokens"], "tokens in:", reply.content[:60])
PY

put li_cover.py <<'PY'
"""The same cover through LlamaIndex: a ChatMessage made of blocks."""
import os
import sys

from llama_index.core.llms import ChatMessage, ImageBlock, TextBlock

message = ChatMessage(role="user", blocks=[TextBlock(text="Describe this cover."),
                                           ImageBlock(path="media/cover-b39.png")])
if sys.argv[1:] == ["openai"]:
    from llama_index.llms.openai import OpenAI
    llm = OpenAI(model="qwen2.5vl:3b")
else:
    from llama_index.llms.openai_like import OpenAILike
    print("default api_base:", OpenAILike(model="qwen2.5vl:3b").api_base)
    llm = OpenAILike(model="qwen2.5vl:3b", is_chat_model=True, api_base=os.environ["OPENAI_BASE_URL"])
reply = llm.chat([message])
print(reply.raw.usage.prompt_tokens, "tokens in:", reply.message.content[:60])
PY

put ticket.py <<'PY'
"""A recorded call to a support ticket: transcribe, then ask for fields, then check them."""
import re
import sys

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnableLambda
from langchain_openai import ChatOpenAI
from openai import OpenAI
from pydantic import BaseModel


class Ticket(BaseModel):
    order: str
    title: str
    problem: str
    refund_cents: int


def transcribe(path):
    with open(path, "rb") as f:
        return {"transcript": OpenAI(base_url="http://localhost:8700/v1").audio.transcriptions.create(
            model="whisper-base", file=f, response_format="text")}


prompt = ChatPromptTemplate.from_messages([
    ("system", "Turn this support call into a support ticket. Use only what the caller and agent say."),
    ("user", "{transcript}")])
llm = ChatOpenAI(model="qwen2.5vl:3b").with_structured_output(Ticket, method="json_schema")
chain = RunnableLambda(transcribe) | {"transcript": lambda x: x["transcript"],
                                      "ticket": prompt | llm}

out = chain.invoke(sys.argv[1])
ticket, heard = out["ticket"], out["transcript"]
print(ticket)

# The check the chain does not do: is every value the ticket states in what was heard?
def plain(s):
    return re.sub(r"[^0-9a-z]", "", s.lower())

print("order  in transcript:", plain(ticket.order) in plain(heard))
print("title  in transcript:", plain(ticket.title) in plain(heard))
PY

put index.py <<'PY'
"""One index over three kinds of file, each piece remembering where in its file it came from."""
import subprocess
import sys
from collections import Counter, defaultdict

from langchain_core.documents import Document
from langchain_core.embeddings import Embeddings
from langchain_core.vectorstores import InMemoryVectorStore
from openai import OpenAI


class MiniLM(Embeddings):
    """all-MiniLM-L6-v2, which Ollama serves as all-minilm, through OpenAI's embeddings route."""
    def embed_documents(self, texts):
        return [d.embedding for d in OpenAI().embeddings.create(model="all-minilm", input=texts).data]

    def embed_query(self, text):
        return self.embed_documents([text])[0]


def invoice_lines(path):
    """Tesseract's words, grouped into lines, each with the box it was read from."""
    tsv = subprocess.run(["tesseract", path, "-", "tsv"], capture_output=True, text=True).stdout
    lines = defaultdict(list)
    for row in tsv.splitlines()[1:]:
        f = row.split("\t")
        if f[0] == "5" and f[11].strip():
            lines[tuple(f[2:5])].append((int(f[6]), int(f[7]), int(f[6]) + int(f[8]), int(f[7]) + int(f[9]), f[11]))
    for words in lines.values():
        box = (min(w[0] for w in words), min(w[1] for w in words), max(w[2] for w in words), max(w[3] for w in words))
        yield Document(" ".join(w[4] for w in words), metadata={"source": path, "at": "box %d,%d,%d,%d" % box})


def call_segments(path):
    """Whisper's timed segments, each one a piece."""
    with open(path, "rb") as f:
        r = OpenAI(base_url="http://localhost:8700/v1").audio.transcriptions.create(model="whisper-base", file=f,
                                                                          response_format="verbose_json")
    for s in r.segments:
        yield Document(s.text.strip(), metadata={"source": path, "at": "%.1f-%.1f s" % (s.start, s.end)})


docs = list(invoice_lines("media/invoice-0931.png")) + list(call_segments("media/call-1042.wav")) \
    + list(call_segments("media/voicemail-pt.wav"))
store = InMemoryVectorStore.from_documents(docs, MiniLM())
print(len(docs), "pieces:", dict(Counter(d.metadata["source"].split("/")[1] for d in docs)))
for question in sys.argv[1:]:
    print(question)
    for doc, score in store.similarity_search_with_score(question, k=2):
        print("  %.3f  %-22s %-22s %s" % (score, doc.metadata["source"].split("/")[1], doc.metadata["at"], doc.page_content[:44]))
PY

block langchain
on 'python lc_cover.py'

block llamaindex
on 'python li_cover.py openai 2>&1 | tail -n 1 | cut -c1-120'
on 'python li_cover.py'

block ticket
lab serve audio
on 'python ticket.py media/call-1042.wav'

block index
on 'python index.py "How much did one copy of Bleak House cost?" "Is the shipping refunded for a damaged book?" "Which customer wants a call back this afternoon?" "Quem pediu para ligar de volta no fim da tarde?"'
lab down
