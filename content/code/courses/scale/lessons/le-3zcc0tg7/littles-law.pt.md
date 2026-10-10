---
title: A lei de Little
version: 1
---

Degradar bem é metade de sobreviver a uma abertura de vendas. A outra metade é ter capacidade
suficiente para que isso raramente aconteça, e o planejamento de capacidade começa por uma equação
que vale para quase todo sistema que não está acumulando trabalho sem limite:

**L = λ × W**

O número médio de coisas dentro de um sistema, *L*, é a taxa com que elas chegam, *λ*, vezes quanto
tempo cada uma fica, *W*. Ela não precisa de nenhuma suposição sobre como as chegadas se distribuem
nem sobre quanto cada uma leva. Vale para a fila de uma loja, para as conexões de um banco e para as
vagas da bilheteria.

O curso já vinha usando a lei sem dizer:

- **O teste de carga da aula 9.** 32 trabalhadores em ciclo fechado, e 105 vendas por segundo. Cada
  trabalhador está sempre dentro da bilheteria, então *L* = 32, e *W* = 32 ÷ 105 = 0,30 s. A mediana
  medida foi 295 ms.
- **O timeout da aula 9.** 32 vagas, cada uma presa pelo segundo inteiro de timeout enquanto o
  payments travava: *λ* = 32 ÷ 1 = 32 vendas por segundo, no máximo, qualquer que fosse a demanda.
- **Quantas cobranças estão em andamento.** 100 vendas por segundo, cada uma passando uns 30 ms no
  payments: 3 cobranças ao mesmo tempo, em média. Se o payments ficar lento, um segundo por cobrança,
  as mesmas 100 vendas por segundo precisam de 100 em andamento, e a bilheteria tem 32 vagas. A lei de
  Little diz, antes de qualquer coisa quebrar, que um payments mais lento vira carga descartada na
  bilheteria.

Esse último uso é o importante. **Uma lentidão em algum lugar mais adiante é um aumento de *L* em todo
lugar antes dele**: mais threads, mais conexões, mais memória, sem nenhum tráfego a mais. É por isso
que a aula 9 limitou as vagas e a aula 10 limitou as novas tentativas: as duas impedem *L* de crescer
sem ninguém ter decidido isso.
