---
title: Um índice sobre uma imagem e duas gravações
version: 1
---

O curso `rag` construiu recuperação sobre texto. O conhecimento de uma loja não é todo texto: notas fiscais chegam como digitalizações, reclamações como ligações, e a resposta a "quanto pagamos pelo Bleak House" está numa imagem. O jeito comum de buscar tudo junto é **transformar cada coisa em texto antes, e guardar um ponteiro para o lugar de onde cada pedaço veio**.

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

O Tesseract lê a nota em palavras com caixas, agrupadas em linhas; o Whisper lê cada gravação em segmentos com tempo. Cada pedaço vira um `Document` do LangChain com a origem e o lugar, e o `InMemoryVectorStore` guarda os vetores deles do all-MiniLM-L6-v2, que o Ollama serve como `all-minilm` e que a classe `MiniLM` pede pela rota de embeddings da OpenAI:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três arquivos à esquerda: invoice-0931.png, call-1042.wav e voicemail-pt.wav. Cada um vira pedaços de texto por um leitor diferente: o Tesseract faz 19 linhas, cada uma com a caixa da página de onde foi lida; o Whisper faz 11 segmentos da ligação e 1 do recado, cada um com início e fim em segundos. Os 31 pedaços entram num só depósito de vetores do MiniLM. Uma pergunta acha um pedaço, e o localizador do pedaço leva de volta a um lugar no arquivo original: uma caixa para destacar ou um segundo para onde pular.\"><defs><marker id=\"l12idx-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12idx-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">invoice-0931.png</text><text x=\"30\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tesseract</text><line x1=\"190\" y1=\"50\" x2=\"236\" y2=\"50\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-amber)\"></line><rect x=\"238\" y=\"20\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedaços de texto</text><text x=\"248\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19 linhas + uma caixa cada</text><line x1=\"428\" y1=\"50\" x2=\"476\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-wire)\"></line><rect x=\"20\" y=\"110\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">call-1042.wav</text><text x=\"30\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Whisper base</text><line x1=\"190\" y1=\"140\" x2=\"236\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-amber)\"></line><rect x=\"238\" y=\"110\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedaços de texto</text><text x=\"248\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11 segmentos + segundos</text><line x1=\"428\" y1=\"140\" x2=\"476\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-wire)\"></line><rect x=\"20\" y=\"200\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">voicemail-pt.wav</text><text x=\"30\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Whisper base</text><line x1=\"190\" y1=\"230\" x2=\"236\" y2=\"230\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-amber)\"></line><rect x=\"238\" y=\"200\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedaços de texto</text><text x=\"248\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 segmento + segundos</text><line x1=\"428\" y1=\"230\" x2=\"476\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l12idx-ah-wire)\"></line><rect x=\"478\" y=\"110\" width=\"220\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"488\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um só depósito</text><text x=\"488\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31 vetores do MiniLM</text><text x=\"488\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ origem + localizador</text><text x=\"478\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um acerto leva de volta ao arquivo:</text><text x=\"478\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">box 92,671,1148,689</text><text x=\"478\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">41.9-49.6 s</text></svg>", "caption": "O índice guarda texto, mas cada pedaço lembra o lugar numa imagem ou numa gravação de onde veio.", "same": ["Tesseract", "Whisper base"]}
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

**As duas primeiras perguntas foram achadas, e com precisão.** A linha do Bleak House teve 0,598 e vem com a caixa de onde foi lida, então uma tela pode desenhar um retângulo na nota. A resposta sobre o reembolso teve 0,802 e vem com 41,9 a 49,6 segundos, então um player pode começar ali. Esse localizador é o ponto do desenho: **um acerto que leva de volta ao original** deixa uma pessoa conferir o OCR ou a transcrição contra a coisa em si.

**A terceira pergunta errou.** O recado pedindo retorno é o único pedaço sobre isso, e a melhor resposta para a pergunta em inglês foi a palavra INVOICE, com 0,345. O all-MiniLM-L6-v2 foi treinado em inglês; o recado está em português, e por isso os dois nunca se encontraram. Perguntado em português, o mesmo índice achou o recado em primeiro, com 0,527. Uma loja com ligações em duas línguas precisa de um modelo de embeddings multilíngue, ou de um passo de tradução antes do índice, e uma pergunta de teste em cada língua teria mostrado isso no primeiro dia.

Os frameworks não mudam nada disso. O LlamaIndex guardaria os mesmos pedaços como `TextNode`s com os mesmos metadados; o trabalho que importa é o leitor que faz o texto e o localizador que leva de volta.
