---
title: Busca híbrida
version: 2
---

Uma **busca híbrida** roda a busca vetorial e a lexical e junta os resultados. A junção é a parte
difícil, porque as duas produzem notas em escalas diferentes: uma similaridade de cosseno de 0,367 e uma
nota BM25 de 5,787 não podem ser somadas, e normalizá-las para uma faixa comum faz o resultado depender
do que mais estava em cada lista.

A **fusão por posição recíproca** (reciprocal rank fusion) contorna o problema ignorando as notas. Cada
lista vota nos seus pedaços pela posição, `1 / (60 + posição)`, e a nota fundida de um pedaço é a soma
dos votos:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def hybrid(question, k=3, depth=20, where=\"TRUE\", params=()):\n    \"\"\"Reciprocal rank fusion of the two lists, each DEPTH long.\"\"\"\n    fused = {}\n    for ranking in (vector(question, depth, where, params), lexical(question, depth, where, params)):\n        for rank, row in enumerate(ranking, 1):\n            fused.setdefault(row[0], [row[:3], 0.0])[1] += 1 / (60 + rank)\n    best = sorted(fused.values(), key=lambda item: -item[1])[:k]\n    return [(*row, score) for row, score in best]",
      "note": "Cada lista contribui com 1/(60 + posição) para cada pedaço que tem, e um pedaço nas duas listas ganha as duas parcelas. As notas dos dois métodos nunca são comparadas, só as posições, e é isso que permite combinar um cosseno com uma nota BM25."
    }
  ]
}
```

O 60 é uma constante do artigo que introduziu o método, Cormack e outros, 2009, e controla quanto um
primeiro lugar pesa mais que um décimo: com 60 a diferença é pequena, então um pedaço que as duas listas
põem razoavelmente alto vence um que uma única lista põe em primeiro.

```
ana@vm:~/rag$ python show.py hybrid "What does error E-4104 mean?"
1    0.033  Affiliate API reference > Errors  | | code | HTTP | meaning | | --- | --- | --- | | 
2    0.032  Affiliate API reference > Errors  | Errors are returned as JSON with a code and a me
3    0.031  Affiliate API reference > Changes in 2.3  | Version 2.3, released on 10 February 2026, added
4    0.030  Affiliate API reference > Rate limits  | A key may make 120 requests per minute. A reques
5    0.029  Warehouse on-call runbook > After an incident  | Every SEV-1 and SEV-2 gets a short review within
```

A tabela de erros está em primeiro, como estava nas duas listas. As notas fundidas são minúsculas e
próximas, 0,033 contra 0,032, porque são somas de recíprocos; como toda nota desta aula, só servem para
ordenar.

## Medindo tudo

O `measure.py` roda cada método do `search.py` contra os dois conjuntos de teste e conta as perguntas
cuja resposta está no primeiro pedaço e nos três primeiros:

```schooling-example
{
  "language": "python",
  "file": "measure.py",
  "parts": [
    {
      "code": "import json\n\nfrom search import hybrid, lexical, rerank, vector\n\nnorm = lambda t: \" \".join(t.split())\nfound = lambda rows, q: any(f in norm(r[2]) for r in rows for f in q[\"facts\"])\nmethods = {\n    \"vector\": lambda q: vector(q, 3),\n    \"lexical\": lambda q: lexical(q, 3),\n    \"hybrid\": lambda q: hybrid(q, 3),\n    \"hybrid, reranked\": lambda q: rerank(q, hybrid(q, 20), 3),\n}\nsets = {name: [q for q in map(json.loads, open(f\"data/{name}.jsonl\")) if q[\"facts\"]]\n        for name in (\"eval\", \"identifiers\")}",
      "note": "Quatro jeitos de buscar, cada um pedindo as três melhores. O reordenado reordena as vinte melhores do híbrido, então custa vinte chamadas ao modelo por pergunta."
    },
    {
      "code": "print(f\"{'':18}{'eval @1':>9}{'eval @3':>9}{'ids @1':>8}{'ids @3':>8}\")\nfor name, run in methods.items():\n    cells = []\n    for s in (\"eval\", \"identifiers\"):\n        results = [(q, run(q[\"question\"])) for q in sets[s]]\n        for k in (1, 3):\n            hits = sum(found(rows[:k], q) for q, rows in results)\n            cells.append(f\"{hits:>{6 if s == 'eval' else 5}}/{len(sets[s]):<2}\")\n    print(f\"{name:18}\" + \"\".join(cells))",
      "note": "Para cada método e cada conjunto de perguntas, quantas tiveram um fato certo no primeiro resultado, e entre os três primeiros. Cada pergunta é buscada uma vez e o primeiro resultado é lido dos três primeiros."
    }
  ]
}
```

```
ana@vm:~/rag$ python measure.py
                    eval @1  eval @3  ids @1  ids @3
vector                19/26    26/26    3/6     4/6 
lexical               16/26    20/26    4/6     6/6 
hybrid                20/26    24/26    4/6     5/6 
hybrid, reranked      19/26    26/26    0/6     4/6 
```

**Nenhuma linha vence todas as colunas.** A vetorial é a melhor nas perguntas de cliente entre as três
primeiras, 26 de 26. A lexical é a melhor nos identificadores entre as três primeiras, 6 de 6. A híbrida é
o meio-termo para o qual foi projetada: o melhor primeiro resultado nas perguntas de cliente, 20 de 26, e
perto da lexical nos identificadores, mas perdeu duas perguntas de cliente entre as três primeiras, 24
contra 26, porque a lista lexical empurrou pedaços mais fracos para a fusão. A última linha é o assunto
da próxima seção.

## O que tirar de uma tabela assim

**O método certo depende da mistura de perguntas, e só um conjunto de teste de perguntas reais diz qual é
a mistura.** Um assistente de atendimento cujos usuários nunca digitam um código de erro perde um pouco
ao virar híbrido; um assistente de desenvolvedores sem busca lexical falha justamente nas perguntas que
mais importam aos usuários. Meça nas suas próprias perguntas, dos dois tipos, e guarde a tabela.

Duas notas práticas. A constante da fusão e a profundidade de cada lista, 20 aqui, também são botões
que vale medir. E a maioria dos bancos vetoriais hoje oferece busca híbrida nativa, com a metade lexical
rodando dentro do mesmo motor; a aula 3 do `embeddings-vectors` construiu uma híbrida à mão sobre a
central de ajuda, e o princípio é o mesmo em qualquer escala.
