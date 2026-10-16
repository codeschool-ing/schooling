---
title: MAPE, o erro como porcentagem
version: 1
---

O **erro percentual absoluto médio** divide cada erro pela verdade antes da média:

`MAPE = mean(|truth − prediction| / truth)`

O atrativo é não ter unidade. "Erra 8,7%" pode ser comparado entre um modelo de minutos de entrega e
um de faturamento mensal, e gestores gostam de porcentagem. O problema é a mesma divisão, de dois
jeitos.

**Verdades pequenas viram porcentagens enormes.** Uma entrega de 15 minutos prevista em 25 erra 67%;
uma de 60 prevista em 70 erra 17%, pelos mesmos dez minutos. Aqui a entrega mais curta levou 15
minutos, então nada explode. Num alvo que pode ser zero, como unidades vendidas num dia parado, o MAPE
divide por zero e não quer dizer nada, e num alvo que fica muitas vezes perto de zero ele é dominado
por essas linhas.

**Ele é torto.** Prever para baixo custa no máximo 100%: preveja zero e você erra exatamente 100%, por
mais que a entrega tenha demorado. Prever para cima não tem teto. Então um modelo escolhido pelo MAPE é
puxado para prever de menos. O programa abaixo desloca toda previsão do `boost_absolute` 10% para baixo
e 10% para cima, e pergunta às duas métricas qual é pior. Salve isto como `mape.py`:

```python
# mape.py
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_absolute_percentage_error

predictions = pd.read_csv("predictions.csv")
truth = predictions["minutes"]
print("every prediction    MAE    MAPE")
for name, factor in [("10% lower", 0.9), ("as fitted", 1.0), ("10% higher", 1.1)]:
    guess = predictions["boost_absolute"] * factor
    print(f"{name:16} {mean_absolute_error(truth, guess):6.2f} "
          f"{mean_absolute_percentage_error(truth, guess):7.1%}")
```

```
ana@lab:~/ml$ python mape.py
every prediction    MAE    MAPE
10% lower          7.17   12.9%
as fitted          5.02    8.7%
10% higher         6.62   13.0%
```

**As duas métricas discordam sobre a direção.** Em minutos, prever 10% para baixo é pior, por causa
das entregas longas da cauda. Em porcentagem, prever 10% para cima é um pouquinho pior, porque a divisão
dá mais peso às entregas curtas e aos erros para cima. Numa promessa de entrega isso importa: a métrica
que gosta de previsões baixas é a que faz promessas que a van não cumpre.

Use o MAPE para **relatar** um erro a quem pensa em porcentagem, num alvo que nunca fica perto de zero.
Tome cuidado ao escolher modelo por ele, e não escolha por ele quando atrasar é o erro caro.
