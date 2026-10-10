---
title: Adiantados e atrasados, e a árvore que os liga
version: 1
---

As vendas do mês são o número que todo mundo na Varanda acompanha, e como guia elas têm um defeito:
quando o total de fevereiro fica conhecido, fevereiro já acabou. **Um indicador atrasado (em inglês,
*lagging*) diz se você chegou. Um indicador adiantado (*leading*) se mexe antes e avisa a tempo de
corrigir o rumo.** Vendas, lucro e rotatividade do ano são atrasados. As visitas ao site nesta
semana, a parcela delas que compra e o número de propostas de emprego recusadas são adiantados.

O erro comum é tratar "adiantado" como elogio, como se o número que chega antes fosse o melhor. Ele
só é melhor se de fato move o resultado, e isso precisa ser mostrado em vez de suposto. Um
indicador adiantado sem ligação comprovada com o resultado é um número precoce sobre nada.

## Uma árvore de KPIs

O jeito de mostrar a ligação é escrever o resultado como a aritmética das suas partes. Para a loja
online, essa aritmética é exata:

**vendas online = visitas × conversão × tíquete médio**

Conversão é a parcela das visitas que termina em pedido, e o tíquete médio é o valor de um pedido.
Multiplique os dois primeiros e você tem o número de pedidos; multiplique pelo tíquete e tem as
vendas. A loja online da Varanda em 2025, numa planilha nova a partir de A1:

| | A | B |
|---|---|---|
| 1 | | Hoje |
| 2 | Visitas | 3568000 |
| 3 | Conversão % | 1,25 |
| 4 | Tíquete médio | 350 |

Em A5 digite `Vendas` e em A6 `Pedidos`, e depois:

```localised
B5   =B2*B3/100*B4      15610000
B6   =B2*B3/100         44600
```

**R$ 15,61 milhões**, o número online da aula 1, refeito a partir de três números que se mexem todo
dia. É isso que torna a árvore útil: o resultado no topo se conhece uma vez por mês, e os ramos se
conhecem na segunda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Uma árvore de KPIs. No topo, as vendas online, um resultado atrasado. Abaixo, multiplicados, visitas, conversão e tíquete médio. Abaixo de cada um, o que o move: campanhas, busca e e-mail para as visitas; preço, estoque, velocidade do site e a promessa de entrega para a conversão; o mix de produtos e os itens por pedido para o tíquete. Cada ramo tem um dono.\" data-fig=\"l10-tree\"><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">vendas online</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 15,61 milhões em 2025</text><text x=\"475.0\" y=\"44.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">atrasado</text><rect x=\"20.0\" y=\"150.0\" width=\"200.0\" height=\"78.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">visitas</text><text x=\"120.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3.568.000</text><text x=\"120.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dono: Renata</text><path d=\"M120.0 150.0 L120.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"260.0\" y=\"150.0\" width=\"200.0\" height=\"78.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">conversão</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1,25% das visitas compram</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">donos: Renata e Caio</text><path d=\"M360.0 150.0 L360.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"500.0\" y=\"150.0\" width=\"200.0\" height=\"78.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">tíquete médio</text><text x=\"600.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 350 por pedido</text><text x=\"600.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dono: Renata</text><path d=\"M600.0 150.0 L600.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M120.0 116.0 L600.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M360.0 116.0 L360.0 84.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"240.0\" y=\"138.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">×</text><text x=\"480.0\" y=\"138.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">×</text><text x=\"700.0\" y=\"138.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">adiantados</text><path d=\"M120.0 230.0 L120.0 262.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"20.0\" y=\"264.0\" width=\"200.0\" height=\"112.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">campanhas pagas</text><text x=\"36.0\" y=\"312.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">busca</text><text x=\"36.0\" y=\"334.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e-mail</text><path d=\"M360.0 230.0 L360.0 262.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"260.0\" y=\"264.0\" width=\"200.0\" height=\"112.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"276.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">preço</text><text x=\"276.0\" y=\"312.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">estoque disponível</text><text x=\"276.0\" y=\"334.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">velocidade do site</text><text x=\"276.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">promessa de entrega</text><path d=\"M600.0 230.0 L600.0 262.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"500.0\" y=\"264.0\" width=\"200.0\" height=\"112.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"516.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">mix de produtos</text><text x=\"516.0\" y=\"312.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">itens por pedido</text></svg>", "caption": "As vendas online como árvore. O resultado no topo chega uma vez por mês; os três ramos mexem todo dia, e o que está embaixo deles é o que alguém consegue de fato mudar. A conversão tem dois donos porque a promessa de entrega e o estoque são de operações."}
```

A última linha da figura é onde o trabalho acontece. Ninguém consegue "aumentar a conversão"
diretamente; dá para baixar o preço de um produto, mantê-lo em estoque, fazer a página carregar mais
rápido ou prometer uma entrega mais curta. **Uma árvore termina onde alguém consegue agir**, e é ali
também que estão os donos. A conversão tem dois, porque o estoque e a promessa de entrega são do
Caio, não da Renata. Uma árvore desenhada assim resolve de antemão a discussão sobre de quem foi a
culpa de um mês ruim.

## Por que um ramo sozinho engana

A agência da Renata propõe um ano de campanhas pagas mais pesadas em 2026, que deve aumentar as
visitas em um quarto. Suponha que aumente, e que os visitantes novos estejam menos dispostos a
comprar que os antigos, de modo que a conversão caia para 1%. Em C1 digite `Campanha`, `1` em C3 e
`350` em C4, e deixe C2 aumentar as visitas em um quarto:

```localised
C2   =B2*1,25           4460000
C5   =C2*C3/100*C4      15610000
C6   =C2*C3/100         44600
```

**Visitas 25% maiores, vendas iguais até o último real.** O relatório da própria campanha, que conta
visitas, vai chamá-la de sucesso, e a árvore diz que ela não comprou nada. O caso oposto mostra o
outro lado da multiplicação. Mantenha visitas e tíquete onde estavam e suba a conversão de 1,25% para
1,375%, um décimo a mais, e as vendas sobem um décimo também:

```localised
=B2*1,375/100*B4                          17171000
=ARRED((B2*1,375/100*B4/B5-1)*100;1)      10
```

As partes de um produto mexem o resultado na mesma proporção, então **um ramo só é boa notícia se os
outros ficaram parados**, e a árvore é como você vê se ficaram.

## O que uma árvore não é

Uma árvore como esta é uma identidade: vale pela aritmética, aconteça o que acontecer. Muitas árvores
que as pessoas desenham não são. "Horas de treinamento movem a satisfação do cliente, que move as
vendas" é uma hipótese escrita no formato de árvore, e as setas precisam ser conferidas nos dados
antes que alguém gerencie por elas. A aula 7 mostrou como dois números podem andar juntos por um
terceiro motivo; a aula 18 de `statistics` trata disso como se deve. Desenhe as partes exatas com
confiança e as supostas com linha pontilhada.
