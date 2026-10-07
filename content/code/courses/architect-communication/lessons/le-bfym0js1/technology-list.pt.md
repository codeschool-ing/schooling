---
title: A armadilha da lista de tecnologias
version: 1
---

**Um público de quem decide não decide tecnologias, então uma apresentação organizada em torno de
tecnologias não lhe dá nada para decidir.** É o formato mais comum da apresentação de um arquiteto,
e o motivo mais comum para a reunião terminar com "vamos falar disso depois".

## Como ela é

Este é o roteiro do primeiro rascunho de Lívia, antes de Bruna lê-lo:

1. Arquitetura atual (um diagrama com onze caixas e os logotipos de seis produtos)
2. Limites de conexão do PostgreSQL e como funcionam
3. Replicação por streaming: síncrona contra assíncrona
4. Comparação de opções de pool de conexões
5. Arquitetura proposta (o mesmo diagrama com doze caixas)
6. Plano de migração em quatro fases
7. Perguntas

Todos os slides estão corretos. A palavra *checkout* aparece pela primeira vez no slide 5, o custo
no slide 6, e a decisão em lugar nenhum. Otávio teria passado oito minutos aprendendo como funciona
a replicação do PostgreSQL, coisa que não pediu para aprender e de que não vai precisar de novo, e a
reunião teria terminado sem ninguém ser chamado a decidir nada.

## Por que acontece

A lista tem o formato do trabalho. Lívia passou duas semanas com modos de replicação e pools de
conexões, então eles parecem a substância da proposta. **Para o público, eles são o método, e
ninguém aprova um método; aprova-se um resultado por um preço.** É a maldição do conhecimento da
aula 3 outra vez: os detalhes com que quem apresenta brigou parecem essenciais justamente porque ela
brigou com eles.

Há também um motivo menos confortável. Um slide de tecnologia é seguro. Ninguém consegue discordar
de como funciona a replicação por streaming, então uma apresentação cheia deles nunca encontra
resistência, e também nunca obtém uma decisão. **Um slide de decisão convida à discordância, e é
para isso que ele existe.**

## A reescrita

O segundo roteiro, depois da pergunta de Bruna, "o que você quer que eles digam no final?":

1. Sexta à noite: nossas três horas de maior movimento, e uma parcela crescente dos checkouts falha
2. 6 de março: quanto custa uma sexta ruim (32 minutos, 1.350 checkouts com falha)
3. Por quê: dois sistemas dividem um banco e disputam por ele no pico
4. Quatro opções e seus preços
5. A recomendação: uma réplica, seis semanas-engenheiro e R$ 4.000 por mês
6. O que precisamos hoje: aprovação, para que o time de plataforma comece em 6 de abril

Seis slides, cada um com uma frase como título, e um diagrama com três caixas no slide 3. O modo de
replicação não é mencionado. Se Caio perguntar como a réplica se mantém atualizada, a resposta é uma
frase e um link para o documento de design, e o fato de ele ter perguntado diz algo sobre o que o
preocupa.

## A tecnologia no lugar dela

Tecnologias aparecem numa apresentação de decisão de exatamente duas formas:

- **como nome de uma opção**, com preço e comparada ("um servidor de banco maior: R$ 9.000 por
  mês");
- **como resposta a uma pergunta**, quando alguém pergunta.

Em todo o resto, diga o que a tecnologia faz pela decisão. Não "vamos adicionar o PgBouncer", mas
"vamos racionar as conexões para que um sistema não consiga ficar com todas".
