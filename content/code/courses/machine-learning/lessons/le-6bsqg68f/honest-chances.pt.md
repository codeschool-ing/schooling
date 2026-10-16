---
title: Se uma chance quer dizer o que diz
version: 1
---

A linha de equilíbrio funciona assim. Um crédito custa R$ 40 e vale R$ 144 quando chega a alguém que
sai, então ele se paga quando a chance de sair passa de 40 / 144 = 0,278. **Essa conta só está certa
se as chances forem honestas**: entre todos os assinantes a quem o modelo dá chance de 0,278, cerca
de 27,8% precisam sair de fato. Um modelo com essa propriedade é **calibrado**.

Nada no ajuste de um modelo promete isso. Um modelo é treinado para ordenar e separar, e suas chances
podem sair altas demais em toda parte, baixas demais em toda parte ou espremidas para o meio, enquanto
a ordenação continua boa como sempre. A AUC da aula 10 não vê nada disso, porque só olha a ordem.

A conferência é direta: ordene as linhas de teste pela chance, corte-as em dez grupos do mesmo
tamanho e, em cada grupo, compare a chance média com a parte que saiu de verdade. O scikit-learn faz o
agrupamento no `calibration_curve`. Salve isto como `reliability.py`:

```python
# reliability.py
import pandas as pd
from sklearn.calibration import calibration_curve

scores = pd.read_csv("scores.csv")
happened, said = calibration_curve(scores["churned"], scores["chance"],
                                   n_bins=10, strategy="quantile")
print("tenth   model said   happened")
for tenth, (s, h) in enumerate(zip(said, happened), start=1):
    print(f"{tenth:5}   {s:10.3f}   {h:8.3f}")
print(f"all     {scores['chance'].mean():10.3f}   {scores['churned'].mean():8.3f}")
```

```
ana@lab:~/ml$ python reliability.py
tenth   model said   happened
    1        0.010      0.010
    2        0.013      0.012
    3        0.016      0.015
    4        0.019      0.026
    5        0.023      0.028
    6        0.028      0.028
    7        0.034      0.040
    8        0.046      0.067
    9        0.074      0.093
   10        0.247      0.292
all          0.051      0.061
```

`strategy="quantile"` faz grupos do mesmo tamanho; o padrão faz grupos da mesma largura, o que numa
classe rara põe quase toda linha no primeiro grupo. Desenhado, cada grupo é um ponto, e os pontos de um
modelo calibrado ficam na diagonal:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 380\" role=\"img\" data-fig=\"l11-reliability\" aria-label=\"Um gráfico de confiabilidade. Cada um dos dez pontos é um décimo das linhas de teste: na horizontal, a chance média que o modelo deu; na vertical, a parte que cancelou de verdade. A diagonal tracejada é onde fica um modelo honesto. Os pontos baixos ficam nela; os três de cima ficam acima, o último em 0,247 na horizontal e 0,292 na vertical.\"><path d=\"M80.0 330.0 L420.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 330.0 L80.0 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,00</text><path d=\"M136.7 330.0 L136.7 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"136.7\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,05</text><path d=\"M193.3 330.0 L193.3 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"193.3\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,10</text><path d=\"M250.0 330.0 L250.0 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"250.0\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,15</text><path d=\"M306.7 330.0 L306.7 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"306.7\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,20</text><path d=\"M363.3 330.0 L363.3 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"363.3\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,25</text><path d=\"M420.0 330.0 L420.0 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"420.0\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,30</text><text x=\"250.0\" y=\"361.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o que o modelo disse</text><path d=\"M80.0 30.0 L80.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 330.0 L80.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"330.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,00</text><path d=\"M80.0 280.0 L420.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 280.0 L80.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,05</text><path d=\"M80.0 230.0 L420.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 230.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,10</text><path d=\"M80.0 180.0 L420.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 180.0 L80.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,15</text><path d=\"M80.0 130.0 L420.0 130.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 130.0 L80.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,20</text><path d=\"M80.0 80.0 L420.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 80.0 L80.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,25</text><path d=\"M80.0 30.0 L420.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 30.0 L80.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,30</text><text x=\"80.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o que aconteceu</text><path d=\"M80.0 330.0 L420.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"314.7\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">honesto</text><path d=\"M90.9 320.1 L94.6 317.6 L98.1 314.7 L101.4 304.0 L105.9 301.6 L111.3 301.6 L118.2 290.4 L131.6 262.8 L163.7 237.3 L359.7 38.2\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"90.9\" cy=\"320.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"94.6\" cy=\"317.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"98.1\" cy=\"314.7\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"101.4\" cy=\"304.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"105.9\" cy=\"301.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"111.3\" cy=\"301.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"118.2\" cy=\"290.4\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"131.6\" cy=\"262.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"163.7\" cy=\"237.3\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"359.7\" cy=\"38.2\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"349.7\" y=\"36.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">décimo de cima</text><text x=\"440.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">acima da linha:</text><text x=\"440.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">saiu mais gente</text><text x=\"440.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">que o modelo disse</text></svg>", "caption": "Honesto embaixo, baixo em cima, onde vão os créditos."}
```

A metade de baixo está perto: uma chance de 0,010 e 1,0% saiu. **Do sétimo décimo para cima, o modelo
diz menos do que aconteceu**, e no décimo de cima, para onde vai todo crédito, ele diz 0,247 onde 0,292
saiu. Somando os seis meses, ele previu 5,1% e 6,1% cancelaram.

Então as chances estão baixas, em cerca de um sexto, justo onde a decisão é tomada. Um assinante a
quem o modelo dá 0,24 está de fato mais perto de 0,28, já vale um crédito, e o corte de equilíbrio o
deixa de fora. É por isso que um corte abaixo de 0,278 deu mais dinheiro na aula 10. A causa é a
próxima pergunta, porque o remédio depende dela.
