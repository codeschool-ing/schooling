---
title: Uma coluna de cada vez
version: 1
---

A primeira pergunta para qualquer coluna é a forma: onde fica o meio, quão larga é a dispersão,
quão longas são as caudas. O `describe` dá os números, e a assimetria diz para que lado a cauda
corre:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(d[['total', 'items']].describe().round(2).to_string()); print(round(d['total'].skew(), 1), round(d['items'].skew(), 1))"
          total     items
count  26510.00  26510.00
mean      94.06      3.47
std      248.91      1.64
min        0.00      1.00
25%       32.70      2.00
50%       57.60      3.00
75%      106.45      5.00
max    26928.50     13.00
64.0 0.3
```

**As duas colunas têm formas bem diferentes.** Itens por pedido, o número de linhas, vai de 1 a 13
com média de 3,47 e mediana de 3, e assimetria de 0,3: quase simétrica, uma coluna cuja média é um
resumo justo. O total vai de 0 a R$ 26.928,50, com mediana de R$ 57,60 e média de R$ 94,06, e
assimetria de 64. **Quando a média fica muito acima da mediana, a média está descrevendo a
cauda**: metade dos pedidos fica abaixo de R$ 57,60, e um "pedido médio de R$ 94" não descreveria
quase ninguém. O logaritmo da aula 12 é o jeito de olhar; aqui basta informar a mediana e os
quartis, R$ 32,70 e R$ 106,45.

Uma coluna de horários também tem forma, e contar por hora é o olhar mais simples:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(d.groupby('hour').size().to_string()); print(round(d['hour'].mean(), 1))"
hour
7      503
8      995
9     1576
10    2011
11    2021
12    1781
13    1512
14    1571
15    1638
16    1513
17    1771
18    2332
19    2660
20    2331
21    1495
22     800
15.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l15-hours\" aria-label=\"Um gráfico de barras dos pedidos entregues pela hora em que foram feitos, das 7 às 22 horas. As barras sobem até um platô às 10 e 11, caem depois do almoço e sobem de novo até a barra mais alta, às 19, com 2.660 pedidos. A hora média, 15, cai no vale entre as duas ondas.\"><path d=\"M70.0 230.0 L70.0 197.3 L108.8 197.3 L108.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M108.8 230.0 L108.8 165.4 L147.5 165.4 L147.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M147.5 230.0 L147.5 127.7 L186.2 127.7 L186.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M186.2 230.0 L186.2 99.4 L225.0 99.4 L225.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M225.0 230.0 L225.0 98.8 L263.8 98.8 L263.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M263.8 230.0 L263.8 114.4 L302.5 114.4 L302.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M302.5 230.0 L302.5 131.8 L341.2 131.8 L341.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M341.2 230.0 L341.2 128.0 L380.0 128.0 L380.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M380.0 230.0 L380.0 123.6 L418.8 123.6 L418.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M418.8 230.0 L418.8 131.8 L457.5 131.8 L457.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M457.5 230.0 L457.5 115.0 L496.2 115.0 L496.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M496.2 230.0 L496.2 78.6 L535.0 78.6 L535.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M535.0 230.0 L535.0 57.3 L573.8 57.3 L573.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M573.8 230.0 L573.8 78.6 L612.5 78.6 L612.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M612.5 230.0 L612.5 132.9 L651.2 132.9 L651.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M651.2 230.0 L651.2 178.1 L690.0 178.1 L690.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M70.0 230.0 L690.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M89.4 230.0 L89.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"89.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M128.1 230.0 L128.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"128.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M166.9 230.0 L166.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"166.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M205.6 230.0 L205.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"205.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M244.4 230.0 L244.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"244.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11</text><path d=\"M283.1 230.0 L283.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"283.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M321.9 230.0 L321.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"321.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><path d=\"M360.6 230.0 L360.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><path d=\"M399.4 230.0 L399.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"399.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M438.1 230.0 L438.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"438.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M476.9 230.0 L476.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"476.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17</text><path d=\"M515.6 230.0 L515.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"515.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M554.4 230.0 L554.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"554.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19</text><path d=\"M593.1 230.0 L593.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"593.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M631.9 230.0 L631.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"631.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21</text><path d=\"M670.6 230.0 L670.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"670.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22</text><text x=\"380.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">hora do dia</text><path d=\"M70.0 40.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 230.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 165.1 L690.0 165.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 165.1 L70.0 165.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"165.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.000</text><path d=\"M70.0 100.1 L690.0 100.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 100.1 L70.0 100.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"100.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.000</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos</text><path d=\"M399.4 230.0 L399.4 52.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"399.4\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">hora média</text></svg>", "caption": "Duas ondas, antes do almoço e depois do jantar. A hora média está certa na aritmética e não descreve nenhuma das duas."}
```

**Duas ondas**: uma crescendo pela manhã até um platô às 10 e 11 horas, e uma mais alta à noite, com
pico às 19, com 2.660 pedidos. A hora calma depois do almoço fica entre elas. A hora média,
na última linha, é 15,0: "os pedidos chegam por volta das 3 da tarde" é verdade na aritmética e cai
entre as ondas, numa hora que não é típica de nada.

Essa é a lição geral de olhar uma coluna: **um número-resumo só é honesto quando a forma é
simples**. Quando a forma tem duas corcovas ou uma cauda longa, a forma é a descoberta, e precisa
ser mostrada, não tirada a média.
