---
title: Encolhendo os vetores
version: 1
---

Se o tamanho é dimensões vezes quatro bytes, há dois jeitos de diminuí-lo: **menos números**, ou
**menos bytes por número**. A suposição comum é que a busca piora na proporção do que se tira, de
modo que metade dos bytes custaria metade da qualidade. Não é assim, e os dois jeitos não se
equivalem: medidos nos mesmos textos, um sai quase de graça por um bom trecho e o outro cobra a
cada passo.

## Quatro formas dos mesmos vetores

A aula 8 apresentou vetores int8 e binários como algo que um provedor pode devolver, e a aula 15
mediu os quantizadores do FAISS dentro de um índice. Aqui eles aparecem lado a lado com o simples
corte de dimensões, nos textos do próprio curso:

```schooling-example
{
  "language": "python",
  "file": "shrink.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nrows = lambda f: [json.loads(l) for l in open(f\"data/{f}.jsonl\")]\nhelp, queries = rows(\"help\"), rows(\"queries\")\nids = [h[\"id\"] for h in help]\narticles = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nasked = [q[\"text\"] for q in queries]\nothers = [b[\"title\"] + \". \" + b[\"blurb\"] for b in rows(\"books\")] + [t[\"text\"] for t in rows(\"tickets\")]",
      "note": "Os textos: os 40 artigos, as 24 perguntas julgadas e todas as sinopses de livros e tickets, para que a comparação de vizinhos tenha muito mais linhas que as perguntas sozinhas."
    },
    {
      "code": "def forms(X):\n    yield \"float32\", X, X.nbytes\n    h = X.astype(np.float16)\n    yield \"float16\", h.astype(np.float32), h.nbytes\n    s = (np.abs(X).max(axis=1, keepdims=True) / 127).astype(np.float32)\n    q = np.round(X / s).astype(np.int8)\n    yield \"int8\", q * s, q.nbytes + s.nbytes\n    b = np.packbits(X > 0, axis=1)\n    yield \"binary\", np.where(X > 0, 1.0, -1.0), b.nbytes",
      "note": "Quatro jeitos de guardar os mesmos vetores. Cada um devolve o que a busca compararia e quantos bytes custa. O int8 guarda uma escala float32 por vetor, e os bytes a incluem."
    },
    {
      "code": "def recall(D, Q):\n    tops = [[ids[i] for i in np.argsort(-(D @ q), kind=\"stable\")[:3]] for q in Q]\n    r1 = sum(t[0] in q[\"relevant\"] for t, q in zip(tops, queries))\n    r3 = sum(any(i in q[\"relevant\"] for i in t) for t, q in zip(tops, queries))\n    return r1, r3\n\ndef top10(E):\n    S = E @ E.T\n    np.fill_diagonal(S, -np.inf)\n    return np.argsort(-S, axis=1, kind=\"stable\")[:, :10]",
      "note": "Duas medidas. `recall` é a da aula 3: das 24 perguntas, quantas acham um artigo certo em primeiro lugar e entre os três primeiros. `top10` lista os dez vizinhos mais próximos de cada texto entre os outros."
    },
    {
      "code": "def report(model, X, full):\n    exact = top10(full)\n    n = len(articles) + len(asked)\n    for form, E, size in forms(X):\n        r1, r3 = recall(E[:len(articles)], E[len(articles):n])\n        mine = top10(E)\n        kept = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(mine, exact)])\n        print(f\"{model:14} {form:8} {size // len(X):5} B  r@1 {r1:2}/24  r@3 {r3:2}/24  \"\n              f\"top-10 kept {kept:.3f}\")",
      "note": "Para cada forma, o recall e a fração dos dez vizinhos mais próximos de cada texto que continuam sendo os vizinhos que os vetores float32 completos davam."
    },
    {
      "code": "texts = articles + asked + others\nM = embed(texts)\nreport(\"minilm 384\", M, M)\nwl = WordLlama.load()\nW = wl.embed(texts, norm=True)\nreport(\"wordllama 256\", W, W)\nfor k in (128, 64):\n    Wk = W[:, :k] / np.linalg.norm(W[:, :k], axis=1, keepdims=True)\n    report(f\"wordllama {k}\", Wk, W)",
      "note": "O MiniLM no tamanho cheio, depois o WordLlama com 256 dimensões e cortado para 128 e 64, renormalizado. Os cortados são comparados com os 256 completos."
    }
  ]
}
```

```
ana@lab:~/emb$ python shrink.py
minilm 384     float32   1536 B  r@1 19/24  r@3 22/24  top-10 kept 1.000
minilm 384     float16    768 B  r@1 19/24  r@3 22/24  top-10 kept 1.000
minilm 384     int8       388 B  r@1 19/24  r@3 22/24  top-10 kept 0.995
minilm 384     binary      48 B  r@1 16/24  r@3 23/24  top-10 kept 0.705
wordllama 256  float32   1024 B  r@1 20/24  r@3 24/24  top-10 kept 1.000
wordllama 256  float16    512 B  r@1 20/24  r@3 24/24  top-10 kept 0.999
wordllama 256  int8       260 B  r@1 20/24  r@3 24/24  top-10 kept 0.995
wordllama 256  binary      32 B  r@1 15/24  r@3 21/24  top-10 kept 0.600
wordllama 128  float32    512 B  r@1 17/24  r@3 23/24  top-10 kept 0.772
wordllama 128  float16    256 B  r@1 17/24  r@3 23/24  top-10 kept 0.772
wordllama 128  int8       132 B  r@1 17/24  r@3 23/24  top-10 kept 0.773
wordllama 128  binary      16 B  r@1 13/24  r@3 19/24  top-10 kept 0.492
wordllama 64   float32    256 B  r@1 20/24  r@3 21/24  top-10 kept 0.642
wordllama 64   float16    128 B  r@1 20/24  r@3 21/24  top-10 kept 0.642
wordllama 64   int8        68 B  r@1 20/24  r@3 21/24  top-10 kept 0.643
wordllama 64   binary       8 B  r@1 11/24  r@3 20/24  top-10 kept 0.391
```

O programa mede duas coisas, e você precisa das duas. `r@1` e `r@3` são o recall da aula 3 nas 24
perguntas julgadas: o número que importa, medido numa amostra pequena demais para mostrar uma
mudança pequena. `top-10 kept` é um instrumento mais fino. Ele pega cada texto do conjunto (os artigos, as
perguntas, as 60 sinopses de livros e os 150 tickets) e pergunta quantos dos dez vizinhos mais
próximos com os vetores `float32` completos continuam entre os dez mais próximos depois da mudança.

## Menos bytes por número

**O float16 corta o tamanho pela metade e não muda nada.** O MiniLM com 768 bytes mantém 1,000 dos
vizinhos, o WordLlama com 512 mantém 0,999, e os dois respondem às 24 perguntas exatamente como
antes.

**O int8 divide por quatro em troca de meio por cento.** São 388 e 260 bytes, contando a escala
`float32` que cada vetor guarda, e 0,995 dos vizinhos mantidos nos dois modelos. As respostas às 24
perguntas não mudaram em nenhum dos dois.

**O binário tem um trinta e dois avos do tamanho e uma vizinhança diferente.** Um bit por número, 48
bytes no MiniLM e 32 no WordLlama, mantém 0,705 e 0,600 dos vizinhos. Mesmo assim o `r@3` do MiniLM
foi de 22/24 para 23/24 em binário. Isso não quer dizer que o binário é melhor: quer dizer que 24
perguntas são poucas demais para enxergar uma mudança em que quase um terço dos vizinhos trocou, e é
por isso que o programa carrega a segunda medida.

## Menos números

O WordLlama é treinado para que as primeiras dimensões carreguem mais, e é isso que torna razoável
cortá-lo: pegue as k primeiras e divida pelo novo comprimento. Mesmo assim, **cortar para 128
dimensões mantém 0,772 dos vizinhos, e 64 mantém 0,642**, contra as 256 completas.

Agora compare com o mesmo tamanho. O WordLlama cortado em 64 dimensões em `float32` tem 256 bytes e
mantém 0,642. O WordLlama com as 256 dimensões completas em `int8` tem 260 bytes e mantém 0,995.
**Com o mesmo número de bytes, menos bits por número ganham de menos números** com folga, neste
modelo e nestes textos. O corte ainda tem seu uso: é o único encolhimento que funciona num sistema
que só guarda `float32`. O pgvector do laboratório é um deles: o 0.6.0 não tem tipo menor, então
no Postgres daqui a única alavanca é a dimensão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"Um gráfico de bytes por vetor, numa escala que dobra de 8 a 2048, contra a fração dos dez vizinhos mais próximos de cada texto que continuam os mesmos. O all-MiniLM-L6-v2 e o WordLlama com 256 dimensões guardam quase todos os vizinhos em float16 e int8 e caem para 0,705 e 0,600 em binário. O WordLlama cortado para 128 e 64 dimensões guarda só 0,772 e 0,642 mesmo em float32, então, perto de 256 bytes, um vetor int8 de 256 dimensões guarda muito mais que um float32 de 64.\"><path d=\"M80 350 L690 350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 350 L80 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 350 L80 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><path d=\"M230 350 L230 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><path d=\"M380 350 L380 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">128</text><path d=\"M530 350 L530 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">512</text><path d=\"M680 350 L680 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2048</text><path d=\"M75 328.6 L80 328.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"328.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M75 242.9 L80 242.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"242.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M75 157.1 L80 157.1\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"157.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M75 71.4 L80 71.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"71.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"385\" y=\"392\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bytes por vetor</text><text x=\"84\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vizinhos do top-10 mantidos</text><path d=\"M648.9 71.4 L573.9 71.4 L500.0 73.6 L273.9 197.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"648.9\" cy=\"71.4\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"648.9\" y=\"87.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f32</text><circle cx=\"573.9\" cy=\"71.4\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"573.9\" y=\"87.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f16</text><circle cx=\"500\" cy=\"73.6\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"500\" y=\"89.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">int8</text><circle cx=\"273.9\" cy=\"197.9\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"283.9\" y=\"197.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bin</text><path d=\"M605.0 71.4 L530.0 71.9 L456.7 73.6 L230.0 242.9\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"600\" y=\"66.4\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"57.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f32</text><rect x=\"525\" y=\"66.9\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"57.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f16</text><rect x=\"451.7\" y=\"68.6\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"456.7\" y=\"59.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">int8</text><rect x=\"225\" y=\"237.9\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"228.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bin</text><path d=\"M530.0 169.1 L455.0 169.1 L383.3 168.7 L155.0 289.1\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"530\" cy=\"169.1\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><circle cx=\"455\" cy=\"169.1\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><circle cx=\"383.3\" cy=\"168.7\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><circle cx=\"155\" cy=\"289.1\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><path d=\"M455.0 224.9 L380.0 224.9 L311.6 224.4 L80.0 332.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"455\" cy=\"224.9\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"380\" cy=\"224.9\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"311.6\" cy=\"224.4\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"80\" cy=\"332.4\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"470\" cy=\"252\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"484\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2, 384</text><rect x=\"465\" y=\"269\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama, 256</text><circle cx=\"470\" cy=\"296\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><text x=\"484\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama cortado em 128</text><circle cx=\"470\" cy=\"318\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><text x=\"484\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama cortado em 64</text></svg>", "caption": "Quanto custa cada forma dos mesmos vetores e quanto da vizinhança completa ela mantém, em todos os textos do conjunto. Menos bits por número sai quase de graça até o int8; menos números custa vizinhos em todos os tamanhos.", "same": ["all-MiniLM-L6-v2, 384", "WordLlama, 256"]}
```

## O que levar da tabela

Os seus números vão ser outros, porque dependem do modelo e do acervo, então meça como este
programa mede: contra os seus vetores completos, com os seus textos. O formato é o que se repete. O
`float16` não custou nada mensurável em nenhum dos dois modelos. O int8 é a primeira coisa a tentar
quando o armazenamento passa a custar dinheiro. O binário é uma primeira passada, não uma resposta:
guarde os vetores completos em algum lugar mais barato e use os bits para escolher candidatos, que é
o padrão de reranqueamento da aula 16.
