---
title: Endpoints, onde uma aplicação encontra um canal
version: 1
---

Roteadores e tradutores vivem no meio de um fluxo. Um *endpoint* fica na borda: é o código que liga
uma aplicação, que não sabe nada de messaging, a um canal, que não sabe nada da aplicação. A maior
parte das decisões deste grupo trata de **quem decide quando uma mensagem é lida, e o que acontece
com o trabalho da própria aplicação se a leitura der errado.**

A ideia errada a abandonar é que o endpoint é encanamento, umas poucas linhas que chamam a biblioteca
cliente do broker. Essas poucas linhas decidem em que ritmo um sistema é alimentado, se duas cópias de
um serviço dividem o trabalho ou o duplicam, e se uma mensagem sobrevive a uma queda. O livro dá onze
padrões ao grupo, e eles se organizam em três perguntas.

## Mantendo o messaging fora da aplicação

Um *messaging gateway* embrulha o código de messaging atrás de uma interface que fala a língua da
aplicação. O Rota, o planejador de rotas feito em casa, publica o plano de caminhões de cada dia. O
código Kotlin dele chama `planPublisher.publish(plan)`; só a classe atrás dessa interface sabe que
existe um gerenciador de filas, como a fila se chama e como um plano vira bytes. O resto do Rota pode
ser testado sem o MQ rodando, e uma troca de broker mexe numa classe só. O *messaging mapper* é a
parte dessa classe que transforma um objeto de domínio em mensagem e de volta.

Um *service activator* é a mesma ideia virada para o outro lado. Ele pega um serviço que foi escrito
para ser chamado e o torna chamável por uma mensagem. O ramo do SAP no fluxo de pedidos termina num
deles: lê um pedido de loja de uma fila, chama a BAPI `BAPI_SALESORDER_CREATEFROMDAT2`, que cria uma
ordem de venda, e põe o resultado no canal de resposta. **A BAPI não sabe nada de mensagens**, e o
mesmo módulo de função continua sendo chamado por outros programas de outras maneiras.

O Spring Integration usa os dois nomes como estão no livro, `gateway` e `service-activator`, um dos
sinais mais claros de quão longe o vocabulário viajou.

## Quem decide quando uma mensagem é lida

| consumidor | quem decide quando uma mensagem é lida | serve quando |
|---|---|---|
| consumidor por polling | a aplicação, quando pede | o receptor precisa controlar o próprio ritmo |
| consumidor orientado a eventos | o sistema de messaging, quando a mensagem chega | as mensagens devem ser tratadas assim que chegam |
| consumidores concorrentes | qualquer um de vários consumidores que estiver livre | um consumidor sozinho não dá conta |
| consumidor seletivo | o consumidor, por uma condição sobre a mensagem | um consumidor quer algumas das mensagens de um canal compartilhado |
| assinante durável | o consumidor, e o broker guarda o que ele perdeu | um assinante não pode perder eventos enquanto está fora |

Um *consumidor por polling* (*polling consumer*) pede uma mensagem quando está pronto para ela. O job
ABAP que carrega o arquivo do Coleta às 02:00 é um consumidor por polling de um arquivo em vez de uma
fila, e a forma é a mesma: quem recebe escolhe a hora. **Um consumidor por polling é como um receptor
frágil se protege.** Durante o fechamento do mês, nos cinco primeiros dias úteis de cada mês (aula 1),
Edson quer que o SAP receba pedidos de loja a no máximo 50 por minuto. Um consumidor que pede 50
mensagens por minuto entrega isso, tenha a fila o que tiver.

Um *consumidor orientado a eventos* (*event-driven consumer*) recebe cada mensagem quando ela chega.
Um fluxo do IIB que começa com um nó MQInput se comporta assim do ponto de vista do fluxo: o fluxo
roda quando há uma mensagem. É o padrão natural para um fluxo que deve reagir rápido, e ele não dá ao
receptor nenhuma voz sobre o ritmo.

*Consumidores concorrentes* (*competing consumers*) são vários consumidores lendo um mesmo canal ponto
a ponto, de modo que cada mensagem vai para um deles. Rodar três cópias do fluxo de pedidos do SAP na
mesma fila mais ou menos triplica o que ele aguenta, e perde a garantia de que os pedidos são
processados na ordem em que chegaram. A aula 10 trata de por que isso importa e do que fazer quando
importa.

Um *consumidor seletivo* (*selective consumer*) lê só as mensagens que atendem a uma condição, como um
seletor de mensagens JMS `plant = 'ALAGOA'`. O primeiro desenho da Joana para o lado do Business
Central no fluxo de pedidos usava um: uma fila única de pedidos, com o adaptador do Business Central
selecionando os pedidos de Alagoa e o lado do SAP selecionando o resto. Rui a convenceu do contrário em
dez minutos. **Uma mensagem que nenhum seletor pega fica na fila para sempre, e ninguém é avisado**,
então um pedido de loja de uma quinta fábrica, ou com um código de fábrica digitado errado, sumiria
numa fila com cara de saudável. E todo consumidor paga pela seleção em cada mensagem que pula. Um
roteador baseado em conteúdo põe a decisão num lugar só e lhe dá uma saída padrão, que é o desenho que
o fluxo de pedidos tem.

Um *assinante durável* (*durable subscriber*) é um assinante de um canal publish-subscribe cuja
assinatura sobrevive à conexão: o broker guarda as mensagens publicadas enquanto ele estava fora. O
Portal B2B assina as mudanças de preço. Quando ele passa por um deploy e fica dez minutos fora, uma
assinatura não durável perderia cada mudança de preço publicada no meio-tempo, e padarias fariam
pedidos a preços que não existem mais. O custo é a imagem no espelho: **um assinante durável que nunca
volta continua acumulando mensagens**, e a assinatura de um consumidor aposentado precisa ser removida
por alguém que se lembre dela.

## Sobrevivendo a falhas na borda

Dois padrões do grupo tratam do que acontece quando um endpoint falha no meio do trabalho.

O *receptor idempotente* (*idempotent receiver*) é um receptor que pode processar a mesma mensagem
duas vezes sem dano. A aula 10 o tratou a fundo, porque a entrega at-least-once torna as duplicatas
normais, não excepcionais. Ele aparece aqui porque é um padrão de endpoint: idempotência é
propriedade do receptor, não do canal.

Um *cliente transacional* (*transactional client*) faz de pegar a mensagem e fazer o trabalho uma
unidade só: se o trabalho falha, a mensagem volta para a fila como se nunca tivesse sido lida. No IBM
MQ isso é um get sob syncpoint, confirmado só depois que o trabalho dá certo. O livro também usa o
padrão do lado de quem envia, em que mandar uma mensagem faz parte da mesma transação que a mudança no
banco que a causou; o outbox da aula 10 é a resposta quando o banco e o broker não podem compartilhar
uma transação.

A armadilha é acreditar que uma transação vai mais longe do que vai. O fluxo de pedidos do SAP lê o
pedido de loja sob syncpoint e chama a BAPI. Se o SAP grava a ordem de venda e o fluxo falha antes de
confirmar o get, a mensagem volta para a fila, e a tentativa seguinte cria a ordem uma segunda vez.
**O commit do SAP não faz parte da unidade de trabalho do MQ, então a transação protege a mensagem, e
não a ordem.** É por isso que o fluxo de pedidos também é um receptor idempotente: antes de criar uma
ordem, ele verifica se o SAP já tem uma para aquele número de pedido da rede, aquela loja e aquela
fábrica.

## Lendo um endpoint numa revisão

Três perguntas pegam a maioria dos defeitos de endpoint, e cada uma corresponde a um padrão acima:

1. Quem dita o ritmo? Se ninguém sabe dizer, o receptor é orientado a eventos por omissão e não tem
   proteção nenhuma no dia em que a fila tiver 40.000 mensagens depois de uma queda.
2. O que acontece com uma mensagem que ninguém pega? Um seletor que não casa com nada, uma assinatura
   durável de um sistema aposentado, uma fila cujo único consumidor foi desligado: cada um guarda
   mensagens que ninguém está esperando.
3. O que a transação cobre de verdade? Liste cada sistema que muda quando a mensagem é tratada e
   pergunte quais deles desfazem se o último passo falhar. Os que não desfazem precisam de um receptor
   idempotente.
