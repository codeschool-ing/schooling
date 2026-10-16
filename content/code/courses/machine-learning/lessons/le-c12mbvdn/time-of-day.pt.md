---
title: A hora do dia
version: 1
---

A aula 5 transformou a hora da entrega numa marca, `rush`, e disse que a escolha pertencia a esta aula.
Há quatro jeitos de dar uma hora a um modelo, e cada um diz algo diferente sobre o que é uma hora:

- **um número**, de 8 a 20: mais tarde é mais lento, na mesma medida a cada hora;
- **um ponto num relógio**, o seno e o cosseno da hora como ângulo: 23h fica ao lado da meia-noite, que
  é o conselho de costume para tudo o que dá a volta;
- **uma coluna por hora**, one-hot: cada hora é uma coisa própria, e o modelo aprende cada uma;
- **uma marca de horário de pico**, 1 às 11, 12, 17, 18 e 19: alguém que conhece a cidade diz quais
  horas são cheias.

Dá para compará-los diretamente. Salve isto como `hours.py`; ele ajusta a reta da aula 5 com a hora
dada de cada jeito, e uma vez sem ela:

```python
# hours.py
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]

def table(rows, hour_as):
    out = rows[["distance_km", "items", "rain", "driver_months"]].copy()
    if hour_as == "a number":
        out["hour"] = rows["hour"]
    elif hour_as == "a point on a clock":
        out["hour_sin"] = np.sin(2 * np.pi * rows["hour"] / 24)
        out["hour_cos"] = np.cos(2 * np.pi * rows["hour"] / 24)
    elif hour_as == "one column per hour":
        hours = pd.get_dummies(rows["hour"], prefix="hour", dtype=float)
        out = pd.concat([out, hours.reindex(columns=[f"hour_{h}" for h in range(8, 21)],
                                            fill_value=0)], axis=1)
    elif hour_as == "a rush-hour flag":
        out["rush"] = rows["hour"].isin([11, 12, 17, 18, 19]).astype(int)
    return out

print("the hour as            columns   off by")
for hour_as in ["left out", "a number", "a point on a clock", "one column per hour",
                "a rush-hour flag"]:
    line = LinearRegression().fit(table(train, hour_as), train["minutes"])
    error = (test["minutes"] - line.predict(table(test, hour_as))).abs().mean()
    print(f"{hour_as:21} {table(train, hour_as).shape[1]:8}   {error:5.2f} min")
```

O `reindex` garante que as colunas de hora sejam as mesmas treze, na mesma ordem, nos dois conjuntos,
que é o trabalho que o `OneHotEncoder` faria sozinho; aqui ele mostra que trabalho é esse.

```
ana@lab:~/ml$ python hours.py
the hour as            columns   off by
left out                     4    7.22 min
a number                     5    7.06 min
a point on a clock           6    7.07 min
one column per hour         17    5.88 min
a rush-hour flag             5    5.87 min
```

**O relógio não fez melhor que o número simples**, 7,07 minutos contra 7,06, e os dois mal vencem deixar
a hora de fora. Seno e cosseno são certos quando o efeito sobe e desce suave ao longo do dia, como a
temperatura. Horários de pico são duas corcovas, no almoço e depois do trabalho, e uma onda suave ao longo
do dia não desenha duas corcovas. As entregas também vão das 8 às 20, então a volta das 23h para a
meia-noite, o motivo do relógio, nunca acontece.

**Uma coluna por hora acha as corcovas sozinha**, 5,88 minutos, com treze colunas e nenhum conhecimento.
**A marca chega ao mesmo, 5,87, com uma coluna**, porque alguém que conhecia a cidade a escreveu. Com seis
mil entregas as duas empatam. Com algumas centenas, os treze pesos por hora seriam aprendidos cada um com
algumas dezenas de linhas, e a marca venceria.

O mesmo raciocínio vale para datas. Uma data como número diz *mais tarde é diferente*, e toda data sobre
a qual o modelo vai ser perguntado é mais tarde que todas as datas de onde ele aprendeu, então o peso
aprendido é um palpite sobre um futuro que ele nunca viu. Pedaços de uma data costumam ser melhores: o
dia da semana, se é feriado, quantos dias faltam para o pagamento. E uma data é onde o futuro vaza com
mais facilidade. **Um atributo calculado de uma data só pode usar o que se sabia naquela data.**
