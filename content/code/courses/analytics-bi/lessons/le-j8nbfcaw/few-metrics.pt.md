---
title: Poucas métricas, em pares, e mudadas com data
version: 1
---

Um time que sabe definir uma métrica com precisão sabe definir cem, e um painel com cem métricas
não é lido por ninguém. Três hábitos mantêm a lista curta e útil.

## Uma métrica que lidera, e as salvaguardas dela

Muitos times escolhem uma **estrela-guia** (*north star*): a métrica que melhor captura o valor que
os clientes recebem, que o resto do trabalho deve mover. Para uma loja como a Lantern, poderia ser
a receita líquida de clientes que voltam, porque ela só cresce se as pessoas voltarem. A escolha
importa menos do que o fato de existir uma, para que duas propostas possam ser comparadas pelo que
fazem ao mesmo número.

Uma métrica só convida a manipulação, mesmo sem ninguém querer. A observação é antiga o bastante
para ter nome, **lei de Goodhart**: quando uma medida vira meta, ela deixa de ser uma boa medida.
Um time premiado por pedidos consegue aumentar os pedidos com cupons que custam mais do que os
pedidos trazem. Então cada meta ganha uma **salvaguarda**, uma segunda métrica que não pode piorar
enquanto a primeira melhora:

| meta | salvaguarda | o que o par evita |
|---|---|---|
| pedidos | receita líquida por pedido | comprar pedidos com desconto |
| receita líquida | taxa de estorno | vender o que os clientes devolvem |
| clientes novos | clientes ativos em 90 dias | campanhas que trazem gente que nunca volta |

A última linha não é hipotética para a Lantern: a campanha de Black Friday de novembro de 2025
trouxe mais clientes novos do que qualquer outro mês, e a aula 9 mede quantos deles ficaram.

## Antecedentes e defasadas

A receita líquida de um trimestre é uma métrica **defasada**: quando ela é conhecida, nada mais pode
mudá-la. A fatia de visitas que chega ao checkout nesta semana é uma **antecedente**: ela se move
primeiro e ainda dá para agir. Um conjunto útil tem as duas, e diz qual é qual, para ninguém esperar
o trimestre para saber o que a semana já mostrou.

## Mudando uma definição

Definições mudam: o financeiro decide que estornos devem contar na data do estorno e não na do
pedido, ou o negócio passa a vender assinaturas e "ativo" precisa incluí-las. **Uma mudança é uma
nova versão com data, nunca uma edição silenciosa.** A linha `desde` do cartão existe para isso, e a
versão antiga continua legível, porque o relatório do conselho do ano passado foi calculado com
ela e alguém vai comparar os dois. Um gráfico que cruza a data de uma mudança deve dizer isso no
próprio gráfico; senão, um degrau na linha que é só uma definição nova parece algo que os clientes
fizeram.
