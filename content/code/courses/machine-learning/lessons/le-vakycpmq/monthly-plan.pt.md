---
title: Por que o plano mensal parece arriscado
version: 1
---

A aula 15 pontuou o `churn_2026.csv` e achou os assinantes do plano mensal novo com chance de cerca de 0,11,
contra 0,05 e 0,07 dos outros planos, e deixou a pergunta do porquê para esta aula. O modelo da aula 15 é uma
regressão logística, então a pergunta tem resposta exata: a **contribuição** de cada coluna aos log-odds de
um assinante é o valor preparado dela vezes o peso dela, e comparar as contribuições médias dos assinantes
mensais com as de todos os outros mostra que colunas fazem a diferença. Salve isto como `monthly.py`:

```python
# monthly.py
import pandas as pd

from churn_model import build
from feira import load_churn

history = load_churn()
new = load_churn("data/churn_2026.csv")
model = build().fit(history, history["churned"])
prepared = model[:-1].transform(new)
weights = model.named_steps["logistic"].coef_[0]
contribution = pd.DataFrame(prepared.toarray() * weights if hasattr(prepared, "toarray")
                            else prepared * weights,
                            columns=model.named_steps["prepare"].get_feature_names_out())

monthly = (new["plan"] == "monthly").to_numpy()
gap = contribution[monthly].mean() - contribution[~monthly].mean()
print(f"{monthly.sum()} monthly subscribers against {(~monthly).sum():,} on the other plans")
print("columns that push the monthly plan's chances up, in log-odds:")
print(gap.sort_values(ascending=False).head(5).round(2).to_string())
print(f"all columns together: {gap.sum():+.2f}")
```

O `model[:-1]` é o pipeline sem o último passo, então o `transform` dá as 36 colunas preparadas que a
regressão logística lê. O codificador pode devolvê-las como tabela esparsa, e o `toarray` a transforma numa
comum.

```
ana@lab:~/ml$ python monthly.py
496 monthly subscribers against 12,658 on the other plans
columns that push the monthly plan's chances up, in log-odds:
numbers__tenure_capped                  0.67
words__plan_weekly                      0.36
words__plan_fortnightly                 0.28
numbers__missingindicator_rating_90d    0.10
numbers__rating_90d                     0.09
all columns together: +0.94
```

Dois motivos diferentes, e só um deles é sobre os assinantes.

**O `tenure_capped`, +0,67, é real.** Os assinantes mensais entraram em 2026, então todos têm pouco tempo de
casa, e pouco tempo de casa é um dos sinais mais fortes de saída que o modelo tem. Essa parte do risco valeria
para qualquer novato em qualquer plano.

**O `plan_weekly` e o `plan_fortnightly`, +0,36 e +0,28, são um artefato.** Todo assinante de um plano
conhecido recebe um desses dois pesos, ambos negativos, como os pesos de pagamento da primeira seção. Um
assinante mensal recebe zero nos dois, como o `handle_unknown="ignore"` da aula 14 arranjou, então ele deixa
de receber um peso negativo que todos os outros recebem. O modelo não está dizendo que o plano mensal é
arriscado. Ele nunca viu o plano mensal, e *"nenhum dos planos que conheço"* por acaso fica no intercepto,
acima dos dois planos conhecidos.

Então, dos +0,94 que separam os dois grupos, cerca de dois terços vêm de um plano de que o modelo não sabe
nada sendo lido como um valor que ele nunca aprendeu. Vale dizer isso à equipe de retenção antes que ela mande
aos assinantes mensais créditos de que talvez não precisem, e esse é o argumento mais forte que existe para
**ajustar de novo quando o plano novo tiver alguns meses de rótulos**, o que a aula 22 faz.
