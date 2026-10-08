---
title: O plano
version: 1
---

Três fatos das aulas 10 e 11 decidem o plano: o apetite do daniel, *no máximo 10% de chance de perder
mais de R$ 500.000 num ano*; a curva de hoje, que passa acima dele com 14,1%; e a ordenação dos
controles por valor. A pergunta é o menor conjunto de controles que traz a curva para baixo do ponto.

Pegando os controles na ordem da ordenação, os quatro primeiros são C5, C1, C8 e C4, juntos R$ 5.700
por ano. Aplicados com o `prioritise.py` e simulados com o `fair.py` da aula 10:

```
(.venv) ana@vm:~/tm/portal-model$ python3 prioritise.py C5 C1 C8 C4 > after/risks.csv
(.venv) ana@vm:~/tm/portal-model$ cd after && python3 ../fair.py | tail -7
all      79,847     99.9%       193,381     780,699

chance that one year's total loss is more than
  R$   100,000   16.4%
  R$   250,000    7.7%
  R$   500,000    2.7%
  R$ 1,000,000    0.5%
```

**2,7%, abaixo do ponto.** Quatro controles, menos de R$ 6.000 por ano, bastam sozinhos para atender
o apetite. Acrescentando os outros cinco cujo valor passa do custo, os nove juntos, R$ 17.200 por
ano:

```
(.venv) ana@vm:~/tm/portal-model$ python3 prioritise.py C5 C1 C8 C4 C3 C9 C10 C7 C2 > after/risks.csv
(.venv) ana@vm:~/tm/portal-model$ cd after && python3 ../fair.py | tail -12
T08         629     19.4%         2,241       9,354
T10         468     10.9%         1,142       9,059
T11         682     32.7%         2,349       7,042
T13       4,447      0.9%             0           0
T14      18,239      9.9%             0     388,419
all      43,081     93.7%       104,281     636,270

chance that one year's total loss is more than
  R$   100,000   10.2%
  R$   250,000    4.6%
  R$   500,000    1.6%
  R$ 1,000,000    0.3%
```

A curva cai mais, para 1,6% em R$ 500.000, e a perda anual média cai de R$ 241.376 para R$ 43.081. A
pasta de rascunho vai embora quando a conta termina:

```
(.venv) ana@vm:~/tm/portal-model$ rm -r after
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l11-curves\" aria-label=\"Três curvas de excedência de perdas nos mesmos eixos. Hoje: 14,1% de chance de perder mais de 500.000 reais num ano, acima do ponto de tolerância do daniel, de 10%. Com os quatro primeiros controles pela razão, custando 5.700 reais por ano: 2,7%, abaixo do ponto. Com todos os nove controles que valem o custo, 17.200 por ano: 1,6%.\"><path d=\"M80.0 260.0 L690.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 25.0 L80.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"72.0\" y=\"201.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25%</text><path d=\"M80.0 201.2 L690.0 201.2\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"142.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M80.0 142.5 L690.0 142.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"83.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><path d=\"M80.0 83.8 L690.0 83.8\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"25.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M80.0 25.0 L690.0 25.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"80.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.000</text><text x=\"326.3\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100.000</text><text x=\"572.5\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.000.000</text><path d=\"M80.0 31.6 L85.1 32.4 L90.2 33.3 L95.3 34.4 L100.3 35.4 L105.4 36.5 L110.5 37.8 L115.6 39.0 L120.7 40.7 L125.7 42.5 L130.8 44.3 L135.9 46.0 L141.0 47.6 L146.1 49.9 L151.2 52.1 L156.2 54.2 L161.3 56.8 L166.4 59.9 L171.5 62.9 L176.6 65.7 L181.7 68.5 L186.8 71.2 L191.8 74.9 L196.9 78.5 L202.0 82.0 L207.1 85.5 L212.2 88.6 L217.2 92.2 L222.3 96.0 L227.4 99.4 L232.5 102.7 L237.6 106.3 L242.7 110.0 L247.8 113.1 L252.8 116.3 L257.9 119.2 L263.0 122.2 L268.1 125.0 L273.2 127.3 L278.2 130.1 L283.3 132.6 L288.4 134.7 L293.5 137.1 L298.6 139.4 L303.7 141.3 L308.8 143.4 L313.8 145.8 L318.9 148.1 L324.0 150.2 L329.1 152.7 L334.2 154.7 L339.3 156.9 L344.3 159.3 L349.4 161.5 L354.5 163.5 L359.6 165.7 L364.7 167.6 L369.7 169.6 L374.8 172.0 L379.9 174.7 L385.0 177.2 L390.1 179.2 L395.2 181.8 L400.2 183.6 L405.3 185.6 L410.4 187.6 L415.5 190.0 L420.6 192.3 L425.7 194.7 L430.7 197.1 L435.8 199.8 L440.9 202.0 L446.0 204.5 L451.1 206.7 L456.2 208.9 L461.2 211.2 L466.3 213.4 L471.4 215.6 L476.5 217.5 L481.6 219.7 L486.7 221.6 L491.8 224.4 L496.8 226.2 L501.9 228.2 L507.0 230.3 L512.1 231.9 L517.2 233.6 L522.2 235.2 L527.3 237.0 L532.4 238.7 L537.5 239.9 L542.6 241.3 L547.7 242.6 L552.8 243.5 L557.8 245.1 L562.9 246.5 L568.0 247.7 L573.1 248.9 L578.2 249.8 L583.2 250.6 L588.3 251.7 L593.4 252.6 L598.5 253.6 L603.6 254.1 L608.7 254.9 L613.8 255.4 L618.8 256.0 L623.9 256.3 L629.0 256.6 L634.1 257.2 L639.2 257.5 L644.3 258.0 L649.3 258.3 L654.4 258.6 L659.5 258.8 L664.6 258.9 L669.7 259.0 L674.8 259.2 L679.8 259.4 L684.9 259.5 L690.0 259.6\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520.0 60.0 L550.0 60.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"558.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">hoje</text><path d=\"M80.0 49.3 L85.1 51.6 L90.2 54.0 L95.3 56.5 L100.3 59.0 L105.4 62.4 L110.5 65.1 L115.6 67.6 L120.7 71.4 L125.7 74.8 L130.8 78.7 L135.9 83.0 L141.0 87.3 L146.1 92.0 L151.2 96.9 L156.2 102.1 L161.3 106.7 L166.4 111.8 L171.5 116.3 L176.6 121.2 L181.7 126.7 L186.8 132.0 L191.8 136.7 L196.9 141.0 L202.0 146.2 L207.1 151.3 L212.2 156.4 L217.2 161.5 L222.3 166.5 L227.4 170.9 L232.5 175.3 L237.6 179.2 L242.7 182.7 L247.8 186.0 L252.8 189.2 L257.9 192.5 L263.0 195.6 L268.1 198.5 L273.2 201.6 L278.2 204.3 L283.3 206.5 L288.4 208.8 L293.5 211.3 L298.6 213.1 L303.7 215.0 L308.8 216.9 L313.8 218.4 L318.9 219.7 L324.0 221.0 L329.1 222.4 L334.2 223.7 L339.3 225.1 L344.3 226.4 L349.4 227.4 L354.5 228.6 L359.6 229.7 L364.7 230.8 L369.7 231.7 L374.8 232.5 L379.9 233.3 L385.0 234.3 L390.1 235.4 L395.2 236.2 L400.2 237.1 L405.3 238.2 L410.4 239.2 L415.5 240.2 L420.6 241.1 L425.7 242.1 L430.7 243.1 L435.8 244.1 L440.9 245.2 L446.0 246.2 L451.1 247.2 L456.2 248.0 L461.2 248.7 L466.3 249.4 L471.4 250.4 L476.5 251.1 L481.6 251.9 L486.7 252.6 L491.8 253.0 L496.8 253.6 L501.9 254.1 L507.0 254.5 L512.1 255.1 L517.2 255.7 L522.2 256.0 L527.3 256.4 L532.4 256.7 L537.5 257.0 L542.6 257.4 L547.7 257.7 L552.8 258.0 L557.8 258.2 L562.9 258.4 L568.0 258.5 L573.1 258.8 L578.2 258.8 L583.2 259.0 L588.3 259.0 L593.4 259.1 L598.5 259.3 L603.6 259.3 L608.7 259.4 L613.8 259.5 L618.8 259.6 L623.9 259.6 L629.0 259.7 L634.1 259.7 L639.2 259.8 L644.3 259.8 L649.3 259.9 L654.4 259.9 L659.5 259.9 L664.6 259.9 L669.7 259.9 L674.8 259.9 L679.8 259.9 L684.9 259.9 L690.0 259.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M520.0 78.0 L550.0 78.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"558.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quatro primeiros</text><path d=\"M80.0 180.5 L85.1 184.4 L90.2 187.5 L95.3 190.6 L100.3 193.7 L105.4 196.8 L110.5 199.7 L115.6 202.6 L120.7 205.1 L125.7 207.5 L130.8 209.5 L135.9 210.9 L141.0 212.6 L146.1 214.2 L151.2 215.3 L156.2 216.3 L161.3 217.4 L166.4 218.4 L171.5 219.1 L176.6 219.8 L181.7 220.6 L186.8 221.4 L191.8 221.9 L196.9 222.5 L202.0 223.1 L207.1 223.6 L212.2 224.1 L217.2 224.6 L222.3 224.9 L227.4 225.3 L232.5 225.6 L237.6 226.0 L242.7 226.5 L247.8 227.0 L252.8 227.5 L257.9 227.9 L263.0 228.5 L268.1 228.9 L273.2 229.4 L278.2 230.0 L283.3 230.6 L288.4 231.0 L293.5 231.7 L298.6 232.3 L303.7 232.8 L308.8 233.6 L313.8 234.2 L318.9 234.9 L324.0 235.7 L329.1 236.4 L334.2 236.9 L339.3 237.6 L344.3 238.1 L349.4 239.0 L354.5 239.7 L359.6 240.6 L364.7 241.2 L369.7 242.2 L374.8 242.9 L379.9 243.5 L385.0 244.2 L390.1 244.9 L395.2 245.6 L400.2 246.3 L405.3 247.1 L410.4 247.9 L415.5 248.2 L420.6 248.7 L425.7 249.2 L430.7 249.8 L435.8 250.3 L440.9 251.1 L446.0 251.6 L451.1 252.1 L456.2 252.6 L461.2 253.1 L466.3 253.5 L471.4 253.9 L476.5 254.3 L481.6 254.8 L486.7 255.2 L491.8 255.6 L496.8 256.0 L501.9 256.5 L507.0 256.6 L512.1 256.9 L517.2 257.3 L522.2 257.5 L527.3 257.8 L532.4 258.0 L537.5 258.2 L542.6 258.4 L547.7 258.6 L552.8 258.7 L557.8 258.8 L562.9 259.0 L568.0 259.1 L573.1 259.2 L578.2 259.2 L583.2 259.3 L588.3 259.4 L593.4 259.5 L598.5 259.5 L603.6 259.6 L608.7 259.6 L613.8 259.7 L618.8 259.8 L623.9 259.8 L629.0 259.9 L634.1 259.9 L639.2 259.9 L644.3 259.9 L649.3 259.9 L654.4 259.9 L659.5 259.9 L664.6 259.9 L669.7 259.9 L674.8 259.9 L679.8 259.9 L684.9 259.9 L690.0 259.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520.0 96.0 L550.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"558.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os nove</text><circle cx=\"498.4\" cy=\"236.5\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"506.4\" y=\"226.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">tolerância</text><text x=\"385.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">perda total em um ano, R$ (escala log)</text></svg>", "caption": "Quatro controles custando R$ 5.700 por ano trazem a curva para baixo do ponto do daniel. Os outros cinco também valem o custo, e não são eles que atendem o apetite."}
```

### Como o plano fica

| fase | controles | custo por ano | por quê |
|---|---|---|---|
| 1, este mês | C5, C1, C8, C4 | R$ 5.700 | o melhor negócio, e o bastante para atender o apetite do daniel |
| 2, este trimestre | C3, C9, C10, C7, C2 | R$ 11.500 | cada um economiza mais do que custa; o C3 fecha a T01, a falha de onde este curso partiu |
| 3, decidido à parte | C11 | R$ 3.500 | não vale para a T03 depois do C1 e do C2; feito mesmo assim pela LGPD (seção anterior) |
| não comprado | C6 | | custa mais do que economiza; a T14 vai para a aula 12 |

### O que sobra

A última tabela também mostra **a T14 como o maior risco que sobra**: R$ 18.239 por ano na média, um
ano ruim de R$ 388.419 um ano em cem, e nada no plano mexe nela. É um resultado deliberado, não um
descuido. O único controle da lista custa mais do que economiza, e as escolhas que sobram são
conviver com ela ou pagar alguém para carregar parte dela. As duas são legítimas; o que não é
legítimo é deixá-la sem registro. A aula 12 a registra.
