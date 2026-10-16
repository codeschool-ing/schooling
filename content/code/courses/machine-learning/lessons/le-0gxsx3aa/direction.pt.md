---
title: Atrasado ou adiantado
version: 1
---

Toda métrica até aqui jogou fora o sinal do erro. O MAE tira o valor absoluto, o RMSE e o R² elevam ao
quadrado, o MAPE tira o valor absoluto de novo. **Uma entrega 10 minutos atrasada e uma 10 minutos
adiantada contam igual nas quatro.**

A aula 1 disse que elas não custam o mesmo. A Feira em Casa quer dizer a cada cliente quando a caixa
vai chegar, e a visão da equipe de logística é simples: uma caixa prometida em 40 minutos que chega em
30 não incomoda ninguém, e uma que chega em 50 gera reclamação. Suponha que o aplicativo mostre a
previsão do modelo como promessa. A pergunta passa a ser com que frequência cada modelo atrasa, e por
quanto. Salve isto como `direction.py`:

```python
# direction.py
import pandas as pd

predictions = pd.read_csv("predictions.csv")
print("promise = prediction   average error   late   late by more than 10 min")
for model in ["line", "boost_squared", "boost_absolute"]:
    late_by = predictions["minutes"] - predictions[model]
    print(f"{model:20} {late_by.mean():+11.2f} min {(late_by > 0).mean():7.1%}"
          f" {(late_by > 10).mean():12.1%}")
```

O **erro médio** mantém o sinal, e tem nome: o **viés**. Positivo quer dizer que as entregas demoraram
mais do que o previsto.

```
ana@lab:~/ml$ python direction.py
promise = prediction   average error   late   late by more than 10 min
line                       +0.20 min   26.6%         3.8%
boost_squared              +0.22 min   33.3%         4.0%
boost_absolute             +2.89 min   50.5%         5.0%
```

O modelo com o melhor MAE **atrasa em metade das promessas**, 50,5%. Isso não é defeito: ele prevê a
mediana, e a mediana é por definição o tempo que metade das entregas ultrapassa. É exatamente o que
foi pedido, e exatamente errado para uma promessa. O viés dele é de quase três minutos de atraso,
porque as entregas que passam do tempo passam por mais do que as adiantadas ficam aquém.

A reta quase não tem viés, +0,20 minuto, e atrasa só 26,6% das vezes. Ela mira a média, e a média fica
acima da mediana aqui, então como promessa ela é cautelosa por acidente. Isso é sorte, não projeto. Num
alvo cuja cauda fosse para o outro lado, ela atrasaria mais vezes que a mediana.

Então um modelo de regressão precisa de **mais um número relatado ao lado do erro: a direção do erro**,
como viés e como parte dos casos do lado caro. Sem ele, o modelo com o melhor MAE teria ido para o ar
como promessa de entrega, e as reclamações teriam começado no primeiro dia. A próxima seção pede o lado
diretamente.
