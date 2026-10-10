---
title: Profundidade, e o ponto em que a árvore começa a decorar
version: 1
---

Cada pergunta divide as linhas ao meio de novo, mais ou menos, então uma árvore de profundidade d
pode ter até 2^d folhas. Funda o bastante, cada folha tem um punhado de linhas, e a árvore parou de
aprender padrões e começou a guardar respostas: a árvore sem limites da aula 3, com 3.421 folhas e
prejuízo nos meses de teste. A profundidade é o botão entre essas pontas. Salve isto como `depth.py`:

```python
# depth.py
from sklearn.tree import DecisionTreeClassifier

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
cut = CREDIT / (SAVED * KEPT)
print("depth  leaves   training R$   test R$")
for depth in [1, 2, 3, 4, 5, 6, 7, 8, 10, 15, None]:
    tree = DecisionTreeClassifier(max_depth=depth, random_state=0)
    tree.fit(train[NUMERIC], train["churned"])
    values = [net_value(rows["churned"], tree.predict_proba(rows[NUMERIC])[:, 1] >= cut)
              for rows in (train, test)]
    print(f"{str(depth):5}  {tree.get_n_leaves():6,}  {values[0]:11,.0f}  {values[1]:8,.0f}")
```

```
ana@lab:~/ml$ python depth.py
depth  leaves   training R$   test R$
1           2            0         0
2           4       14,992     7,304
3           8       20,392    10,048
4          16       25,216    13,528
5          31       29,144    14,416
6          60       37,192    17,072
7         110       42,928    18,096
8         188       48,952     8,624
10        441       68,400     7,256
15      1,610      138,280    -7,624
None    3,328      228,784   -23,856
```

Leia as duas colunas de valor lado a lado:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" data-fig=\"l07-depth\" aria-label=\"Valor líquido em milhares de reais contra a profundidade da árvore, de 1 a 20. A curva de treino sobe sem parar; a de teste sobe até um pico na profundidade 7 e depois cai abaixo de zero.\"><path d=\"M70.0 30.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 250.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-40</text><path d=\"M70.0 213.3 L560.0 213.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 213.3 L70.0 213.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"213.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 176.7 L560.0 176.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 176.7 L70.0 176.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"176.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M70.0 140.0 L560.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 140.0 L70.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><path d=\"M70.0 103.3 L560.0 103.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 103.3 L70.0 103.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"103.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><path d=\"M70.0 66.7 L560.0 66.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 66.7 L70.0 66.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"66.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">160</text><path d=\"M70.0 30.0 L560.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 30.0 L70.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><text x=\"70.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">valor líquido, milhares de reais</text><path d=\"M70.0 250.0 L560.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L70.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M173.2 250.0 L173.2 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"173.2\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M302.1 250.0 L302.1 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"302.1\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M431.1 250.0 L431.1 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"431.1\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M560.0 250.0 L560.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"315.0\" y=\"281.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">max_depth</text><path d=\"M70.0 213.3 L95.8 199.6 L121.6 194.6 L147.4 190.2 L173.2 186.6 L198.9 179.2 L224.7 174.0 L250.5 168.5 L276.3 160.2 L302.1 150.6 L327.9 140.3 L353.7 129.4 L379.5 115.6 L405.3 101.0 L431.1 86.6 L456.8 72.0 L482.6 59.6 L508.4 46.7 L534.2 35.7 L560.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"566.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meses de treino</text><path d=\"M70.0 213.3 L95.8 206.6 L121.6 204.1 L147.4 200.9 L173.2 200.1 L198.9 197.7 L224.7 196.7 L250.5 205.4 L276.3 205.4 L302.1 206.7 L327.9 212.0 L353.7 211.7 L379.5 211.5 L405.3 217.6 L431.1 220.3 L456.8 221.6 L482.6 223.2 L508.4 227.0 L534.2 233.6 L560.0 230.7\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"566.0\" y=\"230.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">meses de teste</text><circle cx=\"224.7\" cy=\"196.7\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"224.7\" y=\"182.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pico: profundidade 7</text></svg>", "caption": "Depois da profundidade 7, cada nível a mais ajuda os meses de treino e prejudica os de teste.", "same": ["max_depth"]}
```

**Nos meses de treino, o valor sobe a cada nível a mais**, de nada até R$ 228.784, porque uma árvore
mais funda sempre consegue se ajustar melhor às próprias linhas. **Nos meses de teste ele sobe até a
profundidade 7, R$ 18.096, e depois cai**, passando por R$ 8.624 na profundidade 8 até um prejuízo
de R$ 23.856 sem limite. A distância entre as curvas é o sobreajuste tornado visível, e o pico da
curva de teste é onde a árvore aprende o máximo que consegue sem decorar.

A profundidade 1 não faz nada porque uma pergunta só não acha um grupo acima do equilíbrio de 28%: o
melhor corte isolado, a avaliação, deixa 27,1% do seu lado. A profundidade 2 acha a folha de 39% da
seção anterior.

A curva de teste é usada aqui só para mostrar a forma. **Escolher a profundidade pelo pico dela nos
meses de teste seria ajustar ao teste**, o erro da aula 3. A profundidade é escolhida em dados de
validação, por validação cruzada dentro dos meses de treino, que a aula 9 faz para todo botão de todo
modelo.
