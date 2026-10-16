---
title: Os juros, não o principal
version: 1
---

Peça a um time a sua dívida técnica e ele entrega uma lista com um tamanho ao lado de cada item: 320
horas para corrigir o travamento das reservas de assento, 200 para a réplica antiga de relatórios,
120 para o gerador de ingressos em PDF. Esse tamanho é o **principal** da dívida, o que custaria
quitá-la. É o número que todo registro de dívida traz, e sozinho ele não convence ninguém, porque
nada nele diz o que acontece se o trabalho nunca for feito.

A metáfora da aula 4 veio de Ward Cunningham, e tinha duas partes. Entregar um código que você sabe
que não está certo é tomar emprestado; cada hora gasta contornando esse código depois é **juro**. O
principal é pago uma vez, e só se alguém decidir pagá-lo. Os juros são pagos com ou sem decisão,
sprint após sprint, por quem quer que encoste no código.

## Dois números para cada dívida

| | principal | juros |
|---|---|---|
| o que é | as horas para quitar a dívida | as horas a mais gastas em cada sprint porque ela continua lá |
| quando se paga | uma vez, se alguém decidir | toda sprint, sem ninguém decidir |
| quem vê | quem estima a correção | ninguém em especial: espalham-se por todos que trabalham perto do código |
| o que responde | quanto custaria? | quanto está custando? |

A Coreto tem quatro dívidas que os líderes de time concordam que são reais. Aqui estão elas com os
dois números, em horas e em reais, à hora de engenharia de R$ 150 da aula 1:

| dívida | principal | juros por sprint |
|---|---|---|
| Travamento das reservas de assento no módulo de reservas | 320 h (R$ 48.000) | 31 h (R$ 4.650) |
| Gerador de ingressos em PDF feito à mão | 120 h (R$ 18.000) | 6 h (R$ 900) |
| Suíte ponta a ponta instável | 80 h (R$ 12.000) | 14 h (R$ 2.100) |
| Réplica antiga de relatórios | 200 h (R$ 30.000) | 4 h (R$ 600) |

Leia só a coluna do principal e a réplica de relatórios parece o segundo maior problema da Coreto.
Leia a coluna dos juros e ela é o menor, com 4 horas por sprint. **A suíte ponta a ponta instável, a
dívida mais barata de corrigir, cobra três vezes e meia os juros da réplica** — 14 horas contra 4.

## Por que o principal engana

Um empréstimo de banco tem uma data de vencimento. Uma dívida no código não tem nenhuma. Nada
acontece no dia em que um time decide não corrigir a réplica, e nada acontece no dia seguinte. Então
uma lista ordenada pelo principal é uma lista de quão cara cada correção parece, e as correções mais
caras parecem os maiores problemas. Elas são só as maiores contas que alguém talvez um dia escolha
pagar.

**Dívida em código que ninguém mexe não cobra juros.** Os juros são pagos na mudança: o engenheiro
paga quando abre o módulo, contorna a esquisitice, espera o teste lento ou corrige o incidente que
ela causou. Um módulo emaranhado que ninguém edita há anos não custa nada nesta sprint, por mais
desagradável que seja de ler, e quitar o seu principal não traz nada de volta. A aula 4 traçou a
linha entre dívida e bagunça; esta é a mesma linha, traçada em dinheiro.

O contrário também vale. Uma dívida de principal modesto num código que todo time edita toda semana
sai cara, e um registro que lista só principais vai colocá-la perto do fim.

## A língua em que o dinheiro é gasto

Um principal é um pedido: deem-nos 320 horas. Os juros são um fato sobre o presente: já gastamos 31
horas por sprint com isto, e vamos continuar gastando. O Davi levou a dívida das reservas de assento
ao Otávio Lins, o CFO, na segunda forma:

> O travamento das reservas de assento nos custa 31 horas de engenharia toda sprint — R$ 4.650 por
> sprint, R$ 120.900 por ano — e continua custando isso até gastarmos 320 horas, R$ 48.000, uma vez.

O Otávio leu aquilo como um custo recorrente contra um investimento único, que é a forma da maioria
das decisões que chegam à mesa de um CFO. Descrita como "320 horas de refatoração", a mesma dívida
soa como engenheiros querendo arrumar a casa. **A aritmética é a mesma nas duas versões, e só a
segunda responde à pergunta que um orçamento faz**: o que acontece se esse dinheiro não for gasto?

## O que as horas deixam de fora

Horas não são todos os juros. A dívida das reservas de assento também falha nas grandes aberturas de
vendas, e uma abertura que falha custa à Coreto vendas e casas de espetáculo de um jeito que nenhum
registro de horas mostra. A aula 20 põe preço nesse tipo de risco, como uma probabilidade
multiplicada por uma perda, e o soma ao argumento.

Esta aula fica na parte que dá para contar em horas. A maioria dos times nunca escreve essa parte, e
ela já basta para ordenar as quatro dívidas de um jeito diferente do que os principais ordenam. A
próxima seção mostra de onde vieram as 31 horas, porque os juros precisam ser medidos, e medir é a
maior parte do trabalho.
