---
title: Menor privilégio
version: 1
---

**O princípio do menor privilégio diz que toda pessoa, programa e sistema recebe só o acesso que a
tarefa dele exige, e só pelo tempo que exige.** Ele é antigo: Jerome Saltzer e Michael Schroeder o
listaram em 1975 entre os princípios de projeto para proteger informação em computadores, e nada
desde então o tornou menos verdadeiro.

A objeção de sempre é sobre confiança: "Eu confio na minha equipe, por que limitar?" Isso entende
errado contra o que o princípio protege. Menor privilégio não é um julgamento sobre a honestidade de
alguém. Ele limita o **estrago** de qualquer coisa que dê errado agindo como aquela pessoa, e quase
tudo o que dá errado não é a pessoa:

| o que dá errado | sem menor privilégio | com ele |
|---|---|---|
| a senha de alguém da equipe vaza | o atacante tem tudo o que a pessoa tocava | o atacante tem só o que o trabalho exigia |
| um programa tem um defeito | o defeito faz tudo o que a conta do programa faz | o defeito fica preso numa conta pequena |
| alguém comete um erro | um comando errado apaga qualquer coisa | um comando errado falha por falta de permissão |
| um malware roda num notebook | roda como quem estiver logado | uma conta do dia a dia não consegue instalá-lo no sistema todo |

Cada linha é um caso em que a pessoa era confiável e o acesso ainda assim causou dano. **Quanto menor o
acesso, menor o raio de explosão** (*blast radius*), a expressão que se usa para o quanto o dano se
espalha a partir de uma falha.

### Duas ideias vizinhas

**Necessidade de saber** (*need to know*) é o menor privilégio aplicado à informação. Uma pessoa pode ter
o cargo para ver uma categoria de dados e ainda assim receber só a parte que a tarefa atual exige. O
bruno, no financeiro, precisa dos salários; quem embala os pedidos precisa do endereço de entrega, e não
do histórico de compras do cliente.

**Negar por padrão** é a mesma ideia aplicada a regras, e a aula 5 já a usou na rede: começar sem nada
permitido e acrescentar o que é preciso. Um sistema projetado ao contrário, tudo permitido e algumas
coisas retiradas, vaza toda permissão que alguém esqueceu de retirar.

### O que o menor privilégio custa

Ele não sai de graça. Toda permissão concedida é um pedido que alguém faz e alguém aprova, e toda tarefa
que precisa de uma permissão que ninguém previu é um atraso. A falha comum é desistir do princípio no
terceiro atraso e fazer de todo mundo administrador. A saída é tornar a concessão de acesso rápida e
registrada, e não conceder tudo de antemão. O registro de riscos da aula 3 é onde vai uma exceção
deliberada, com motivo e data.
