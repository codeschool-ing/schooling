---
title: O proxy que ficou
version: 1
---

Um proxy é uma coluna que carrega uma característica protegida sem nomeá-la. O teste para encontrar um é
direto: tente prever a característica a partir das colunas que o modelo mantém. Se funcionar, o modelo
consegue usar a idade sem recebê-la. Salve isto como `proxies.py`:

```python
# proxies.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
others = [c for c in NUMERIC if c != "age"] + CATEGORICAL

for name, older in [("65 or over", 65), ("50 or over", 50)]:
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(train[others], train["age"] >= older)
    guess = model.predict_proba(test[others])[:, 1]
    print(f"is the subscriber {name}? AUC {roc_auc_score(test['age'] >= older, guess):.3f}, "
          f"from columns that do not include age")

band = pd.cut(train["age"], [17, 24, 34, 49, 64, 99], labels=["18-24", "25-34", "35-49", "50-64", "65+"])
summary = pd.DataFrame({"app_user": train.groupby(band, observed=True)["app_user"].mean(),
                        "boleto": train.groupby(band, observed=True)["payment"]
                                       .apply(lambda p: (p == "boleto").mean())})
print(summary.round(2).T.to_string())
```

```
ana@lab:~/ml$ python proxies.py
is the subscriber 65 or over? AUC 0.872, from columns that do not include age
is the subscriber 50 or over? AUC 0.765, from columns that do not include age
age       18-24  25-34  35-49  50-64   65+
app_user   0.95   0.87   0.72   0.52  0.27
boleto     0.04   0.10   0.18   0.24  0.32
```

**Colunas sem a idade identificam quem tem 65 anos ou mais com AUC de 0,872.** Duas delas fazem a maior
parte do trabalho, e a tabela de baixo as mostra. 95% da faixa mais jovem usa o app, contra 27% da mais
velha; 4% da mais jovem paga com boleto, contra 32% da mais velha. Nenhuma das duas colunas é sobre idade,
as duas são coisas razoáveis para um modelo de churn ler, e juntas dizem muito sobre a idade de alguém.

Os proxies fazem algo mais específico que isso. `app_user` também decide se `days_since_login` existe,
então um login ausente é ele mesmo um sinal de idade. E a aula 19 viu que pagar com boleto soma cerca de
0,48 ao log-odds de sair. Se assinantes mais velhos saem mais em parte *porque* são mais velhos, um modelo
sem a idade vai pôr parte desse efeito no boleto, e quem paga com boleto, de qualquer idade, vai ser
tratado como se o compartilhasse.

Não existe uma lista de proxies para remover. Em dados sobre pessoas, quase tudo se correlaciona com algo
protegido: CEP com raça e renda, primeiro nome com sexo, hábitos de compra com religião, velocidade de
digitação com idade. Remover toda coluna correlacionada removeria o modelo. **A defesa é medir**: guarde a
característica protegida para auditoria, imprima as tabelas desta aula para todo modelo que entra no ar,
e olhe de novo sempre que o modelo ou os dados mudarem.
