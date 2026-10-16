---
title: Somado ou multiplicado
version: 1
---

Antes de desmontar uma série você precisa dizer como as partes foram montadas. Há dois jeitos, e
escolher o errado dá uma sazonalidade errada nas duas pontas do dado.

- **Aditivo**: a série é tendência + sazonalidade + ruído. Uma segunda fica um número fixo de
  pedidos acima do nível, qualquer que seja o nível.
- **Multiplicativo**: a série é tendência × sazonalidade × ruído. Uma segunda fica uma *proporção*
  fixa acima do nível, então, conforme o negócio cresce, a diferença em pedidos cresce junto.

O teste é ver se a oscilação cresce com o nível. Isto compara segundas e sábados em cada ano:

```schooling-example
{"language": "python", "file": "swing.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]"}, {"code": "monday = orders[orders.index.dayofweek == 0]\nsaturday = orders[orders.index.dayofweek == 5]\nyears = pd.DataFrame({\n    \"monday\": monday.groupby(monday.index.year).mean(),\n    \"saturday\": saturday.groupby(saturday.index.year).mean(),\n})", "note": "Tira a média de todas as segundas e de todos os sábados, separadamente para cada ano."}, {"code": "years[\"difference\"] = years[\"monday\"] - years[\"saturday\"]\nyears[\"ratio\"] = years[\"monday\"] / years[\"saturday\"]\nprint(years.round(2).rename_axis(None).to_string())", "note": "A diferença é a oscilação em pedidos; a razão é a oscilação como proporção do nível."}], "output": "       monday  saturday  difference  ratio\n2023  1121.00    825.12      295.88   1.36\n2024  1441.89   1063.73      378.16   1.36\n2025  1639.17   1194.27      444.90   1.37"}
```

**A diferença cresce pela metade enquanto a razão quase não se mexe.** Uma segunda ficava 296
pedidos acima de um sábado em 2023 e 445 em 2025, mas nos dois anos ficava cerca de 36 por cento
acima. A sazonalidade da Panela é multiplicativa, como a da maioria das séries de negócio: uma
empresa maior tem uma segunda maior.

Um modelo aditivo ajustado aqui usaria uma diferença média para os três anos, cerca de 373 pedidos,
e assim subestimaria a oscilação semanal em 2025 e superestimaria em 2023. Os resíduos mostrariam:
uma ondulação semanal, negativa numa ponta do dado e positiva na outra.

## O logaritmo transforma um no outro

O logaritmo de um produto é a soma dos logaritmos, então **uma série multiplicativa vira aditiva
quando você tira o log dela**. É por isso que tantos programas de séries temporais começam com
`np.log(series)`: um método que só sabe somar passa a lidar com uma sazonalidade que multiplica, e
os resultados voltam com `np.exp`. A decomposição STL de duas seções adiante faz exatamente isso.

Numa escala logarítmica, uma razão constante é uma distância constante. Uma série cujas oscilações
parecem crescer num gráfico comum, e parecem estáveis num gráfico logarítmico, é multiplicativa.
