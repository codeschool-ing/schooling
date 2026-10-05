---
title: Respondendo uma pergunta
version: 1
---

Na hora da busca o trabalho é pequeno: transformar a pergunta em vetor com o mesmo modelo, dar nota
contra cada vetor guardado e devolver os melhores.

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import json\nimport sys\nimport numpy as np\nfrom minilm import embed\n\nD = np.load(\"index.npy\")\nids = json.load(open(\"ids.json\"))\nhelp = {h[\"id\"]: h for h in map(json.loads, open(\"data/help.jsonl\"))}",
      "note": "Carregue o que `index.py` guardou, e os artigos para mostrar os títulos. O modelo é carregado uma vez, quando `minilm` é importado, e não a cada pergunta."
    },
    {
      "code": "def search(query, k=3):\n    q = embed(query)[0]\n    scores = D @ q\n    best = np.argsort(-scores)[:k]\n    return [(ids[i], float(scores[i])) for i in best]",
      "note": "Transforme a pergunta em vetor, dê nota contra cada linha, ordene da maior nota para baixo e fique com `k`. Cada número de linha volta a ser um artigo por meio de `ids`."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for doc, score in search(sys.argv[1]):\n        print(f\"{score:6.3f}  {doc}  {help[doc]['title']}\")",
      "note": "Pela linha de comando, imprima os três melhores com as notas."
    }
  ]
}
```

```
ana@lab:~/emb$ python search.py "how do I get my money back"
 0.446  h18  Returning a gift
 0.438  h15  When your refund arrives
 0.399  h22  Charged twice for one order
ana@lab:~/emb$ python search.py "the box never showed up"
 0.458  h09  A parcel marked as delivered that never arrived
 0.300  h26  Resetting your password
 0.290  h19  Wrong book in the parcel
```

**A pergunta sobre dinheiro de volta põe o artigo do reembolso em segundo, atrás do artigo do
presente, como na aula 1**, mas agora contra os 40 artigos, e não contra seis escolhidos a dedo. *the box never showed up* ("a caixa nunca chegou") encontra **A parcel marked as
delivered that never arrived** ("um pacote marcado como entregue que nunca chegou") com 0,458, sem
nenhuma palavra importante em comum.

Veja o que vem em segundo e terceiro para a caixa. **Resetting your password** ("redefinir sua
senha"), com 0,300, e **Wrong book in the parcel** ("livro errado no pacote"), com 0,290, não têm
nada a ver com um pacote que sumiu. Uma busca sempre devolve `k` resultados, existam ou não `k` bons,
e as notas deles ficam bem abaixo da primeira. A aula 16 trata disso: quando cortar uma lista e
como escolher `k`.

## Todos os artigos, toda vez

`D @ q` calcula a nota de **todos** os vetores guardados contra a pergunta, 40 produtos escalares de
384 números cada. Depois `np.argsort(-scores)` ordena todas elas, da maior nota para baixo, porque o
`argsort` ordena para cima e o sinal de menos inverte. Nada é pulado e nada é estimado, então os
três primeiros são exatamente os três mais próximos.

Isso se chama busca **exata**, ou de força bruta, e para 40 artigos é a ferramenta certa. O
custo cresce a cada documento novo: um milhão de artigos seriam um milhão de produtos escalares por
pergunta. A aula 11 mede onde isso começa a doer, e a aula 15 constrói os índices que evitam ler
todos os vetores, ao preço de às vezes perder um.
