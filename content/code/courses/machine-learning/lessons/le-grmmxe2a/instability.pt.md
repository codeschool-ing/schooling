---
title: Por que uma árvore só não basta
version: 1
---

Uma árvore é construída de forma gulosa, um corte por vez, e cada corte depende dos que estão acima
dele. Mude um pouco as linhas de treino e um corte de cima pode se mexer, e aí tudo abaixo dele é
outra árvore. Essa é a propriedade que esta seção mede e que a aula 8 aproveita. Salve isto como
`unstable.py`; ele ajusta uma árvore de três níveis em cinco metades aleatórias diferentes dos meses
de treino:

```python
# unstable.py
from sklearn.tree import DecisionTreeClassifier

from feira import NUMERIC, by_time, load_churn

train, _ = by_time(load_churn())
for seed in range(5):
    sample = train.sample(frac=0.5, random_state=seed)            # another half of the rows
    tree = DecisionTreeClassifier(max_depth=3, random_state=0)
    tree.fit(sample[NUMERIC], sample["churned"])
    t = tree.tree_
    root = f"{NUMERIC[t.feature[0]]} <= {t.threshold[0]:.2f}"
    second = sorted({NUMERIC[f] for f in t.feature[1:] if f >= 0})
    print(f"sample {seed}: root {root:26} below it: {', '.join(second)}")
```

```
ana@lab:~/ml$ python unstable.py
sample 0: root rating_90d <= 3.60         below it: complaints_90d, rating_90d, skips_90d, tenure_months
sample 1: root rating_90d <= 3.58         below it: complaints_90d, skips_90d, tenure_months
sample 2: root rating_90d <= 3.59         below it: complaints_90d, rating_90d, skips_90d, tenure_months
sample 3: root rating_90d <= 3.60         below it: rating_90d, skips_90d, tenure_months
sample 4: root rating_90d <= 3.59         below it: days_since_login, late_90d, skips_90d, tenure_months
```

**A raiz é estável**: toda metade escolhe a avaliação, num limiar entre 3,58 e 3,60. Esse corte é
tão melhor que qualquer outro, como o `purity.py` mostrou, que nenhuma amostra razoável escolheria
outra coisa. **Abaixo dela, as árvores discordam.** A amostra 4 traz `days_since_login` e `late_90d`,
que nenhuma outra usa, e deixa de lado `complaints_90d`, em que três das outras se apoiam. Cinco
amostras, quatro conjuntos diferentes de perguntas de baixo.

Em dados sem uma coluna dominante, até a raiz se mexe, e as árvores diferem desde o topo. De um jeito
ou de outro, a conclusão é a mesma: **uma árvore sozinha tem variância alta.** As linhas específicas
que ela recebeu deixam uma marca forte nela, então as previsões para um assinante individual podem
mudar bastante de um ajuste para outro.

Há um lado bom escondido nisso. Se cada árvore é um palpite ruidoso mas diferente, **tirar a média de
muitas delas cancela boa parte do ruído**, do mesmo jeito que a média de muitas medições ruidosas é
melhor que qualquer uma delas. Essa ideia, aplicada com algum cuidado sobre como as árvores ficam
diferentes, é a floresta aleatória, e é a primeira seção da aula 8.
