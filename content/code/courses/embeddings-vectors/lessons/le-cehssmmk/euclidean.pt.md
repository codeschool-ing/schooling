---
title: Distância euclidiana
version: 1
---

O outro jeito natural de comparar dois pontos é medir a linha reta entre eles. Essa é a
**distância euclidiana**, também chamada de **distância L2**: subtraia um vetor do outro e tire o
comprimento do que sobrou. Para os dois vetores das seções anteriores, `a − b` é `(1, −1, 0)` e o
comprimento dele é √(1 + 1 + 0) = 1,414.

O sentido da escala é a primeira coisa a não confundir. **Uma similaridade é maior quando dois
textos estão mais perto; uma distância é menor.** Ordenar uma distância de cima para baixo devolve
primeiro os piores resultados, e é um erro que parece perfeitamente razoável na tela.

## Para vetores de comprimento 1, a mesma ordem do cosseno

Abra a distância ao quadrado e o produto escalar aparece dentro dela:
`|a − b|² = |a|² + |b|² − 2 a · b`. Quando os dois vetores têm comprimento 1, os dois primeiros
termos valem 1 cada e o produto escalar é o cosseno, então

`|a − b|² = 2 − 2 cos θ`

A distância é uma função fixa e decrescente do cosseno. Ordenar pela menor distância é, portanto,
exatamente ordenar pelo maior cosseno, e `euclid.py` confere isso na central de ajuda com as 24
perguntas de `data/queries.jsonl`:

```schooling-example
{
  "language": "python",
  "file": "euclid.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\na = np.array([2, 1, 2])\nb = np.array([1, 2, 2])\nprint(a - b, round(np.linalg.norm(a - b), 3))",
      "note": "O exemplo do papel: subtrair e depois tirar o comprimento."
    },
    {
      "code": "help = [json.loads(line) for line in open(\"data/help.jsonl\")]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nQv = embed([q[\"text\"] for q in queries])",
      "note": "Os 40 artigos e as 24 perguntas, todos transformados em vetores pelo all-MiniLM-L6-v2."
    },
    {
      "code": "q = Qv[0]\ncos = D @ q\ndist = np.linalg.norm(D - q, axis=1)\nprint(\"      cos    dist   2-2cos  dist^2\")\nfor i in np.argsort(-cos)[:4]:\n    print(f\"{help[i]['id']}  {cos[i]:.3f}  {dist[i]:.3f}  {2 - 2 * cos[i]:.3f}  {dist[i] ** 2:.3f}\")",
      "note": "Para a primeira pergunta, *how do I get my money back* (\"como recebo meu dinheiro de volta\"), o cosseno e a distância dos quatro melhores artigos, com os dois lados da fórmula."
    },
    {
      "code": "same_l2 = same_l1 = top_l1 = 0\nfor q in Qv:\n    by_cos = np.argsort(-(D @ q))\n    by_l2 = np.argsort(np.linalg.norm(D - q, axis=1))\n    by_l1 = np.argsort(np.abs(D - q).sum(axis=1))\n    same_l2 += (by_cos == by_l2).all()\n    same_l1 += (by_cos == by_l1).all()\n    top_l1 += by_cos[0] == by_l1[0]\nprint(f\"same order as cosine, all 40 articles: L2 {same_l2}/24, L1 {same_l1}/24\")\nprint(f\"same first article as cosine:          L1 {top_l1}/24\")",
      "note": "Para cada pergunta, ordene os 40 artigos de três jeitos e compare as ordens: pelo maior cosseno, pela menor distância L2 e pela menor distância L1."
    }
  ]
}
```

```
ana@lab:~/emb$ python euclid.py
[ 1 -1  0] 1.414
      cos    dist   2-2cos  dist^2
h18  0.446  1.053  1.109  1.109
h15  0.438  1.061  1.125  1.125
h22  0.399  1.096  1.201  1.201
h14  0.392  1.103  1.216  1.216
same order as cosine, all 40 articles: L2 24/24, L1 0/24
same first article as cosine:          L1 23/24
```

A tabela é a fórmula em números. Para o artigo do presente, a coluna `2-2cos` e o quadrado da
distância de 1,053 dão os dois 1,109, e o mesmo vale em todas as linhas. **As duas ordens dos 40
artigos coincidem em 24 das 24 perguntas.** Para um modelo cujos vetores têm comprimento 1, escolher
entre cosseno e L2 muda os números que você vê e nunca a ordem dos resultados.

## Distância de Manhattan

A distância **L1**, ou **de Manhattan**, soma as diferenças absolutas coordenada por coordenada, do
jeito que um táxi atravessa uma cidade de quarteirões quadrados. É uma distância perfeitamente
válida, e não é aquela com que esses modelos foram treinados. As duas últimas linhas medem quanto
isso custa: a L1 pôs em primeiro o mesmo artigo que o cosseno em 23 das 24 perguntas, e a ordem
completa dos 40 artigos coincidiu em nenhuma. Algumas bibliotecas oferecem essa distância; com
embeddings de texto, raramente você terá motivo para escolhê-la.
