---
title: Médias de médias
version: 1
---

A Horta tem duas lojas. No mês passado, a loja do Cambuí recebeu 300 pedidos com cesta média de R$ 80, e
a loja do Taquaral recebeu 100 pedidos com cesta média de R$ 40. Qual foi a cesta média nas duas?

A resposta tentadora é tirar a média das duas médias: (80 + 40) ÷ 2 = **R$ 60**. Está errada.

## Pese cada média pela sua contagem

Os 300 pedidos do Cambuí renderam 300 × 80 = R$ 24.000. Os 100 do Taquaral renderam 100 × 40 = R$ 4.000.
Juntos, R$ 28.000 em 400 pedidos:

```localised
(300 × 80 + 100 × 40) ÷ (300 + 100) = 28.000 ÷ 400 = 70
```

A cesta média nas duas lojas é **R$ 70**. Tirar a média das duas médias deu a cada loja o mesmo peso,
como se cada uma tivesse recebido o mesmo número de pedidos. A **média ponderada** dá a cada loja um peso
proporcional aos seus pedidos, e é isso que a média geral é.

A média simples de médias só está certa quando os grupos têm o mesmo tamanho. Quando diferem, ela erra
por uma quantia que cresce com a diferença.

## A mesma coisa numa tabela de frequências

Uma tabela de frequências é um conjunto de grupos, cada um com uma contagem, então a média dela é uma
média ponderada. Aqui estão 100 pedidos da Horta contados pelo número de itens:

| itens | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| pedidos | 14 | 22 | 31 | 18 | 9 | 6 |

Multiplique cada número de itens pela sua contagem, some e divida pela contagem total:

```localised
(1×14 + 2×22 + 3×31 + 4×18 + 5×9 + 6×6) ÷ 100 = 304 ÷ 100 = 3,04
```

A média é **3,04 itens**. Na planilha, com os itens em A2:A7 e as contagens em B2:B7:

```localised
=SOMARPRODUTO(A2:A7; B2:B7) / SOMA(B2:B7)      3,04
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 270\" role=\"img\" data-fig=\"l03-items-frequency\" aria-label=\"Um gráfico de barras de 100 pedidos por número de itens: 14 com um, 22 com dois, 31 com três, 18 com quatro, 9 com cinco e 6 com seis. A média ponderada, 3,04, fica logo à direita do três. A média simples dos rótulos de 1 a 6, 3,5, fica mais à direita.\"><path d=\"M80.0 60.0 L80.0 215.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 215.0 L80.0 215.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"215.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 192.9 L560.0 192.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 192.9 L80.0 192.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"192.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M80.0 170.7 L560.0 170.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 170.7 L80.0 170.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"170.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M80.0 148.6 L560.0 148.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 148.6 L80.0 148.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"148.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M80.0 126.4 L560.0 126.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 126.4 L80.0 126.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"126.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M80.0 104.3 L560.0 104.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 104.3 L80.0 104.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"104.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M80.0 82.1 L560.0 82.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 82.1 L80.0 82.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"82.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M80.0 60.0 L560.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 60.0 L80.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text><text x=\"80.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos</text><path d=\"M92.8 215.0 L92.8 153.0 L147.2 153.0 L147.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"120.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M172.8 215.0 L172.8 117.6 L227.2 117.6 L227.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"200.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M252.8 215.0 L252.8 77.7 L307.2 77.7 L307.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"280.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M332.8 215.0 L332.8 135.3 L387.2 135.3 L387.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"360.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M412.8 215.0 L412.8 175.1 L467.2 175.1 L467.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"440.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M492.8 215.0 L492.8 188.4 L547.2 188.4 L547.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"520.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><path d=\"M80.0 215.0 L560.0 215.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"320.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">itens no pedido</text><path d=\"M283.2 215.0 L283.2 44.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"283.2\" y=\"36.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">média ponderada 3,04</text><path d=\"M320.0 215.0 L320.0 44.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"320.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">média dos rótulos 3,5</text></svg>", "caption": "Cada barra pesa tanto quanto os pedidos que tem. Tirar a média dos rótulos de 1 a 6 dá o mesmo peso a toda barra, e cai em 3,5."}
```

O erro a evitar é `=MÉDIA(A2:A7)`, que tira a média dos seis rótulos de 1 a 6 e devolve 3,5, como se
toda barra tivesse o mesmo número de pedidos.

## A mediana de uma tabela de frequências

A mediana vem das contagens acumuladas. Descendo a tabela, as contagens somam 14, depois 36, depois 67.
O 50º e o 51º pedidos caem os dois no terceiro grupo, então a mediana é **3 itens**, e a moda, a barra
mais alta, também é 3.
