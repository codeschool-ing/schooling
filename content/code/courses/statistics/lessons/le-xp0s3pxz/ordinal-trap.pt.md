---
title: A média de uma nota em estrelas
version: 1
---

A Horta pede que todo cliente avalie a entrega de 1 a 5 estrelas. Nos doze pedidos, as notas foram:

| estrelas | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| pedidos | 1 | 1 | 2 | 4 | 4 |

Todo aplicativo mostra a média: 45 estrelas em 12 pedidos dá **3,75**. É um resumo justo?

## O que a média supõe

Para somar notas em estrelas e dividir, é preciso tratá-las como quantias. Isso significa supor que **os
passos têm o mesmo tamanho**: que a diferença entre 1 e 2 estrelas é tão grande quanto a diferença entre
4 e 5. Ninguém estabeleceu isso. O cliente escolheu uma palavra — péssimo, ruim, ok, bom, ótimo — e o
aplicativo a transformou num dígito.

Muita gente usa só as pontas da escala, 5 para "nada deu errado" e 1 para "algo deu". Para essas
pessoas, a distância de 4 para 5 é pequena, e a distância de 1 para 2 é enorme. Tirar a média das notas
delas mistura duas réguas diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 260\" role=\"img\" data-fig=\"l02-ratings-bars\" aria-label=\"Um gráfico de barras das doze notas, de 1 a 5 estrelas: um 1, um 2, dois 3, quatro 4 e quatro 5. A mediana, 4, é uma nota que alguém deu. A média, 3,75, fica entre duas barras.\"><path d=\"M80.0 50.0 L80.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 205.0 L80.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 174.0 L520.0 174.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 174.0 L80.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M80.0 143.0 L520.0 143.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 143.0 L80.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M80.0 112.0 L520.0 112.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 112.0 L80.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M80.0 81.0 L520.0 81.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 81.0 L80.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M80.0 50.0 L520.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 50.0 L80.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"80.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos</text><path d=\"M95.8 205.0 L95.8 174.0 L152.2 174.0 L152.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"124.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M183.8 205.0 L183.8 174.0 L240.2 174.0 L240.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"212.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M271.8 205.0 L271.8 143.0 L328.2 143.0 L328.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"300.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M359.8 205.0 L359.8 81.0 L416.2 81.0 L416.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"388.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M447.8 205.0 L447.8 81.0 L504.2 81.0 L504.2 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"476.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M80.0 205.0 L520.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"300.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">estrelas dadas</text><path d=\"M388.0 205.0 L388.0 36.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"388.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mediana 4</text><path d=\"M366.0 205.0 L366.0 36.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"366.0\" y=\"28.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">média 3,75</text></svg>", "caption": "A mediana é um valor da escala. A média trata o passo de 1 para 2 estrelas como do mesmo tamanho que o passo de 4 para 5, e ninguém mediu isso."}
```

## O que é seguro informar

A **mediana** precisa só da ordem. Ordene as doze notas — 1, 2, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5 — e as duas
do meio são 4, então a mediana é 4. É uma nota que alguém de fato deu, e ela diz que metade dos
clientes avaliou a entrega com 4 ou mais.

A **própria distribuição** é ainda mais segura. "Oito de doze clientes deram 4 ou 5 estrelas; um deu 1"
diz mais que qualquer número sozinho, e não supõe nada sobre distâncias.

## Então por que todo mundo tira a média das notas?

Porque é conveniente, e porque com muitas notas ela costuma dar a mesma ordenação que um método mais
cuidadoso. Tratar uma escala de cinco pontos como se fosse intervalar é prática comum em pesquisas de
opinião, e defensável quando a escala tem pontos suficientes e as respostas se espalham por eles.

A questão não é que o 3,75 seja proibido. É que **ele se apoia numa suposição**, e a suposição quebra de
um jeito reconhecível: quando dois produtos têm a mesma média construída a partir de distribuições bem
diferentes. Um 3,75 feito quase só de 4 e um 3,75 feito de 5 e 1 descrevem serviços diferentes, e só a
distribuição mostra a diferença.
