---
title: Contaminação
version: 1
---

**Um teste está contaminado quando o grupo de controle é tocado pelo tratamento**, ou quando os dois
grupos não agem de forma independente. A diferença entre eles encolhe, ou entorta, e nada no dado
avisa. Três tipos aparecem de novo e de novo.

## A mesma pessoa nos dois grupos

Um visitante é um cookie, e uma pessoa pode ter vários. Alguém que olha as receitas da Panela no
celular no almoço e faz o pedido no notebook à noite pode ver o checkout antigo num e o novo no outro.
Se pedir no notebook, o pedido conta para o grupo em que o notebook estava, e a experiência que o
convenceu pode ter sido a outra. **O efeito é diluído em direção a zero**, porque parte de cada grupo
viu as duas versões.

As soluções são uma unidade maior, como a conta logada onde ela existe, ou aceitar a diluição e dizer
isso. Medi-la é possível onde alguns visitantes entram na conta: a fração de contas vistas com dois
aparelhos em grupos diferentes é uma estimativa de quanto do teste se misturou.

## Pessoas que conversam

A Panela tem um programa de indicação: um cliente manda a um amigo um código de desconto. Se o
tratamento muda a página de indicação, o amigo de um cliente tratado cai em qualquer grupo, e um
visitante do controle chega já convencido por um amigo tratado. **Efeitos que andam entre pessoas
vazam pela divisão.** O mesmo acontece em marketplaces, onde compradores e vendedores dividem um
mesmo conjunto, e em qualquer coisa social.

A solução é sortear **agrupamentos** que não conversam entre si, como cidades ou regiões, em vez de
indivíduos. Funciona e custa muito poder, porque um teste de vinte cidades tem vinte unidades, não
vinte mil.

## Recursos compartilhados

Se o tratamento faz mais gente pedir, e a capacidade da cozinha é fixa, os pedidos do grupo de
controle podem atrasar ou ser cancelados para abrir espaço. O tratamento então parece melhor em
parte por tirar algo do controle. **Uma diferença que o próprio teste causou no controle não é efeito
do tratamento**, e ela some no momento em que todo mundo recebe o tratamento. Vigiar uma métrica de
proteção no grupo de controle, como os atrasos de entrega, é como isso é notado.

## O que escrever no plano

O plano de teste da aula 7 ganha mais uma linha: **qual é a unidade de aleatorização, e como o
tratamento poderia chegar ao grupo de controle?** Se a resposta é "não pode", diga por quê. Se pode,
diga quanta diluição é aceitável, ou mude a unidade.
