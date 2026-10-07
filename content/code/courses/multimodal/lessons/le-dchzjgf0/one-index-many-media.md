---
title: One index over an image and two recordings
version: 1
---

The `rag` course built retrieval over text. A shop's knowledge is not all text: invoices arrive as scans, complaints as calls, and the answer to "what did we pay for Bleak House" is in a picture. The usual way to search them together is to **turn each one into text first, and keep a pointer back to where every piece came from**.

```python
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
```

Tesseract reads the invoice into words with boxes, grouped into lines; Whisper reads each recording into timed segments. Every piece becomes a LangChain `Document` with its source and its place, and `InMemoryVectorStore` holds their vectors from all-MiniLM-L6-v2, which Ollama serves as `all-minilm` and the `MiniLM` class asks for through OpenAI's embeddings route:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three files on the left: invoice-0931.png, call-1042.wav and voicemail-pt.wav. Each is turned into text pieces by a different reader: Tesseract makes 19 lines, each with the box on the page it was read from; Whisper makes 11 segments of the call and 1 of the voicemail, each with its start and end in seconds. All 31 pieces go into one store of MiniLM vectors. A question finds a piece, and the piece&#x27;s locator leads back to a place in the original file: a box to highlight or a second to seek to.\"><defs><marker id=\"l12idx-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12idx-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">invoice-0931.png</text><text x=\"30\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tesseract</text><line x1=\"190\" y1=\"50\" x2=\"236\" y2=\"50\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-amber)\"></line><rect x=\"238\" y=\"20\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">text pieces</text><text x=\"248\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19 lines + a box each</text><line x1=\"428\" y1=\"50\" x2=\"476\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-wire)\"></line><rect x=\"20\" y=\"110\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">call-1042.wav</text><text x=\"30\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Whisper base</text><line x1=\"190\" y1=\"140\" x2=\"236\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-amber)\"></line><rect x=\"238\" y=\"110\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">text pieces</text><text x=\"248\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11 segments + seconds</text><line x1=\"428\" y1=\"140\" x2=\"476\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-wire)\"></line><rect x=\"20\" y=\"200\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">voicemail-pt.wav</text><text x=\"30\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Whisper base</text><line x1=\"190\" y1=\"230\" x2=\"236\" y2=\"230\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-amber)\"></line><rect x=\"238\" y=\"200\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">text pieces</text><text x=\"248\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 segment + seconds</text><line x1=\"428\" y1=\"230\" x2=\"476\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-wire)\"></line><rect x=\"478\" y=\"110\" width=\"220\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"488\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one store</text><text x=\"488\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31 MiniLM vectors</text><text x=\"488\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ source + locator</text><text x=\"478\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a hit leads back to the file:</text><text x=\"478\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">box 92,671,1148,689</text><text x=\"478\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">41.9-49.6 s</text></svg>", "caption": "The index holds text, but every piece remembers the place in an image or a recording it came from."}
```

```
ana@lab:~/mm$ python index.py "How much did one copy of Bleak House cost?" "Is the shipping refunded for a damaged book?" "Which customer wants a call back this afternoon?" "Quem pediu para ligar de volta no fim da tarde?"
31 pieces: {'invoice-0931.png': 19, 'call-1042.wav': 11, 'voicemail-pt.wav': 1}
How much did one copy of Bleak House cost?
  0.598  invoice-0931.png       box 92,671,1148,689    Bleak House 5 32.90 164.50
  0.398  invoice-0931.png       box 90,719,1148,737    The Secret Garden 10 15.90 159.00
Is the shipping refunded for a damaged book?
  0.802  call-1042.wav          41.9-49.6 s            Yes, for a damaged book we refund the full 3
  0.548  call-1042.wav          39.7-41.3 s            Will I get the shipping back as well?
Which customer wants a call back this afternoon?
  0.345  invoice-0931.png       box 951,98,1147,131    INVOICE
  0.312  call-1042.wav          39.7-41.3 s            Will I get the shipping back as well?
Quem pediu para ligar de volta no fim da tarde?
  0.527  voicemail-pt.wav       0.0-12.4 s             Oi, aqui é o Rafael Piente da Maginalia, sou
  0.479  invoice-0931.png       box 90,408,474,432     Av. Exemplo 1000, Sao Paulo SP
```

**The first two questions were found, and found exactly.** The Bleak House line scored 0.598 and comes with the box it was read from, so a screen can draw a rectangle on the invoice. The refund answer scored 0.802 and comes with 41.9 to 49.6 seconds, so a player can start there. That locator is the point of the design: **a hit that leads back to the original** lets a person check the OCR or the transcript against the thing itself.

**The third question was missed.** The voicemail asking for a call back is the only piece about it, and the English question's best match was the word INVOICE, at 0.345. all-MiniLM-L6-v2 was trained on English; the voicemail is in Portuguese, and so the two never met. Asked in Portuguese, the same index found the voicemail first, at 0.527. A shop with calls in two languages needs a multilingual embedding model, or a translation step before the index, and a test question in each language would have shown it on the first day.

The frameworks change nothing about this. LlamaIndex would hold the same pieces as `TextNode`s with the same metadata; the work that matters is the reader that makes the text and the locator that leads back.
