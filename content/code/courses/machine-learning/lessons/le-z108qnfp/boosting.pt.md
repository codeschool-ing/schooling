---
title: Boosting, árvores que corrigem umas às outras
version: 1
---

Uma floresta cresce as árvores de forma independente e tira a média. O **boosting** as cresce uma
depois da outra, e cada árvore nova é ajustada aos erros das anteriores. A primeira árvore faz uma
previsão grosseira. A segunda é ajustada ao que a primeira errou, e a previsão dela é somada, em
escala menor. A terceira é ajustada ao que as duas primeiras juntas ainda erram, e assim por diante.
As árvores são pequenas, muitas vezes de três ou quatro níveis, e nenhuma presta sozinha; o modelo é
a soma delas.

O **gradient boosting** é a receita geral: "o que o modelo erra" é medido pela inclinação da perda,
então o mesmo método serve para erro quadrático, erro absoluto ou a perda logarítmica de um
classificador. A **taxa de aprendizado** (*learning rate*) é quanto de cada árvore nova é somado: uma
taxa pequena deixa cada passo cauteloso, precisa de mais árvores e normalmente termina melhor.

O jeito como ele constrói uma previsão é mais fácil de ver numa quantidade. Salve isto como
`boosting_steps.py`; o `staged_predict` dá a previsão depois de cada árvore, então um ajuste só mostra
todas:

```python
# boosting_steps.py
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
features = ["distance_km", "items", "hour", "rain", "driver_months"]
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]

boost = GradientBoostingRegressor(n_estimators=300, max_depth=3, learning_rate=0.1,
                                  loss="absolute_error", random_state=0)
boost.fit(train[features], train["minutes"])
errors = [np.abs(test["minutes"] - p).mean() for p in boost.staged_predict(test[features])]
for n in [1, 3, 10, 30, 100, 300]:
    print(f"after {n:3} trees: off by {errors[n - 1]:5.2f} minutes")
```

```
ana@lab:~/ml$ python boosting_steps.py
after   1 trees: off by 11.04 minutes
after   3 trees: off by 10.10 minutes
after  10 trees: off by  8.29 minutes
after  30 trees: off by  6.11 minutes
after 100 trees: off by  5.03 minutes
after 300 trees: off by  4.98 minutes
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 280\" role=\"img\" data-fig=\"l08-boost-curve\" aria-label=\"Erro médio em minutos nas entregas de teste contra o número de árvores do boosting, de 1 a 300. Começa perto de 11, cai rápido nas 50 primeiras árvores, cruza os 5,9 da reta e se achata logo abaixo de 5.\"><path d=\"M60.0 30.0 L60.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M56.0 230.0 L60.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 196.7 L560.0 196.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 196.7 L60.0 196.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"196.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M60.0 163.3 L560.0 163.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 163.3 L60.0 163.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"163.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M60.0 130.0 L560.0 130.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 130.0 L60.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M60.0 96.7 L560.0 96.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 96.7 L60.0 96.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"96.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M60.0 63.3 L560.0 63.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 63.3 L60.0 63.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"63.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M60.0 30.0 L560.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 30.0 L60.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutos de erro, em média</text><path d=\"M60.0 230.0 L560.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 230.0 L60.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M143.3 230.0 L143.3 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"143.3\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M226.7 230.0 L226.7 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"226.7\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M310.0 230.0 L310.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"310.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><path d=\"M393.3 230.0 L393.3 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"393.3\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M476.7 230.0 L476.7 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"476.7\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">250</text><path d=\"M560.0 230.0 L560.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><text x=\"310.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">árvores somadas</text><path d=\"M61.7 46.1 L63.3 54.5 L65.0 61.7 L66.7 67.6 L68.3 72.8 L70.0 77.7 L71.7 82.0 L73.3 85.4 L75.0 88.4 L76.7 91.8 L78.3 94.6 L80.0 97.6 L81.7 99.5 L83.3 102.4 L85.0 104.4 L86.7 106.8 L88.3 110.1 L90.0 111.5 L91.7 113.1 L93.3 114.4 L95.0 117.2 L96.7 118.2 L98.3 119.6 L100.0 121.2 L101.7 122.6 L103.3 123.8 L105.0 124.5 L106.7 126.5 L108.3 127.2 L110.0 128.1 L111.7 129.2 L113.3 129.8 L115.0 130.4 L116.7 131.0 L118.3 131.8 L120.0 132.2 L121.7 132.8 L123.3 133.3 L125.0 133.6 L126.7 134.1 L128.3 134.7 L130.0 135.0 L131.7 135.4 L133.3 136.3 L135.0 136.7 L136.7 137.0 L138.3 137.5 L140.0 137.8 L141.7 138.2 L143.3 138.6 L145.0 138.8 L146.7 139.0 L148.3 139.3 L150.0 140.1 L151.7 140.6 L153.3 140.9 L155.0 141.1 L156.7 141.2 L158.3 141.5 L160.0 141.8 L161.7 142.0 L163.3 142.2 L165.0 142.4 L166.7 142.6 L168.3 142.9 L170.0 143.0 L171.7 143.2 L173.3 143.5 L175.0 143.6 L176.7 143.8 L178.3 144.0 L180.0 144.1 L181.7 144.2 L183.3 144.3 L185.0 144.4 L186.7 144.6 L188.3 144.6 L190.0 144.7 L191.7 144.9 L193.3 145.0 L195.0 145.2 L196.7 145.2 L198.3 145.3 L200.0 145.3 L201.7 145.3 L203.3 145.4 L205.0 145.4 L206.7 145.5 L208.3 145.6 L210.0 145.6 L211.7 145.7 L213.3 145.7 L215.0 145.8 L216.7 145.8 L218.3 145.9 L220.0 145.9 L221.7 146.0 L223.3 146.0 L225.0 146.1 L226.7 146.1 L228.3 146.2 L230.0 146.2 L231.7 146.3 L233.3 146.3 L235.0 146.3 L236.7 146.3 L238.3 146.4 L240.0 146.4 L241.7 146.4 L243.3 146.5 L245.0 146.5 L246.7 146.5 L248.3 146.5 L250.0 146.5 L251.7 146.5 L253.3 146.5 L255.0 146.5 L256.7 146.5 L258.3 146.6 L260.0 146.6 L261.7 146.6 L263.3 146.6 L265.0 146.6 L266.7 146.6 L268.3 146.6 L270.0 146.6 L271.7 146.6 L273.3 146.7 L275.0 146.7 L276.7 146.7 L278.3 146.7 L280.0 146.7 L281.7 146.7 L283.3 146.7 L285.0 146.7 L286.7 146.7 L288.3 146.7 L290.0 146.7 L291.7 146.7 L293.3 146.8 L295.0 146.8 L296.7 146.8 L298.3 146.8 L300.0 146.8 L301.7 146.8 L303.3 146.8 L305.0 146.8 L306.7 146.8 L308.3 146.8 L310.0 146.8 L311.7 146.8 L313.3 146.8 L315.0 146.8 L316.7 146.8 L318.3 146.8 L320.0 146.8 L321.7 146.8 L323.3 146.8 L325.0 146.8 L326.7 146.8 L328.3 146.8 L330.0 146.8 L331.7 146.8 L333.3 146.8 L335.0 146.8 L336.7 146.8 L338.3 146.8 L340.0 146.8 L341.7 146.8 L343.3 146.8 L345.0 146.8 L346.7 146.8 L348.3 146.8 L350.0 146.8 L351.7 146.8 L353.3 146.8 L355.0 146.8 L356.7 146.8 L358.3 146.8 L360.0 146.8 L361.7 146.8 L363.3 146.8 L365.0 146.8 L366.7 146.8 L368.3 146.8 L370.0 146.8 L371.7 146.8 L373.3 146.8 L375.0 146.8 L376.7 146.8 L378.3 146.8 L380.0 146.9 L381.7 146.9 L383.3 146.9 L385.0 146.9 L386.7 146.9 L388.3 146.9 L390.0 146.9 L391.7 146.9 L393.3 146.9 L395.0 146.9 L396.7 146.9 L398.3 146.9 L400.0 146.9 L401.7 146.9 L403.3 146.9 L405.0 146.9 L406.7 146.9 L408.3 147.0 L410.0 147.0 L411.7 147.0 L413.3 146.9 L415.0 146.9 L416.7 146.9 L418.3 146.9 L420.0 146.9 L421.7 146.9 L423.3 146.9 L425.0 147.0 L426.7 147.0 L428.3 147.0 L430.0 147.0 L431.7 147.0 L433.3 146.9 L435.0 146.9 L436.7 146.9 L438.3 146.9 L440.0 146.9 L441.7 146.9 L443.3 147.0 L445.0 147.0 L446.7 147.0 L448.3 147.0 L450.0 147.0 L451.7 147.0 L453.3 147.0 L455.0 147.0 L456.7 147.0 L458.3 147.0 L460.0 147.0 L461.7 146.9 L463.3 146.9 L465.0 147.0 L466.7 146.9 L468.3 147.0 L470.0 147.0 L471.7 146.9 L473.3 146.9 L475.0 146.9 L476.7 146.9 L478.3 146.9 L480.0 146.9 L481.7 146.9 L483.3 146.9 L485.0 146.9 L486.7 147.0 L488.3 147.0 L490.0 146.9 L491.7 147.0 L493.3 147.0 L495.0 147.0 L496.7 147.0 L498.3 147.0 L500.0 147.0 L501.7 147.0 L503.3 147.0 L505.0 147.0 L506.7 147.0 L508.3 147.0 L510.0 147.0 L511.7 147.0 L513.3 147.0 L515.0 147.0 L516.7 147.0 L518.3 147.0 L520.0 147.0 L521.7 147.0 L523.3 147.0 L525.0 147.0 L526.7 147.0 L528.3 147.0 L530.0 147.0 L531.7 147.0 L533.3 147.0 L535.0 147.0 L536.7 147.0 L538.3 147.0 L540.0 147.0 L541.7 147.0 L543.3 147.0 L545.0 147.0 L546.7 147.0 L548.3 147.0 L550.0 147.0 L551.7 147.0 L553.3 147.0 L555.0 147.0 L556.7 147.0 L558.3 147.0 L560.0 147.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M60.0 131.7 L560.0 131.7\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560.0\" y=\"121.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a reta da aula 5: 5,9</text></svg>", "caption": "Cada árvore é uma pequena correção. Quase todo o ganho vem nas cem primeiras, e o resto é polimento."}
```

**Uma árvore erra por 11 minutos, mais ou menos tão mal quanto a mediana da aula 2.** Cada árvore
soma uma pequena correção, e depois de cem o modelo erra por 5,03 minutos, o que supera a reta da aula
5, com 5,9. A reta tinha a forma certa para a maior parte dos dados; o boosting acha a mesma
inclinação como uma soma de muitos passos pequenos, e também as partes que a reta não via, como a
chuva pesar mais em viagens longas.

A curva se achata: de 100 para 300 árvores o erro se mexe cinco centésimos de minuto. Nestes dados
nada pior acontece. Com uma taxa maior ou árvores mais fundas, o erro de teste pode virar e subir,
porque o boosting, ao contrário do bagging, **pode sobreajustar acrescentando árvores**: cada árvore é
ajustada aos erros que restam, e quando o sinal acaba, o que resta é ruído. A próxima seção é como
parar no momento certo.

O `loss="absolute_error"` ajusta a mediana em vez da média a cada passo, para a entrega ocasional de
duas horas não puxar toda previsão para cima. A aula 12 trata do que cada escolha de erro premia.
