---
title: Um assinante de um lado só
version: 1
---

As linhas do `churn.csv` vêm em famílias: um assinante, uma linha por mês. Quando as partes são
cortadas ao acaso, a linha de março de um assinante pode estar nas partes de treino e a de abril na
parte medida. **Se isso importa depende de as linhas de uma família compartilharem a resposta.**

O `folds.py` já mediu isso para a pergunta da Feira em Casa. A terceira linha dele usou o
`GroupKFold`, que põe todas as linhas de um assinante na mesma parte, e a nota ficou parecida com as
outras: média de R$ 787 por mil linhas contra R$ 824 e R$ 758, bem dentro da dispersão. Isso porque a
pergunta é sobre um mês. Se alguém cancela em abril é um evento novo, e conhecer a linha de março
dele diz pouco.

Agora faça outra pergunta às mesmas linhas: **este assinante algum dia vai cancelar?** Cada linha
carrega a mesma resposta que todas as outras da mesma pessoa, e um modelo que reconhece a pessoa tem
a resposta. Salve isto como `groups.py`:

```python
# groups.py
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold, KFold

from feira import NUMERIC, by_time, load_churn

train, _ = by_time(load_churn())
X = train[NUMERIC].fillna(-1)
ever = train.groupby("customer_id")["churned"].transform("max")   # one answer per person
print(f"rows whose subscriber ever cancels: {ever.mean():.1%}")


def top_tenth(splitter, groups=None):
    """Of the 10% of rows the model ranks highest, the share that are right."""
    hits = []
    for fit_rows, check_rows in splitter.split(X, ever, groups):
        forest = RandomForestClassifier(n_estimators=200, n_jobs=-1, random_state=0)
        forest.fit(X.iloc[fit_rows], ever.iloc[fit_rows])
        score = forest.predict_proba(X.iloc[check_rows])[:, 1]
        top = np.argsort(-score)[: len(check_rows) // 10]
        hits.append(ever.iloc[check_rows].iloc[top].mean())
    return np.mean(hits)


print(f"rows split at random:     {top_tenth(KFold(5, shuffle=True, random_state=0)):.1%}")
print(f"subscribers kept whole:   {top_tenth(GroupKFold(5), train['customer_id']):.1%}")
```

```
ana@lab:~/ml$ python groups.py
rows whose subscriber ever cancels: 23.9%
rows split at random:     76.0%
subscribers kept whole:   54.7%
```

A nota aqui é a parte de acertos entre os 10% de linhas que o modelo põe no topo, escolhida porque
não precisa de vocabulário de aulas posteriores. Cortado ao acaso, **76,0%** do décimo do topo
acertam; com cada assinante inteiro, **54,7%**. A floresta tinha achado um jeito de reconhecer
pessoas pela idade, pelo tempo de casa e pelos hábitos, e um corte ao acaso a premiou por lembrar
delas. Os 54,7% são os honestos: é o que acontece quando o modelo encontra alguém novo, que é a única
coisa que ele vai fazer em produção.

## Quando agrupar

Agrupe sempre que **uma coisa do mundo produz várias linhas e elas compartilham a resposta**: um
paciente e seus exames, um cliente e seus pedidos quando a pergunta é sobre o cliente, uma casa e
seus anúncios ao longo dos anos, um motorista e suas viagens. O teste é uma pergunta: *em produção,
o modelo vai alguma vez avaliar uma linha de uma família que ele viu no treino?* Se não, as partes
também não podem deixar.
