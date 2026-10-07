---
title: A distribuição uniforme
version: 1
---

A **distribuição uniforme** dá a todo valor de uma faixa a mesma chance. É o modelo da ignorância completa
sobre onde, na faixa, um valor vai cair.

## Contínua: uma linha reta

Um entregador da Horta vai chegar num momento qualquer entre 18:00 e 18:30, sem nenhum momento mais
provável que outro. A densidade é reta ao longo da meia hora e zero fora dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 200\" role=\"img\" data-fig=\"l08-uniform\" aria-label=\"Uma linha reta na altura de um trinta avos, de 0 a 30 minutos: o entregador tem a mesma chance de chegar em qualquer momento da meia hora. O trecho de 20 a 30 minutos está sombreado; é um terço do retângulo, então a chance de esperar mais de 20 minutos é de uma em três.\"><path d=\"M50.0 150.0 L520.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M77.6 150.0 L77.6 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"77.6\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M146.8 150.0 L146.8 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"146.8\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M215.9 150.0 L215.9 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"215.9\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M285.0 150.0 L285.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M354.1 150.0 L354.1 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"354.1\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M423.2 150.0 L423.2 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"423.2\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M492.4 150.0 L492.4 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"492.4\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"285.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutos depois das 18:00</text><path d=\"M354.1 150.0 L354.1 71.4 L492.4 71.4 L492.4 150.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.45\"></path><path d=\"M77.6 150.0 L77.6 71.4 L492.4 71.4 L492.4 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"423.2\" y=\"57.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">esperar mais de 20 minutos: 1/3</text></svg>", "caption": "Todo momento com a mesma chance, então a probabilidade de qualquer trecho é a fração que ele ocupa da largura."}
```

Com uma densidade reta, a probabilidade de qualquer trecho é simplesmente a fração que ele ocupa da
largura total. A chance de esperar mais de 20 minutos é o trecho de 20 a 30, um terço da janela de 30
minutos: **1/3**.

Para uma distribuição uniforme entre *a* e *b*:

- a **média** é o ponto do meio, (*a* + *b*) ÷ 2, aqui 15 minutos;
- o **desvio padrão** é (*b* − *a*) ÷ √12, aqui 30 ÷ √12 = **8,66 minutos**.

O √12 sai do cálculo e só vale ser conhecido por um motivo: o desvio padrão de uma distribuição reta é um
pouco menos de 30% da largura dela.

## Discreta: um dado honesto

A versão discreta dá a cada um de um conjunto de valores a mesma probabilidade. Um dado honesto de seis
faces dá 1/6 a cada face. O sorteio de um pedido numa lista de 400 dá 1/400 a cada pedido, e é exatamente
nisso que uma **amostra aleatória simples** se apoia, como a aula 10 explica.

## Onde serve e onde não serve

A uniforme é o modelo certo quando nada favorece um valor em vez de outro: o ponteiro dos segundos quando
você olha o relógio, um gerador de números aleatórios, uma loteria honesta.

É o modelo errado sempre que os valores se agrupam. Tempos de entrega, cestas, pesos e quase tudo o que se
mede em dados de negócio têm um pico em algum lugar, e supor todos os valores igualmente prováveis o
ignoraria. Dados uniformes são raros na natureza, e por isso a aparição deles — uma coluna de respostas
"aleatórias" de pesquisa espalhadas perfeitamente por igual — às vezes é sinal de que alguém inventou os
dados.
