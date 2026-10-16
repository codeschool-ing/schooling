---
title: Antipadrões de desempenho
version: 1
---

Um **padrão** é uma solução que continua funcionando. Um **antipadrão** é um hábito que continua
parecendo uma solução e continua causando o mesmo problema. O Azure Architecture Center, da Microsoft,
mantém um catálogo dos que deixam sistemas na nuvem lentos, os **antipadrões de desempenho**
(*performance antipatterns*), e a maior parte dos itens nem é sobre nuvem. É sobre código que pede demais,
vezes demais, a alguma coisa longe.

Três deles respondem pela maior parte do que dá errado numa loja como a da Quitanda, e esta aula constrói
e conserta cada um:

| antipadrão | o que o código faz | por que dói |
| --- | --- | --- |
| **I/O tagarela** (*chatty I/O*) | muitas requisições pequenas onde uma bastaria | cada requisição paga uma ida e volta |
| **busca desnecessária** (*extraneous fetching*) | busca mais dados do que usa | todo byte atravessa a rede e ocupa memória |
| **banco ocupado** (*busy database*) | faz o banco fazer trabalho que poderia ser feito uma vez, ou em outro lugar | o banco é a parte mais difícil de escalar |

O que eles têm em comum é que **são invisíveis num notebook**. Com o banco na mesma máquina, uma ida e
volta leva um décimo de milissegundo, e mil delas levam um décimo de segundo, o que ninguém percebe. Em
produção o banco fica em outra zona de disponibilidade, a um ou dois milissegundos, e as mesmas mil idas e
voltas levam dois segundos. O código não mudou; a distância mudou.

Então o laboratório devolve a distância. Todo byte entre a loja e o banco passa por um proxy pequeno que o
segura por um milissegundo em cada direção, o que transforma uma ida e volta local em uns dois
milissegundos, mais ou menos o custo de atravessar entre zonas numa região.
