---
title: Lendo os pesos em voz alta
version: 1
---

O resultado do `linear.py` é uma frase esperando ser dita. Cada peso é **quantos minutos a previsão
se mexe quando aquela coluna sobe uma unidade e todas as outras ficam onde estão**:

| coluna | peso | lido em voz alta |
|---|---|---|
| intercepto | 18,32 | uma entrega de zero quilômetro, zero item, fora do pico, sem chuva, feita por um motorista novato levaria uns 18 minutos: a parte fixa |
| `distance_km` | +2,60 | cada quilômetro soma uns dois minutos e meio |
| `items` | +0,37 | cada item soma uns vinte segundos; trinta itens, onze minutos |
| `rush` | +9,57 | um horário de pico soma quase dez minutos |
| `rain` | +11,23 | a chuva soma uns onze minutos |
| `driver_months` | −0,07 | cada mês de experiência economiza uns quatro segundos |

**"Todas as outras ficam onde estão" é a parte que as pessoas esquecem**, e ela muda o sentido. O
peso da chuva é o que a chuva soma *a uma entrega da mesma distância, na mesma hora, com o mesmo
motorista*. Se os dias de chuva também tivessem rotas mais longas, a simples diferença entre entregas
com e sem chuva misturaria as duas coisas, e o peso as separa. Essa separação é o mais útil que um
modelo linear faz, e ela só vale para as colunas que o modelo recebeu.

O intercepto é outro tipo de número. É uma previsão para uma entrega com todas as colunas em zero,
que pode nem existir: ninguém entrega zero quilômetro. **Leia-o como a parte fixa da reta, não como um
fato sobre alguma entrega real.**

## O que a reta não enxerga

Um modelo linear soma seus termos. Ele não consegue dizer "a chuva custa mais numa viagem longa do
que numa curta", porque o peso da chuva é um número só, seja qual for a distância. Se a chuva funciona
assim, o modelo precisa ser avisado, com uma coluna que é o produto das duas. Salve isto como
`interaction.py`:

```python
# interaction.py
import pandas as pd
from sklearn.linear_model import LinearRegression

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
deliveries["rush"] = deliveries["hour"].isin([11, 12, 17, 18, 19]).astype(int)
deliveries["rain_km"] = deliveries["rain"] * deliveries["distance_km"]
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]

for features in [["distance_km", "items", "rush", "rain", "driver_months"],
                 ["distance_km", "items", "rush", "rain", "driver_months", "rain_km"]]:
    line = LinearRegression().fit(train[features], train["minutes"])
    error = (test["minutes"] - line.predict(test[features])).abs().mean()
    coefs = dict(zip(features, line.coef_.round(2)))
    print(f"MAE {error:.2f}  rain {coefs['rain']:+.2f}  km {coefs['distance_km']:+.2f}"
          + (f"  rain_km {coefs['rain_km']:+.2f}" if "rain_km" in coefs else ""))
```

```
ana@lab:~/ml$ python interaction.py
MAE 5.87  rain +11.23  km +2.60
MAE 5.71  rain +3.55  km +2.38  rain_km +1.30
```

Com o produto `rain_km` acrescentado, o erro cai de 5,87 para 5,71, e a história muda: a chuva agora
soma **3,55 minutos mais 1,30 por quilômetro**, então 5 minutos numa viagem curta e 16 numa de dez
quilômetros, onde o primeiro modelo dizia 11 para as duas. A coluna nova é uma **interação**, e um
modelo linear só tem as que recebe. As árvores da aula 7 acham interações sozinhas, que é um dos
motivos de costumarem vencer, e um dos motivos de serem mais difíceis de ler.

Dois avisos sobre ler pesos, e a aula volta aos dois:

- **Um peso não é uma causa.** A chuva não causa minutos como uma alavanca; o peso é a diferença que
  os dados mostram, mantendo fixo só o que está no modelo. A aula 19 trata da distância entre o que
  um modelo usa e o que faz as coisas acontecerem.
- **Pesos só se comparam na mesma escala.** +2,60 por quilômetro e +0,37 por item não se comparam,
  porque um quilômetro e um item não são a mesma quantidade de nada. A seção 07 desta aula põe as
  colunas na mesma escala para que se comparem.
