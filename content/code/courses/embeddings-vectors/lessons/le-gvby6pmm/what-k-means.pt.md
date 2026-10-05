---
title: O que k quer dizer
version: 1
---

Toda busca deste curso até aqui terminou do mesmo jeito: ordenar as notas e ficar com as primeiras.
A quantidade guardada é o **k**, e uma busca que funciona assim é uma busca **top-k**. É fácil ler
k como *o número de respostas boas*. É o número de respostas, boas ou não.

Esta é a busca da aula 3 como módulo, para que o resto da aula possa importá-la:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Transforme os 40 artigos em vetores uma vez, título e corpo juntos, quando o módulo é importado. `D` é uma matriz de 40 × 384, uma linha por artigo."
    },
    {
      "code": "def search(text, k=3):\n    scores = D @ embed(text)[0]\n    top = np.argsort(-scores)[:k]\n    return [(float(scores[i]), ids[i], help[i][\"title\"]) for i in top]",
      "note": "`search` dá nota a todos os artigos contra a pergunta, ordena as notas da maior para a menor e fica com as `k` primeiras. Nada ali olha o quanto as notas são altas."
    }
  ]
}
```

E duas perguntas feitas a ela, uma que a central de ajuda responde e outra que não:

```python
from search import search

for question in ["the box never showed up", "do you sell concert tickets?"]:
    print(question)
    for score, id, title in search(question, k=3):
        print(f"  {score:.3f}  {id}  {title}")
```

```
ana@lab:~/emb$ python topk.py
the box never showed up
  0.458  h09  A parcel marked as delivered that never arrived
  0.300  h26  Resetting your password
  0.290  h19  Wrong book in the parcel
do you sell concert tickets?
  0.293  h05  Orders for schools and libraries
  0.266  h04  Buying books as a gift
  0.252  h24  Using a gift card
```

**A Marginalia não vende ingressos de show, e a busca devolveu três artigos mesmo assim.** Nada deu
errado. Pediram a `search` os três artigos mais próximos, e sempre existem três artigos mais
próximos, do mesmo jeito que sempre existe uma cidade mais próxima de qualquer ponto do mapa,
inclusive no meio do mar. Uma busca top-k não tem como dizer *não tem nada aqui*.

## O que as notas dizem, e o que não dizem

A primeira pergunta mostra a outra metade do mesmo fato. A resposta dela, **A parcel marked as
delivered that never arrived** (um pacote marcado como entregue que nunca chegou), está em primeiro
com 0,458, e depois vêm *Resetting your password* com 0,300 e *Wrong book in the parcel* com 0,290.
Nenhum dos dois tem a ver com uma caixa que nunca chegou. Estão ali porque k era 3 e alguma coisa
precisava ocupar o segundo e o terceiro lugares.

Leia as duas listas lado a lado e aparece mais uma coisa: o artigo de senha, que é ruído para a
primeira pergunta, tira **0,300**, mais do que qualquer coisa que a pergunta do show conseguiu
(0,293). Uma nota só é comparável com outras notas da mesma pergunta, do mesmo modelo. Não é uma
nota numa escala fixa, e o espaço lotado da aula 2 explica por quê: em 384 dimensões, textos que
não têm nada em comum ainda caem numa faixa de notas pequenas e positivas.

Então k responde *quantos*, e nunca responde *se*. O resto da aula trata das duas perguntas
separadamente: como escolher k, e como impedir que uma busca devolva o que não deveria.

## Onde k é definido

Toda ferramenta deste curso tem o mesmo botão com outro nome:

| onde | o botão |
|---|---|
| NumPy, como acima | `[:k]` depois da ordenação |
| Chroma | `n_results` |
| LanceDB, pgvector | `.limit(k)`, `LIMIT k` |
| Qdrant | `limit` |
| FAISS, hnswlib | `k` em `search` e `knn_query` |

Em todas elas é um pedido de k resultados. **Se você recebe k depende do índice**, e a seção *k e o
índice* mostra um banco de dados que devolve menos sem avisar.
