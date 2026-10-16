---
title: R², medido contra a média
version: 1
---

O **R²**, o coeficiente de determinação, compara os erros quadráticos do modelo com os da previsão mais
simples possível, a média da verdade:

`R² = 1 − sum((truth − prediction)²) / sum((truth − mean of truth)²)`

1 é perfeito. 0 é não ser melhor que prever a média. E apesar do quadrado no nome ele pode ser
**negativo**: um modelo pior que a média fica abaixo de zero. Escrever a fórmula deixa esses três
fatos fáceis de conferir. Salve isto como `r2.py`:

```python
# r2.py
import pandas as pd

predictions = pd.read_csv("predictions.csv")
truth = predictions["minutes"]

def r2(truth, guess):
    return 1 - ((truth - guess) ** 2).sum() / ((truth - truth.mean()) ** 2).sum()

print(f"the test months' own mean       R² {r2(truth, truth.mean()):6.3f}")
print(f"the median by hour              R² {r2(truth, predictions['by_hour']):6.3f}")
print(f"the line                        R² {r2(truth, predictions['line']):6.3f}")
usual = (truth - predictions["line"]).abs() <= 30
print(f"the line, without stuck ones    R² {r2(truth[usual], predictions['line'][usual]):6.3f}")
print(f"a constant of 60 minutes        R² {r2(truth, 60):6.3f}")
```

```
ana@lab:~/ml$ python r2.py
the test months' own mean       R²  0.000
the median by hour              R²  0.021
the line                        R²  0.397
the line, without stuck ones    R²  0.870
a constant of 60 minutes        R² -0.732
```

Três coisas para ler nele.

**O R² é o RMSE disfarçado.** É feito dos mesmos erros quadráticos, então ordena os modelos exatamente
como o RMSE nas mesmas linhas, e herda a mesma fraqueza: a reta explica 39,7% da variação com as
entregas paradas, e 87,0% sem elas. O modelo não melhorou entre as duas linhas; mudaram as linhas
sobre as quais ele foi perguntado.

**O R² depende das linhas tanto quanto do modelo.** O denominador é o quanto a verdade se espalha. O
mesmo modelo medido num conjunto de entregas muito parecidas tira um R² baixo, e num conjunto que
mistura viagens curtas e longas tira um alto, com exatamente os mesmos erros em minutos. Isso torna o
R² inútil para comparar modelos medidos em dados diferentes, e uma resposta fraca a "isto é bom o
bastante?". Quem gerencia a logística sabe julgar "erra cinco minutos". Ninguém sabe julgar "explica
40% da variância" sem saber o que havia para explicar.

**Abaixo de zero quer dizer pior que não saber nada.** Um palpite constante de 60 minutos tira −0,732.
Modelos de verdade chegam a R² negativo mais vezes do que as pessoas esperam, em geral em meses novos
que diferem dos que eles aprenderam, já que a média na fórmula do R² é a média das linhas de teste.
Esse número não estava disponível para o modelo, então vencê-lo não é garantido.

O R² vale a pena imprimir porque é o número que um estatístico espera ver, e porque um negativo é um
alarme. Como métrica principal de uma decisão, ele diz pouco.
