---
title: Comparar opções
version: 1
---

Para dezembro de 2025, a equipe da Renata Sá propôs uma promoção no jogo de jardim de quatro lugares
mais vendido da Varanda: 10% de desconto, ou talvez 20%. A Helena perguntou à Lívia qual. **Uma
resposta prescritiva põe as opções lado a lado contra o objetivo**, e aqui a primeira coisa que ela
mostrou foi que os dois objetivos óbvios apontam para lados opostos.

## As opções

O jogo custa R$ 1.000 ao cliente e R$ 600 à Varanda, então cada um vendido sem desconto rende
R$ 400 antes dos custos da própria loja. A equipe da Renata estimou quantos jogos cada opção venderia
em dezembro, a partir das promoções dos dois últimos anos:

| | A | B | C |
|---|---|---|---|
| 1 | Opção | Preço | Unidades |
| 2 | Sem desconto | 1000 | 400 |
| 3 | 10% de desconto | 900 | 520 |
| 4 | 20% de desconto | 800 | 700 |

Essas unidades são uma previsão, feita com os métodos da aula 8, e carregam a incerteza dela. Guarde
isso; o fim desta seção volta ao assunto.

## Vendas e lucro

Em D1 digite `Vendas` e em E1 `Lucro`, os dois em milhares de reais. Lucro aqui é a margem sobre os
jogos vendidos, preço menos custo, vezes unidades:

```localised
=B2*C2/1000      400
=(B2-600)*C2/1000      160
```

Copie as duas até a linha 4:

| opção | vendas | lucro |
|---|---|---|
| sem desconto | 400 | 160 |
| 10% de desconto | 468 | 156 |
| 20% de desconto | 560 | 140 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três pares de barras para a promoção de dezembro do jogo de jardim. Sem desconto: vendas de 400 mil reais e lucro de 160 mil. Dez por cento: vendas de 468 mil e lucro de 156 mil. Vinte por cento: vendas de 560 mil e lucro de 140 mil. As vendas sobem da esquerda para a direita e o lucro cai.\" data-fig=\"l09-options\"><path d=\"M70.0 240.0 L700.0 240.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"244.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 173.3 L700.0 173.3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"177.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M70.0 106.7 L700.0 106.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"110.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M70.0 40.0 L700.0 40.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><path d=\"M115.0 106.7 H171.0 V240.0 H115.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M179.0 186.7 H235.0 V240.0 H179.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"143.0\" y=\"100.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">400</text><text x=\"207.0\" y=\"180.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">160</text><text x=\"175.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sem desconto</text><path d=\"M325.0 84.0 H381.0 V240.0 H325.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M389.0 188.0 H445.0 V240.0 H389.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"353.0\" y=\"78.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">468</text><text x=\"417.0\" y=\"182.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">156</text><text x=\"385.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">10% de desconto</text><path d=\"M535.0 53.3 H591.0 V240.0 H535.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M599.0 193.3 H655.0 V240.0 H599.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"563.0\" y=\"47.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">560</text><text x=\"627.0\" y=\"187.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">140</text><text x=\"595.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">20% de desconto</text><path d=\"M70.0 12.0 H84.0 V26.0 H70.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vendas</text><path d=\"M170.0 12.0 H184.0 V26.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"190.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">lucro</text><text x=\"700.0\" y=\"24.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milhares de reais</text><text x=\"700.0\" y=\"290.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a opção que mais vende é a que menos lucra</text></svg>", "caption": "Três opções para dezembro, com as estimativas da própria Varanda de quantos jogos cada uma venderia. A melhor opção para as vendas e a melhor para o lucro ficam em pontas opostas."}
```

**Com 20% de desconto a Varanda vende 40% a mais que sem desconto e lucra 12,5% a menos.** Cada
desconto entrega parte de uma margem que, para começar, era 40% do preço: R$ 100 dos R$ 400 com 10%
de desconto, e R$ 200 com 20%. Os jogos a mais não compensam. Se o objetivo é vender, a resposta é
20%. Se é lucrar, a resposta é sem desconto, por pouco à frente dos 10%.

## Quantos jogos cada desconto precisa

As estimativas são incertas, então um número mais útil é quantos jogos cada opção precisa vender para
lucrar o mesmo que a opção sem desconto. Em F1 digite `Unidades para empatar`:

```localised
=ARRED($E$2*1000/(B2-600);0)      400
```

Copiada para baixo, ela dá 533 para 10% de desconto e 800 para 20%. **Isso transforma uma pergunta
de previsão numa pergunta que alguém consegue julgar.** A opção de 20% precisa de 800 jogos contra uma
estimativa de 700: teria de superar a própria previsão em 100 jogos só para empatar. A de 10% precisa
de 533 contra 520, 13 jogos abaixo, bem dentro do erro de qualquer previsão. Se a equipe da Renata
vender 540 com 10% de desconto, lucra R$ 162 mil e passa a opção sem desconto.

## O que a Lívia recomendou

Ela não escolheu uma. Escreveu que, pelas estimativas da equipe, o desconto de 20% maximiza as vendas
e custa R$ 20 mil de lucro contra a opção sem desconto; que 10% e sem desconto ficam dentro do erro da
estimativa no lucro; e que a escolha depende de para que serve dezembro. Se o objetivo é lucro, sem
desconto ou 10%; se é desovar estoque ou ganhar clientes que voltem, 20% pode valer o custo, e essa é
uma pergunta para a Renata e a Helena, e não para a planilha. **O analista mostra as consequências de
cada opção; quem é dono do objetivo escolhe.**
