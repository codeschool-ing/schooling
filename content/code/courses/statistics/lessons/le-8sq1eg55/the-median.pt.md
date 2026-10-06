---
title: A mediana
version: 1
---

A **mediana** é o valor do meio depois que os valores estão em ordem. Metade das observações fica nela
ou abaixo, e metade fica nela ou acima.

## Uma quantidade ímpar de valores

Com uma quantidade ímpar existe um valor no meio. Pegue as cinco primeiras entregas: 34,5, 41,0, 52,5,
29,0, 38,5. Ordenadas, ficam

```localised
29,0   34,5   38,5   41,0   52,5
              ^^^^
```

O terceiro de cinco é o do meio, então a mediana é **38,5 minutos**.

## Uma quantidade par de valores

Com uma quantidade par existem dois valores no meio, e a mediana fica no meio deles. Estas são as doze
cestas da Horta, ordenadas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 150\" role=\"img\" data-fig=\"l03-median\" aria-label=\"As doze cestas ordenadas de R$ 12,90 a R$ 212,60, como doze caixas em fila. A sexta e a sétima, R$ 62,30 e R$ 74,10, estão destacadas; a mediana fica no meio delas, R$ 68,20.\"><rect x=\"30.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12,90</text><rect x=\"82.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"106.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">18,50</text><rect x=\"134.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"158.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">31,90</text><rect x=\"186.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">35,60</text><rect x=\"238.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">47,80</text><rect x=\"290.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"314.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">62,30</text><rect x=\"342.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"366.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">74,10</text><rect x=\"394.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">86,40</text><rect x=\"446.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">95,00</text><rect x=\"498.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">118,20</text><rect x=\"550.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"574.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">154,75</text><rect x=\"602.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">212,60</text><path d=\"M340.0 30.0 L340.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"184.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seis abaixo</text><text x=\"496.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seis acima</text><text x=\"340.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">mediana = (62,30 + 74,10) ÷ 2 = 68,20</text></svg>", "caption": "Com uma quantidade par não existe um único valor do meio, então a mediana fica no meio dos dois centrais."}
```

A sexta e a sétima são R$ 62,30 e R$ 74,10, então a cesta mediana é (62,30 + 74,10) ÷ 2 = **R$ 68,20**.

Faça o mesmo com os doze tempos de entrega — ordenados, o sexto e o sétimo são 36,0 e 38,5 — e a mediana
é **37,25 minutos**, um pouco abaixo da média de 38,96.

## Achando o meio numa lista longa

Para *n* valores ordenados, a mediana fica na posição (*n* + 1) ÷ 2. Com 12 valores, isso é a posição
6,5, o que significa no meio do sexto e do sétimo. Com 101 valores, é a posição 51, um valor só.

Ordenar é todo o trabalho. Esquecer de ordenar é o erro: o meio de uma lista desordenada é só o que
calhou de ser digitado no meio.

## O que a mediana ignora

A mediana olha a ordem dos valores e um ou dois deles no meio, e mais nada. Mude a entrega mais lenta de
61 minutos para 610 e a mediana não se mexe: continua no meio de 36,0 e 38,5.

Isso a torna **robusta**: um único valor absurdo, um erro de digitação ou um caso extraordinário não
consegue arrastá-la. A média, que usa o tamanho de cada valor, se move com cada um deles. A aula 4
transforma essa diferença numa regra para escolher entre as duas.

A mediana também precisa só de uma **ordem**, não de distâncias. Por isso a aula 2 a permitiu para
variáveis ordinais como notas em estrelas, onde a média se apoia numa suposição.
