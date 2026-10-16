---
title: A mensagem que falha toda vez
version: 1
---

Pelo menos uma vez tem mais uma falha, e é a que trava uma fila inteira. Uma **mensagem envenenada** é
uma que nunca pode ser processada: um corpo que não é JSON válido, um id de pedido que não existe, um
campo que o consumidor não entende. Se o consumidor simplesmente falha e deixa o broker entregar de
novo, a mensagem volta, falha de novo, volta de novo. Numa fila com ordem, ela trava tudo atrás dela; em
qualquer fila, prende um consumidor num laço para sempre.

**Uma falha que nunca vai dar certo precisa ser separada de uma que talvez dê**, e as duas vão para
lugares diferentes:

| a falha | exemplo | o que fazer |
| --- | --- | --- |
| transitória | o banco estourou o tempo, a operadora respondeu 503 | tentar de novo, com espera, aula 11 |
| permanente | o corpo não dá para interpretar, o produto não existe | pôr a mensagem de lado para uma pessoa |

## A fila de mensagens mortas

O lado onde ela fica é uma **fila de mensagens mortas** (*dead-letter queue*). No RabbitMQ uma fila
declara `x-dead-letter-exchange`, como `charges` faz em `topology.py`, e uma mensagem que o consumidor
rejeita com `requeue=False`, ou uma que expira, é republicada ali em vez de descartada. O `pay.py` trata
um corpo que não é JSON como permanente e o rejeita.

Publique um pedido de pagamento quebrado e rode o consumidor:

```
ana@vm:~/lab/delivery$ $R publish.py q-4 899 --broken
confirmed by the broker: q-4
ana@vm:~/lab/delivery$ $R pay.py
rejected q-4: not JSON, sent to the dead-letter queue
ana@vm:~/lab/delivery$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
charges.dead	1
charges	0
```

O broker confirmou `q-4`, porque era uma mensagem perfeitamente boa até onde o broker conseguia ver. O
consumidor não conseguiu interpretá-la, disse isso, e a rejeitou. **`charges` está vazia e continua
andando; `charges.dead` guarda a única mensagem que ninguém conseguiu tratar**, com cabeçalhos que
registram de onde ela veio e por que morreu.

## Uma fila de mensagens mortas é uma promessa de olhar

Uma fila de mensagens mortas que ninguém lê é um jeito mais lento de descartar mensagens. Ela precisa de
um alerta quando não está vazia, de uma pessoa que olhe o que chegou, e de um jeito de mandar uma
mensagem de volta à sua fila quando a causa for corrigida. Filas gerenciadas têm a mesma ideia com o
mesmo nome: a política de *redrive* da SQS move uma mensagem depois de um número definido de
recebimentos, e o Service Bus e o Pub/Sub têm configurações próprias de mensagens mortas.

Quando terminar a aula, pare o broker e remova o volume dele:

```sh
docker compose down -v
```
