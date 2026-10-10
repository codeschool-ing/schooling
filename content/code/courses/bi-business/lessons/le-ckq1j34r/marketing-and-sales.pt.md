---
title: Marketing e vendas: o funil
version: 1
---

O trabalho do marketing é trazer clientes, e o de vendas é transformá-los em pedidos, então os dois são
medidos ao longo de um mesmo caminho. **O funil é esse caminho contado passo a passo: quantas pessoas
chegaram, quantas mostraram interesse, quantas compraram.** O valor dele não está no formato, que todo
funil tem. Está em que uma queda nas vendas pode ser rastreada até o passo em que as pessoas pararam.

## O funil da loja online, 2025

A loja online da Varanda conta cada passo, porque cada passo é uma página:

| | A | B |
|---|---|---|
| 1 | Passo | Contagem |
| 2 | Visitas | 6480000 |
| 3 | Carrinhos | 498900 |
| 4 | Pedidos | 124000 |

Uma visita é uma sessão no site; um carrinho é uma sessão em que algo foi posto na cesta; um pedido é
um pedido pago. As taxas entre os passos:

```localised
=ARRED(B3/B2*100;1)      7,7
=ARRED(B4/B3*100;1)      24,9
=ARRED(B4/B2*100;1)      1,9
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O funil da loja online em 2025 como três barras cada vez mais curtas: 6,48 milhões de visitas, 498.900 carrinhos, 124.000 pedidos. De visita para carrinho, 7,7%; de carrinho para pedido, 24,9%; de visita para pedido, 1,9%.\" data-fig=\"l05-funnel\"><text x=\"136.0\" y=\"60.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">visitas</text><path d=\"M150.0 34.0 H570.0 V74.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"580.0\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">6,48 milhões</text><text x=\"136.0\" y=\"144.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">carrinhos</text><path d=\"M150.0 118.0 H182.3 V158.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"192.3\" y=\"144.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">498.900</text><text x=\"136.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">pedidos</text><path d=\"M150.0 202.0 H158.0 V242.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"168.0\" y=\"228.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">124.000</text><text x=\"156.0\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">7,7% das visitas põem algo no carrinho</text><text x=\"156.0\" y=\"180.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">24,9% dos carrinhos viram pedido</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">1,9% das visitas terminam num pedido</text></svg>", "caption": "O funil online, 2025. Cada passo perde a maior parte do anterior; a taxa de conversão é o produto dos passos."}
```

**7,7% das visitas puseram algo no carrinho, 24,9% dos carrinhos viraram pedido, e 1,9% das visitas
terminaram num pedido.** A última é a taxa de conversão, e ela é o produto dos passos anteriores: 7,7%
de 24,9% dá cerca de 1,9%. Por isso vale manter os passos separados. Uma queda na conversão de 1,9% para
1,6% pode ser menos gente chegando ao carrinho, o que aponta para os produtos e os preços na página, ou
menos carrinhos sendo pagos, o que aponta para frete, pagamento ou um checkout quebrado. O total não
distingue essas duas coisas; os passos distinguem.

## Mais dois números de que o marketing vive

**O tíquete médio** é a venda dividida pelos pedidos. As vendas online foram R$ 15,61 milhões, da aula 1:

```localised
=ARRED(15610*1000/124000;2)      125,89
```

R$ 125,89 por pedido online. Vendas são visitas vezes conversão vezes tíquete, então qualquer um dos
três pode movê-las, e um relatório que mostra só as vendas esconde qual deles foi.

**O custo de aquisição de cliente** é o que se gastou para conquistar clientes novos dividido por
quantos foram conquistados. Em 2025 a Varanda gastou R$ 2,15 milhões em marketing online, e 79.600
pessoas fizeram o primeiro pedido online da vida, 41.200 delas no primeiro semestre, como a aula 3
contou:

```localised
=ARRED(2150*1000/79600;2)      27,01
```

Cerca de R$ 27 por cliente novo. **Leia com cuidado: o cálculo põe todo o marketing online na conta
dos clientes novos, embora parte dele tenha alcançado quem já tinha comprado.** É um número
aproximado, bom para comparar um ano com o seguinte se for calculado sempre do mesmo jeito, e a aula 17
põe um custo como este diante do que um cliente vale.

## A loja também tem funil

O funil de uma loja física é mais difícil de contar, porque ninguém faz login na porta. Seis lojas da
Varanda, Contagem entre elas, têm um contador na entrada. Em 2025 ele contou 211.500 visitantes em
Contagem, e os caixas emitiram 51.480 cupons:

```localised
=ARRED(51480/211500*100;1)      24,3
=ARRED(12480*1000/51480;2)      242,42
```

**24,3% dos visitantes compraram alguma coisa, e o cupom médio foi de R$ 242,42**, quase o dobro do
tíquete online, porque os móveis grandes são comprados em geral na loja. Um contador de porta conta
entradas, não pessoas: um casal conta como dois, e um cliente que vai ao carro e volta conta duas
vezes. A conversão da loja é, portanto, um número para comparar consigo mesmo ao longo do tempo, não
com a taxa online.
