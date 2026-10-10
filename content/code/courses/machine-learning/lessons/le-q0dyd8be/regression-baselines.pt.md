---
title: Linhas de base para uma quantidade
version: 1
---

Uma regressão também tem linhas de base, e elas funcionam do mesmo jeito: a constante primeiro,
depois as regras que uma pessoa escreveria, todas escolhidas nas linhas de treino e medidas nas de
teste. A nota aqui é a mais simples que existe para uma quantidade, **quanto o palpite erra, em
média, na própria unidade do alvo**. A aula 12 a chama de MAE e a põe ao lado das outras.

Os dados são o `deliveries.csv`: uma linha por entrega em 2025, e os minutos que ela levou. Os três
últimos meses são o teste. Salve isto como `delivery_baselines.py`:

```python
# delivery_baselines.py
import pandas as pd

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]
print(f"learn from {len(train):,} deliveries, test on {len(test):,}")

per_km = (train["minutes"] / train["distance_km"]).median()
guesses = {
    "the mean of all deliveries": train["minutes"].mean(),
    "the median of all deliveries": train["minutes"].median(),
    "the median of the city": test["city"].map(train.groupby("city")["minutes"].median()),
    "the median minutes per km, times km": per_km * test["distance_km"],
    "the median by hour of day": test["hour"].map(train.groupby("hour")["minutes"].median()),
}
for name, guess in guesses.items():
    error = (test["minutes"] - guess).abs().mean()
    print(f"  {name:38} off by {error:5.1f} minutes on average")
```

```
ana@lab:~/ml$ python delivery_baselines.py
learn from 4,460 deliveries, test on 1,540
  the mean of all deliveries             off by  12.0 minutes on average
  the median of all deliveries           off by  11.6 minutes on average
  the median of the city                 off by  11.6 minutes on average
  the median minutes per km, times km    off by  17.7 minutes on average
  the median by hour of day              off by  10.9 minutes on average
```

Três coisas em cinco linhas de resultado.

**A mediana supera a média como constante**, 11,6 minutos contra 12,0. Algumas entregas levam uma ou
duas horas a mais que o normal, um pneu furado ou um endereço errado, e puxam a média para cima; a
mediana as ignora, e um erro médio absoluto em minutos é exatamente o que a mediana minimiza.

**Separar por cidade não compra nada.** As cidades diferem menos no tempo de entrega do que parece
que deveriam, e a regra que um gerente usaria primeiro acrescenta uma coluna e nenhuma precisão.

**A regra que soa mais sensata é a pior.** "Minutos por quilômetro, vezes quilômetros" é como
qualquer pessoa estimaria uma viagem, e erra por 17,7 minutos, pior que ignorar a distância de vez.
Uma entrega tem uma parte fixa, carregar a van e achar a porta, que não cresce com a distância; uma
regra sem espaço para ela erra de um jeito que cresce a cada viagem curta. A aula 5 ajusta uma reta
que tem as duas partes, e o erro dela é o número a pôr ao lado de **10,9 minutos**, a melhor destas.
