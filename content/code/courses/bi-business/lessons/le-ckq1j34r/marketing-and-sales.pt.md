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
| 2 | Visitas | 3568000 |
| 3 | Carrinhos | 214100 |
| 4 | Pedidos | 44600 |

Uma visita é uma sessão no site; um carrinho é uma sessão em que algo foi posto na cesta; um pedido é
um pedido pago. As taxas entre os passos:

```localised
=ARRED(B3/B2*100;1)      6
=ARRED(B4/B3*100;1)      20,8
=ARRED(B4/B2*100;2)      1,25
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O funil da loja online em 2025 como três barras cada vez mais curtas: 3.568.000 visitas, 214.100 carrinhos, 44.600 pedidos. De visita para carrinho, 6,0%; de carrinho para pedido, 20,8%; de visita para pedido, 1,25%.\" data-fig=\"l05-funnel\"><text x=\"136.0\" y=\"60.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">visitas</text><path d=\"M150.0 34.0 H570.0 V74.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"580.0\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3.568.000</text><text x=\"136.0\" y=\"144.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">carrinhos</text><path d=\"M150.0 118.0 H175.2 V158.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"185.2\" y=\"144.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">214.100</text><text x=\"136.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">pedidos</text><path d=\"M150.0 202.0 H155.2 V242.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"165.2\" y=\"228.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">44.600</text><text x=\"156.0\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">6,0% das visitas põem algo no carrinho</text><text x=\"156.0\" y=\"180.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">20,8% dos carrinhos viram pedido</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">1,25% das visitas terminam num pedido</text></svg>", "caption": "O funil online, 2025. Cada passo perde a maior parte do anterior; a taxa de conversão é o produto dos passos."}
```

**6,0% das visitas puseram algo no carrinho, 20,8% dos carrinhos viraram pedido, e 1,25% das visitas
terminaram num pedido.** O Calc mostra a primeira como `6`, como a aula 4 explicou. A última é a taxa
de conversão, arredondada a duas casas porque é pequena, e ela é o produto dos passos anteriores:
6,0% de 20,8% dá cerca de 1,25%. Por isso vale manter os passos separados. Uma queda na conversão de 1,25% para 1,05% pode ser menos gente chegando ao carrinho, o que aponta para os produtos e os preços na página, ou
menos carrinhos sendo pagos, o que aponta para frete, pagamento ou um checkout quebrado. O total não
distingue essas duas coisas; os passos distinguem.

## Mais dois números de que o marketing vive

**O tíquete médio** é a venda dividida pelos pedidos. As vendas online foram R$ 15,61 milhões, da aula 1:

```localised
=ARRED(15610*1000/44600;2)      350
```

R$ 350 por pedido online. Vendas são visitas vezes conversão vezes tíquete, então qualquer um dos
três pode movê-las, e um relatório que mostra só as vendas esconde qual deles foi.

**O custo de aquisição de cliente** é o que se gastou para conquistar clientes novos dividido por
quantos foram conquistados. Em 2025 a Varanda gastou R$ 2,15 milhões em marketing online, e 28.400 pessoas fizeram o primeiro pedido online da vida, 13.200 delas no primeiro semestre, como a aula 3
contou:

```localised
=ARRED(2150*1000/28400;2)      75,7
```

Cerca de R$ 76 por cliente novo. **Leia com cuidado: o cálculo põe todo o marketing online na conta
dos clientes novos, embora parte dele tenha alcançado quem já tinha comprado.** É um número
aproximado, bom para comparar um ano com o seguinte se for calculado sempre do mesmo jeito, e a aula 17
põe um custo como este diante do que um cliente vale.

## A loja também tem funil

O funil de uma loja física é mais difícil de contar, porque ninguém faz login na porta. Seis lojas da
Varanda, Contagem entre elas, têm um contador na entrada. Em 2025 ele contou 117.500 visitantes em Contagem, e os caixas emitiram 28.600 cupons:

```localised
=ARRED(28600/117500*100;1)      24,3
=ARRED(12480*1000/28600;2)      436,36
```

**24,3% dos visitantes compraram alguma coisa, e o cupom médio foi de R$ 436,36**, cerca de um quarto acima do tíquete online de R$ 350,
porque os móveis grandes são comprados em geral na loja. Um contador de porta conta
entradas, não pessoas: um casal conta como dois, e um cliente que vai ao carro e volta conta duas
vezes. A conversão da loja é, portanto, um número para comparar consigo mesmo ao longo do tempo, não
com a taxa online.
