---
title: RMSE, e as entregas que ninguém prevê
version: 1
---

A **raiz do erro quadrático médio** eleva cada erro ao quadrado antes da média, e depois tira a raiz
para trazer a unidade de volta a minutos:

`RMSE = √ mean((truth − prediction)²)`

Elevar ao quadrado muda quem conta. Um erro de 10 minutos contribui 100, um de 60 contribui 3.600:
**uma entrega com uma hora de erro pesa tanto quanto trinta e seis com dez minutos.** O RMSE é a
métrica para problemas em que um erro grande é muito pior que vários pequenos, e é a que a maioria
das bibliotecas ajusta por padrão.

Nas entregas isso é um problema, porque os erros grandes aqui não são culpa do modelo. A aula 2
notou que algumas entregas levam uma ou duas horas a mais que o normal: um pneu furado, um endereço
errado. Nenhuma coluna do arquivo diz quais, então nenhum modelo as vê chegando. Conte-as, e dê preço
às duas métricas com e sem elas. Salve isto como `outliers.py`:

```python
# outliers.py
import pandas as pd

predictions = pd.read_csv("predictions.csv")

def mae(error):
    return error.abs().mean()

def rmse(error):
    return (error ** 2).mean() ** 0.5

print("                  all deliveries         without the stuck ones")
print("model              MAE    RMSE   stuck      MAE    RMSE")
for model in ["line", "boost_absolute"]:
    error = predictions["minutes"] - predictions[model]
    usual = error.abs() <= 30
    print(f"{model:15} {mae(error):6.2f}  {rmse(error):6.2f}  {(~usual).sum():6}    "
          f"{mae(error[usual]):6.2f}  {rmse(error[usual]):6.2f}")
```

```
ana@lab:~/ml$ python outliers.py
                  all deliveries         without the stuck ones
model              MAE    RMSE   stuck      MAE    RMSE
line              5.87   14.25      46      3.76    4.58
boost_absolute    5.02   14.43      49      2.76    3.71
```

**Cerca de 3% das entregas erram por mais de meia hora, e elas são o RMSE.** Com elas, os dois
modelos tiram cerca de 14 minutos e a reta passa na frente por pouco. Sem elas, o RMSE cai para menos
de 5 nos dois, e o `boost_absolute` fica à frente nas duas métricas por cerca de um minuto, o mesmo
veredito que o MAE deu desde o começo. As 46 ou 49 entregas paradas entre 1.540 decidem a ordem do
RMSE, e são as entregas que menos servem para ordenar modelos, porque nenhum modelo poderia saber.

O retrato é a forma dos erros. A maioria fica num morro estreito em torno de zero; uma cauda fina vai
para a direita, onde a van quebrou:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 340\" role=\"img\" data-fig=\"l12-errors\" aria-label=\"Um histograma dos erros do boost_absolute nas 1.540 entregas de teste, verdade menos previsão, em faixas de cinco minutos de −25 a 130 minutos, numa escala de raiz quadrada para as barras raras aparecerem. Quase todos os erros ficam num morro entre −10 e +15 minutos. Uma cauda fina de barras âmbar pequenas vai até 130 minutos de atraso: as 49 entregas com mais de meia hora de erro.\"><path d=\"M70.0 280.0 L580.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M86.5 280.0 L86.5 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"86.5\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-20</text><path d=\"M152.3 280.0 L152.3 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"152.3\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M218.1 280.0 L218.1 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"218.1\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M283.9 280.0 L283.9 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"283.9\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M349.7 280.0 L349.7 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"349.7\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M415.5 280.0 L415.5 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"415.5\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><path d=\"M481.3 280.0 L481.3 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"481.3\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M547.1 280.0 L547.1 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"547.1\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><text x=\"325.0\" y=\"311.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutos de atraso (verdade − previsão)</text><path d=\"M70.0 30.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 280.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 252.1 L580.0 252.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 252.1 L70.0 252.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"252.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M70.0 217.7 L580.0 217.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 217.7 L70.0 217.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"217.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M70.0 191.9 L580.0 191.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 191.9 L70.0 191.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"191.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M70.0 155.4 L580.0 155.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 155.4 L70.0 155.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"155.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M70.0 103.8 L580.0 103.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 103.8 L70.0 103.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"103.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M70.0 64.1 L580.0 64.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 64.1 L70.0 64.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"64.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><text x=\"70.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">entregas (escala de raiz quadrada)</text><path d=\"M102.9 280.0 L102.9 267.5 L119.4 267.5 L119.4 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M119.4 280.0 L119.4 231.7 L135.8 231.7 L135.8 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M135.8 280.0 L135.8 41.9 L152.3 41.9 L152.3 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M152.3 280.0 L152.3 70.7 L168.7 70.7 L168.7 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M168.7 280.0 L168.7 176.9 L185.2 176.9 L185.2 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M185.2 280.0 L185.2 235.9 L201.6 235.9 L201.6 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M201.6 280.0 L201.6 267.5 L218.1 267.5 L218.1 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M234.5 280.0 L234.5 271.2 L251.0 271.2 L251.0 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M251.0 280.0 L251.0 262.4 L267.4 262.4 L267.4 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M267.4 280.0 L267.4 262.4 L283.9 262.4 L283.9 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M283.9 280.0 L283.9 271.2 L300.3 271.2 L300.3 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M316.8 280.0 L316.8 264.7 L333.2 264.7 L333.2 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M333.2 280.0 L333.2 255.1 L349.7 255.1 L349.7 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M349.7 280.0 L349.7 271.2 L366.1 271.2 L366.1 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M366.1 280.0 L366.1 264.7 L382.6 264.7 L382.6 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M382.6 280.0 L382.6 271.2 L399.0 271.2 L399.0 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M399.0 280.0 L399.0 264.7 L415.5 264.7 L415.5 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M415.5 280.0 L415.5 267.5 L431.9 267.5 L431.9 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M431.9 280.0 L431.9 264.7 L448.4 264.7 L448.4 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M448.4 280.0 L448.4 260.3 L464.8 260.3 L464.8 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M464.8 280.0 L464.8 271.2 L481.3 271.2 L481.3 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M481.3 280.0 L481.3 267.5 L497.7 267.5 L497.7 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M497.7 280.0 L497.7 264.7 L514.2 264.7 L514.2 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M514.2 280.0 L514.2 271.2 L530.6 271.2 L530.6 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M530.6 280.0 L530.6 262.4 L547.1 262.4 L547.1 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M152.3 280.0 L152.3 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"415.5\" y=\"211.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">49 entregas paradas, mais de</text><text x=\"415.5\" y=\"226.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">meia hora de erro: quase todo o RMSE</text></svg>", "caption": "Um morro que o MAE descreve, e uma cauda de que o RMSE é feito quase todo."}
```

Então o RMSE responde a uma pergunta diferente da do MAE, e a escolha entre eles é uma pergunta sobre
o negócio:

- **Se um erro grande é muito pior que vários pequenos**, eleve os erros ao quadrado. Uma previsão de
  quanto estoque pedir, em que faltar custa um dia de vendas, é assim.
- **Se todo minuto de atraso é mais ou menos tão ruim quanto outro**, use o MAE. A maioria das
  promessas a uma pessoa é assim, até certo ponto.
- **Se os erros grandes são aleatórios e não são culpa de ninguém**, o RMSE vai gastar a atenção com
  eles. Relate-o se alguém pedir, mas não escolha modelo por ele.

Mais uma propriedade sai do quadrado: **o RMSE nunca é menor que o MAE**, e a distância entre eles diz
quão pesada é a cauda. Aqui o RMSE é quase o triplo do MAE. Com erros todos de tamanho parecido, os
dois seriam quase iguais.
