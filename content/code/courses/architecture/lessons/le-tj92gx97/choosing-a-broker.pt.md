---
title: Escolhendo um broker
version: 1
---

A primeira pergunta não é que produto. É **se as mensagens são trabalho a fazer ou um registro do que
aconteceu**, e a resposta aponta uma família antes de apontar um nome.

| se as mensagens são… | e você precisa de… | use |
| --- | --- | --- |
| tarefas para trabalhadores, cada uma feita uma vez | roteamento por chave ou padrão, retry por mensagem, prioridades | uma fila: RabbitMQ, ou SQS ou Service Bus se você já está nessa nuvem |
| eventos que muitos serviços vão ler, alguns ainda não escritos | releitura, leitores novos começando do passado, volume muito alto | um log: Kafka, ou um Kafka gerenciado |
| algumas centenas de mensagens por minuto entre dois serviços | o mínimo possível para operar | a fila gerenciada do provedor |
| um fluxo para analytics e um fluxo para serviços | os dois | muitas vezes um log, com o grupo de consumidores de cada serviço fazendo papel de "fila" |

## A resposta da Quitanda

A Quitanda publica `OrderPlaced` para vários serviços, e a equipe de analytics pediu o histórico de
pedidos para construir um modelo de vendas no próximo trimestre. **Esse segundo desejo decide para os
pedidos**: um log guarda os eventos para quem vier depois, e uma fila os teria apagado. A lista de
separação do depósito, por outro lado, é trabalho para uma pequena equipe de separadores, com retry por
item quando um separador relata um problema, e ninguém vai querer reler uma lista de separação; uma fila
encaixa nela, e rodar os dois não é incomum.

## O que toda escolha custa

Qualquer que seja o broker, as mesmas três perguntas chegam com ele, e o broker não responde nenhuma
sozinho:

1. O que acontece quando uma mensagem é entregue duas vezes, ou um consumidor morre no meio de uma?
2. Que mensagens precisam ser processadas em ordem, e que chave as mantém assim?
3. O que acontece com uma mensagem que falha toda vez que é processada?

Essas perguntas são a aula 7. São a diferença entre um sistema que usa um broker e um sistema que
sobrevive a um.
