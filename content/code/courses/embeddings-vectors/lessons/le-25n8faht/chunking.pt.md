---
title: Documentos longos e pedaços
version: 1
---

Todo artigo da central de ajuda é curto, um assunto e umas quarenta palavras. Documentos reais
muitas vezes não são: um manual, uma política, uma página que ganhou uma seção por ano. O primeiro
movimento natural é transformar cada documento inteiro em vetor, um vetor por documento, e ele é o
errado quando um documento trata de vários assuntos.

Um vetor é um ponto. Uma página sobre três coisas ganha um ponto em algum lugar entre as três, perto
de nenhuma, e **toda pergunta sobre um dos assuntos combina fraco com ela**. A correção é cortar o
documento em **pedaços** (*chunks*), transformar cada pedaço em vetor, buscar nos pedaços e devolver
o documento a que o melhor pedaço pertence.

## Medindo

`chunking.py` refaz a central de ajuda em inglês como ela poderia ter sido um dia: 13 páginas, cada
uma com até três artigos vizinhos de uma categoria emendados. Depois busca nas páginas de três
jeitos e pergunta, para cada uma das 24 perguntas, se a página com a resposta veio primeiro.

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed, pieces\n\nhelp = [h for h in map(json.loads, open(\"data/help.jsonl\")) if h[\"lang\"] == \"en\"]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]",
      "note": "Só os artigos em inglês, e as 24 perguntas."
    },
    {
      "code": "pages = []\nfor category in (\"orders\", \"shipping\", \"returns\", \"payments\", \"account\", \"ebooks\"):\n    articles = [h for h in help if h[\"category\"] == category]\n    for i in range(0, len(articles), 3):\n        group = articles[i:i + 3]\n        pages.append(([h[\"id\"] for h in group],\n                      \" \".join(h[\"title\"] + \". \" + h[\"body\"] for h in group)))\nprint(f\"{len(pages)} pages, the longest {max(len(pieces(t)) for _, t in pages)} word pieces\")",
      "note": "Monte a central de ajuda antiga: em cada categoria, junte até três artigos vizinhos numa página, e guarde quais artigos cada página contém. `pieces` conta o que o modelo leria."
    },
    {
      "code": "def windows(text, size=40, overlap=10):\n    w = text.split()\n    return [\" \".join(w[i:i + size]) for i in range(0, max(len(w) - overlap, 1), size - overlap)]\n\nchunkings = {\n    \"whole page\": [(p, text) for p, (_, text) in enumerate(pages)],\n    \"one article\": [(p, h[\"title\"] + \". \" + h[\"body\"])\n                    for p, (members, _) in enumerate(pages) for h in help if h[\"id\"] in members],\n    \"40-word window\": [(p, w) for p, (_, text) in enumerate(pages) for w in windows(text)],\n}",
      "note": "Três jeitos de cortar as páginas em vetores: a página inteira, um pedaço por artigo e janelas de 40 palavras que dividem 10 com a seguinte. Cada pedaço guarda o número da página de onde veio."
    },
    {
      "code": "Q = embed([q[\"text\"] for q in queries])\nfor name, chunks in chunkings.items():\n    V = embed([text for _, text in chunks])\n    owner = np.array([p for p, _ in chunks])\n    right, best = 0, []\n    for q, v in zip(queries, Q):\n        scores = V @ v\n        right += bool(set(pages[owner[scores.argmax()]][0]) & set(q[\"relevant\"]))\n        best.append(scores.max())\n        if q[\"id\"] == \"q15\":\n            example = f\"{' '.join(pages[owner[scores.argmax()]][0])} at {scores.max():.3f}\"\n    print(f\"{name:15} {len(chunks):3} vectors  right page first {right:2}/24\"\n          f\"  mean best {np.mean(best):.3f}  q15: {example}\")",
      "note": "Para cada corte, transforme os pedaços em vetores, ache o melhor pedaço para cada pergunta e confira se a página dele contém a resposta. Guarde também a melhor nota, e o resultado da pergunta q15."
    }
  ]
}
```

```
ana@lab:~/emb$ python chunking.py
13 pages, the longest 175 word pieces
whole page       13 vectors  right page first 18/24  mean best 0.411  q15: h35 h36 h37 at 0.199
one article      37 vectors  right page first 21/24  mean best 0.511  q15: h35 h36 h37 at 0.431
40-word window   59 vectors  right page first 19/24  mean best 0.510  q15: h35 h36 h37 at 0.409
```

**Transformadas inteiras em vetor, as páginas puseram a certa em primeiro em 18 perguntas de 24.
Cortadas nos limites dos artigos, em 21.** A melhor nota por pergunta também subiu, de 0,411 em
média para 0,511. A pergunta q15, *make the letters bigger when reading* ("aumentar as letras na
leitura"), mostra isso numa linha: os três métodos acharam a página certa, a que contém h35, h36 e
h37, mas a página inteira combinou com 0,199 e o artigo sobre fontes dentro dela com 0,431. A
resposta sempre esteve lá; um vetor do tamanho da página a tinha diluído.

Nada disso foi o modelo ficando sem espaço. A página mais longa tem 175 pedaços de palavra e o
all-MiniLM-L6-v2 lê 256, então toda palavra de toda página entrou. Um texto mais longo que isso
perde o final sem nenhum aviso, o que é um segundo motivo, à parte, para cortar; a aula 9 mostra
isso.

## Tamanho, sobreposição e limites

Dois números definem um cortador simples, e os dois são escolhas, não fatos:

- **Tamanho.** Pedaços pequenos tratam de uma coisa só e combinam com precisão, mas uma frase
  arrancada do contexto pode deixar de fazer sentido. Pedaços grandes guardam o contexto e voltam a
  escorregar para o problema da página inteira.
- **Sobreposição.** Janelas que dividem algumas palavras em cada borda mantêm inteira, em pelo menos
  uma delas, uma frase que cruza um limite. `windows()` usa 40 palavras com 10 em comum, o que deu
  59 pedaços a partir de 13 páginas.

As janelas fixas fizeram 19 de 24, abaixo dos 21 dos limites dos artigos. **Um limite que o autor
traçou, como um título, um parágrafo ou um artigo, costuma ser um lugar melhor para cortar do que uma
contagem de palavras**, porque ele já separa assuntos. Janelas são para texto que não tem essas
marcas.

Seja qual for o corte, guarde a ligação de cada pedaço com o documento, como `owner` faz aqui: a
busca ordena pedaços, e o cliente quer a página. O curso `rag` leva o corte em pedaços mais longe,
porque lá os próprios pedaços são entregues a um modelo de linguagem.
