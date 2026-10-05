---
title: Busca híbrida
version: 1
---

As duas últimas seções deixam um resultado incômodo. A busca por embedding é muito melhor em
perguntas nas palavras do próprio cliente, e a busca por palavras é perfeita em textos exatos. Uma
caixa de busca de verdade recebe os dois. A **busca híbrida** roda as duas lado a lado e junta as
ordens numa só.

## Junte posições, não notas

Somar as duas notas não funciona. O BM25 imprimiu 3,22 e 4,11 nesta aula; a busca por embedding
imprime cossenos como 0,446. Os números vivem em escalas diferentes, e uma soma seria decidida pela
escala que por acaso fosse maior.

As posições estão na mesma escala nas duas listas. A **fusão por posição recíproca** (*reciprocal
rank fusion*, RRF) dá a cada documento, de cada lista, `1 / (k + rank)`, e soma:

`score(d) = 1 / (k + rank in keyword list) + 1 / (k + rank in embedding list)`

Um documento que não está numa lista não ganha nada dela. `k` é uma constante que suaviza a
diferença entre o primeiro e o segundo lugar, e 60, o valor do artigo que apresentou a RRF em 2009,
é o padrão de costume.

```schooling-example
{
  "language": "python",
  "file": "hybrid.py",
  "parts": [
    {
      "code": "import collections\nfrom bm25 import keyword_search, help\nfrom evaluate import embedding_search, recall, natural, exact\nfrom search import ids",
      "note": "As duas buscas e a medida vêm dos arquivos anteriores: `keyword_search` de `bm25.py`, e `embedding_search`, `recall` e os dois conjuntos de julgamentos de `evaluate.py`."
    },
    {
      "code": "def rrf(rankings, weights=None, k=60):\n    weights = weights or [1] * len(rankings)\n    scores = collections.defaultdict(float)\n    for ranking, weight in zip(rankings, weights):\n        for rank, doc in enumerate(ranking, start=1):\n            scores[doc] += weight / (k + rank)\n    return sorted(scores, key=lambda d: -scores[d]), scores",
      "note": "Fusão por posição recíproca: cada documento ganha `weight / (k + rank)` de cada lista em que aparece, e os totais são ordenados. As posições começam em 1."
    },
    {
      "code": "query = \"how fast is shipping\"\nkw, em = keyword_search(query), embedding_search(query)\nfused, scores = rrf([kw, em])\nfor doc in fused[:3]:\n    k_rank = kw.index(doc) + 1 if doc in kw else \"-\"\n    print(f\"{ids[doc]}  keyword {k_rank}  embedding {em.index(doc) + 1}\"\n          f\"  rrf {scores[doc]:.5f}  {help[doc]['title']}\")",
      "note": "O exemplo resolvido: os três primeiros da fusão para uma pergunta, com a posição de cada artigo nas duas listas. Um traço indicaria que a busca por palavras nem o devolveu."
    },
    {
      "code": "methods = {\n    \"keyword\": keyword_search,\n    \"embedding\": embedding_search,\n    \"hybrid\": lambda t: rrf([keyword_search(t), embedding_search(t)])[0],\n    \"hybrid, keyword x0.5\": lambda t: rrf([keyword_search(t), embedding_search(t)], [0.5, 1])[0],\n}\nprint(\"                       24 questions    8 exact strings\")\nfor name, rank in methods.items():\n    print(f\"{name:22} @1 {recall(rank, natural, 1):2}  @3 {recall(rank, natural, 3):2}\"\n          f\"    @1 {recall(rank, exact, 1)}  @3 {recall(rank, exact, 3)}\")",
      "note": "Quatro buscas medidas nos dois conjuntos: cada uma sozinha, fundidas com pesos iguais, e fundidas com a lista de palavras valendo a metade."
    }
  ]
}
```

```
ana@lab:~/emb$ python hybrid.py
h10  keyword 2  embedding 2  rrf 0.03226  Shipping outside the country
h07  keyword 9  embedding 1  rrf 0.03089  Delivery times and costs
h14  keyword 3  embedding 9  rrf 0.03037  How to return a book
                       24 questions    8 exact strings
keyword                @1 10  @3 15    @1 8  @3 8
embedding              @1 19  @3 22    @1 3  @3 7
hybrid                 @1 11  @3 20    @1 7  @3 8
hybrid, keyword x0.5   @1 15  @3 22    @1 7  @3 8
ana@lab:~/emb$ python search.py "4.90"
 0.254  h39  Prazos e custos de entrega
 0.090  h06  Where to find your order number
 0.090  h25  Prices and price changes
```

## Um exemplo resolvido

As três primeiras linhas são os três primeiros da fusão para *how fast is shipping* ("qual a
rapidez da entrega"), cuja resposta é **Delivery times and costs** ("prazos e custos de entrega"),
h07:

| artigo | posição por palavras | posição por embedding | nota RRF |
|---|---|---|---|
| h10 Shipping outside the country | 2 | 2 | 1/62 + 1/62 = 0,03226 |
| h07 Delivery times and costs | 9 | 1 | 1/69 + 1/61 = 0,03089 |
| h14 How to return a book | 3 | 9 | 1/63 + 1/69 = 0,03037 |

A busca por embedding tinha a resposta certa em primeiro. O BM25 a pôs em nono, porque o artigo
nunca diz *shipping*. **A fusão premia a concordância**, então o artigo que as duas listas puseram
em segundo ganhou do que uma lista pôs em primeiro. Essa é a RRF funcionando como foi desenhada, e
nesta pergunta ela piorou o resultado.

## O que ela fez em todas as perguntas

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Gráfico de barras do recall em 1 e em 3 para quatro buscas, nas 24 perguntas e nos 8 textos exatos. palavra-chave: 10 e 15 de 24 perguntas em 1 e 3, 8 e 8 de 8 textos exatos; embedding: 19 e 22 de 24 perguntas em 1 e 3, 3 e 7 de 8 textos exatos; híbrida: 11 e 20 de 24 perguntas em 1 e 3, 7 e 8 de 8 textos exatos; híbrida, palavra-chave ×0,5: 15 e 22 de 24 perguntas em 1 e 3, 7 e 8 de 8 textos exatos.\"><text x=\"190\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">24 perguntas comuns</text><path d=\"M190 52 L190 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M490 52 L490 262\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"490\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><text x=\"190\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"190\" y=\"64\" width=\"125\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"321\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><rect x=\"190\" y=\"82\" width=\"187.5\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"383.5\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">15</text><rect x=\"190\" y=\"114\" width=\"237.5\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"433.5\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">19</text><rect x=\"190\" y=\"132\" width=\"275\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"471\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">22</text><rect x=\"190\" y=\"164\" width=\"137.5\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"333.5\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11</text><rect x=\"190\" y=\"182\" width=\"250\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"446\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">20</text><rect x=\"190\" y=\"214\" width=\"187.5\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"383.5\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15</text><rect x=\"190\" y=\"232\" width=\"275\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"471\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">22</text><text x=\"530\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">8 textos exatos</text><path d=\"M530 52 L530 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M690 52 L690 262\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"690\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"530\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"530\" y=\"64\" width=\"160\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"696\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><rect x=\"530\" y=\"82\" width=\"160\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"696\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><rect x=\"530\" y=\"114\" width=\"60\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"596\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"530\" y=\"132\" width=\"140\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"676\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">7</text><rect x=\"530\" y=\"164\" width=\"140\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><rect x=\"530\" y=\"182\" width=\"160\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"696\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><rect x=\"530\" y=\"214\" width=\"140\" height=\"16\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><rect x=\"530\" y=\"232\" width=\"160\" height=\"16\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"696\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><text x=\"176\" y=\"81\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">palavra-chave</text><text x=\"176\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">embedding</text><text x=\"176\" y=\"181\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">híbrida</text><text x=\"176\" y=\"231\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">híbrida, palavra-chave ×0,5</text><rect x=\"20\" y=\"14\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"38\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">artigo certo em primeiro</text><rect x=\"220\" y=\"14\" width=\"12\" height=\"12\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"238\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">entre os três primeiros</text></svg>", "caption": "Recall em 1 e em 3 das quatro buscas que hybrid.py mediu. Fundir as duas listas salva os textos exatos e, com pesos iguais, tira das perguntas comuns boa parte do que a busca por embedding tinha ganhado.", "same": ["embedding"]}
```

**Com pesos iguais, a busca híbrida achou em primeiro 7 dos 8 textos exatos, quando a busca por
embedding sozinha achou 3. Nas 24 perguntas comuns ela pôs o artigo certo em primeiro 11 vezes,
quando a busca por embedding sozinha conseguiu 19.** Nesta central de ajuda, a fusão igual compra
os textos exatos com as perguntas comuns, e as perguntas comuns são a maior parte do tráfego.

Os pesos são o botão de ajuste. Reduzir à metade o peso da lista de palavras, para que os votos dela
valham metade, mantém 7 de 8 textos exatos e recupera o número dos três primeiros, 22, com 15 em
primeiro em vez de 11. Outros pesos cairiam em outro lugar, e escolher um é exatamente o trabalho
dos julgamentos de relevância de *Medindo uma busca*: meça nas suas próprias perguntas, incluindo os
números de pedido e os preços colados, e fique com o peso que atende a elas.

O último comando mostra por que os textos exatos precisam de ajuda. Diante de `4.90`, a busca por
embedding devolve o artigo de entrega em português com 0,254, que escreve o mesmo preço como
`4,90`, e os dois seguintes com 0,090. O BM25 achou o artigo em inglês que contém o texto exato.
Alguns sistemas mandam uma consulta que parece um código ou um número direto para a busca por
palavras, em vez de fundir; as consultas híbridas do Weaviate expõem o equilíbrio como um único
`alpha`, que a aula 12 mostra.
