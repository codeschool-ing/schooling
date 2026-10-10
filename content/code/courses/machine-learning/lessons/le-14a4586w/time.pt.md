---
title: A divisão que respeita o tempo
version: 1
---

Tudo acima embaralha as linhas antes de cortá-las, e embaralhar traz uma suposição dentro: **que a
ordem das linhas não carrega informação.** Para a Feira em Casa ela carrega muita. O modelo será usado
em 1º de janeiro de 2026 para avaliar janeiro, tendo aprendido com tudo o que veio antes. Uma divisão
embaralhada, em vez disso, deixa que ele aprenda com setembro para julgar agosto, e o futuro vaza para
dentro.

O que vaza não é uma coluna, é um mundo. Em setembro de 2025 toda caixa ficou 12% mais cara e mais
gente cancelou. Um modelo que viu setembro aprendeu o que o aumento fez; em 1º de janeiro ele teria
aprendido, legitimamente, mas no dia 1º de qualquer mês anterior não poderia. Salve isto como
`time_split.py`:

```python
# time_split.py
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import train_test_split

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

churn = load_churn()
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)


def judged(learn, check):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    send = model.predict_proba(check[features])[:, 1] >= cut
    return net_value(check["churned"], send) / len(check) * 1000


learn, check = by_time(churn)
print(f"learn before July, judge July-December:   R$ {judged(learn, check):5.0f} per 1,000 rows")

learn, rest = train_test_split(churn, test_size=0.3, random_state=0)
check = rest[rest["snapshot"] >= "2025-07-01"]
print(f"learn from a random 70% of all 18 months: R$ {judged(learn, check):5.0f} per 1,000 rows")
```

```
ana@lab:~/ml$ python time_split.py
learn before July, judge July-December:   R$   893 per 1,000 rows
learn from a random 70% of all 18 months: R$  1007 per 1,000 rows
```

**O mesmo modelo e os mesmos meses de teste, R$ 893 contra R$ 1.007 por mil linhas.** A divisão ao
acaso é 13% mais otimista, e nada desses 13% estaria lá no dia em que o modelo for usado. Nenhum dos
dois números é o modelo melhor ou pior; um mede a situação em que o modelo vai estar, e o outro não.

## Caminhando para a frente no tempo

Uma divisão por tempo também pode ser repetida, que é a ideia da validação cruzada adaptada a uma
flecha: para cada mês, aprenda com tudo o que veio antes e meça aquele mês. O `TimeSeriesSplit` do
scikit-learn faz o corte para linhas igualmente espaçadas; para retratos mensais o laço fica mais
claro escrito por extenso. Salve isto como `walk_forward.py`:

```python
# walk_forward.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, load_churn, net_value

churn = load_churn()
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

print("month       learned from  leavers  R$ per 1,000 rows")
for month in pd.date_range("2025-01-01", "2025-12-01", freq="MS"):
    learn = churn[churn["snapshot"] < month]          # everything known before it
    check = churn[churn["snapshot"] == month]
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    send = model.predict_proba(check[features])[:, 1] >= cut
    value = net_value(check["churned"], send) / len(check) * 1000
    print(f"{month:%Y-%m}     {len(learn):>10,}  {check['churned'].mean():6.1%}  {value:10.0f}")
```

```
ana@lab:~/ml$ python walk_forward.py
month       learned from  leavers  R$ per 1,000 rows
2025-01         17,931    5.8%         755
2025-02         21,122    5.5%         568
2025-03         24,415    5.2%         367
2025-04         27,797    5.0%         395
2025-05         31,300    5.5%         643
2025-06         34,906    4.9%         589
2025-07         38,628    4.7%         530
2025-08         42,461    5.0%         495
2025-09         46,423    7.2%        1182
2025-10         50,504    6.9%        1064
2025-11         54,602    6.9%         946
2025-12         58,739    6.0%        1127
```

Leia a última coluna de cima para baixo. O valor do modelo por mil linhas vai de R$ 367 a R$ 1.182 de
um mês para outro, e o salto é em **setembro**, quando a parte de quem saiu subiu de 5,0% para 7,2%.
Mais gente saindo quer dizer mais créditos que valem a pena, então o mesmo modelo valeu o dobro nos
meses depois do aumento. Uma divisão ao acaso faz a média de tudo isso num número só e o esconde.

Duas conclusões, e as duas valem pelo resto do curso:

- **Meça por tempo quando o modelo for usado para a frente no tempo.** Isso é quase todo modelo que
  uma empresa põe em uso. Uma divisão ao acaso responde a uma pergunta que ninguém vai fazer.
- **Espere que a nota se mexa com o mundo.** A tabela mês a mês é uma prévia da aula 22, em que o
  modelo encontra 2026 e o mundo se mexeu de novo.
