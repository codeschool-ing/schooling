---
title: Agrupamento, e a escolha de quantos grupos
version: 1
---

A lição 1 agrupou os membros por quantas vezes e quanto eles compram. Esta seção os agrupa pelo
**que** eles leem, uma pergunta que os compradores da loja fazem: quantos tipos de leitor temos, e
qual o tamanho de cada um? Não há rótulo para "tipo de leitor", então é agrupamento de novo, com um
problema novo: **ninguém diz ao k-means quanto `k` deve valer.**

Cada membro vira oito números, a fração dos seus livros em cada categoria, então um membro que
comprou dez livros dos quais seis eram policiais tem 0,6 na coluna de policial. Salve isto como
`cluster.py`:

```python
"""cluster.py: kinds of reader, from the share of each category in what they bought."""
import sqlite3

import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

SHARES = """
SELECT p.member_id, t.category, count(*) AS books
FROM purchases p JOIN lines l USING (purchase_id) JOIN titles t USING (title_id)
WHERE p.day <= '2025-11-30'
GROUP BY p.member_id, t.category
"""

with sqlite3.connect("shop.db") as db:
    books = pd.read_sql_query(SHARES, db)
shares = books.pivot_table(index="member_id", columns="category", values="books", fill_value=0)
shares = shares[shares.sum(axis=1) >= 5]                # members with five books or more
shares = shares.div(shares.sum(axis=1), axis=0)         # each row now adds up to 1

for k in range(2, 11):
    groups = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(shares)
    print(f"k={k:2}  silhouette {silhouette_score(shares, groups, random_state=0):.3f}")

k = 8
shares["group"] = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(shares)
centres = shares.groupby("group").mean()
for g, row in centres.iterrows():
    top = row.sort_values(ascending=False).head(2)
    print(f"group {g}: {int((shares['group'] == g).sum()):4} members, "
          + ", ".join(f"{c} {v:.0%}" for c, v in top.items()))
```

Dois filtros antes de qualquer agrupamento. Só as compras até 30 de novembro são lidas, para que os
grupos descrevam a loja num momento. E só ficam os membros com cinco livros ou mais, porque as
frações de um membro com um livro são todas 0 e um 1, o que não diz nada sobre o gosto dele.

```
ana@dev:~/ml$ python cluster.py
k= 2  silhouette 0.129
k= 3  silhouette 0.176
k= 4  silhouette 0.227
k= 5  silhouette 0.258
k= 6  silhouette 0.281
k= 7  silhouette 0.309
k= 8  silhouette 0.322
k= 9  silhouette 0.304
k=10  silhouette 0.295
group 0:  385 members, literary 56%, science 7%
group 1:  445 members, history 54%, science 7%
group 2:  375 members, children 54%, literary 8%
group 3:  341 members, science 56%, cooking 8%
group 4:  370 members, travel 55%, science 8%
group 5:  364 members, cooking 56%, fantasy 7%
group 6:  429 members, crime 55%, science 7%
group 7:  379 members, fantasy 56%, literary 7%
```

## Lendo a silhueta

**A silhueta** dá uma nota a um agrupamento, de -1 a 1, perguntando, para cada membro, quanto mais
perto ele está do próprio grupo do que do outro grupo mais próximo. Ela não precisa de rótulo, e por
isso é o jeito usual de comparar valores de `k`. Aqui ela sobe de 0,129 com dois grupos para
**0,322 com oito**, e cai depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l02-silhouette\" aria-label=\"A silhueta para k de 2 a 10: 0,129, 0,176, 0,227, 0,258, 0,281, 0,309, 0,322, 0,304, 0,295. Ela sobe até um pico em k = 8 e cai depois.\"><path d=\"M80.0 40.0 L80.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 220.0 L80.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M80.0 175.0 L680.0 175.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 175.0 L80.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,1</text><path d=\"M80.0 130.0 L680.0 130.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 130.0 L80.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M80.0 85.0 L680.0 85.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 85.0 L80.0 85.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,3</text><path d=\"M80.0 40.0 L680.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">silhueta</text><path d=\"M80.0 220.0 L680.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M113.3 220.0 L113.3 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"113.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M180.0 220.0 L180.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M246.7 220.0 L246.7 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"246.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M313.3 220.0 L313.3 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"313.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M380.0 220.0 L380.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M446.7 220.0 L446.7 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"446.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M513.3 220.0 L513.3 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"513.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M580.0 220.0 L580.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"580.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M646.7 220.0 L646.7 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"646.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"380.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">número de grupos, k</text><path d=\"M113.3 161.9 L180.0 140.8 L246.7 117.8 L313.3 103.9 L380.0 93.5 L446.7 81.0 L513.3 75.1 L580.0 83.2 L646.7 87.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"113.3\" cy=\"161.9\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"180.0\" cy=\"140.8\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"246.7\" cy=\"117.8\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"313.3\" cy=\"103.9\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"380.0\" cy=\"93.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"446.7\" cy=\"81.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"513.3\" cy=\"75.1\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"580.0\" cy=\"83.2\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"646.7\" cy=\"87.2\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"513.3\" y=\"59.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pico em 8 · 0,322</text></svg>", "caption": "A silhueta sobe até oito grupos e cai depois: oito é onde cada membro está mais claramente mais perto do próprio grupo do que do seguinte."}
```

Oito grupos, cada um construído em volta de uma categoria, com 54 a 56%. Isso bate com o jeito como
o gerador sorteia um membro: **duas categorias favoritas, a primeira escolhida para metade dos
livros.** O k-means achou a primeira favorita e nada da segunda, que fica espalhada em 7 ou 8% por
todos os grupos. A loja tem 28 pares de favoritas, e uma silhueta com pico em oito está mostrando a
estrutura que consegue ver, não a estrutura que existe.

Duas coisas para guardar disto. **O melhor `k` pela silhueta é uma sugestão**, e um comprador que
quer "leitores de policial e de literatura" como um grupo pediria outro agrupamento de propósito. E
o número de um grupo é um acaso da rodada: o grupo 6 é o de policial aqui por causa da ordem em que
o k-means calhou de se acomodar, e um modelo treinado de novo tem toda liberdade de chamá-lo de
outra coisa.
