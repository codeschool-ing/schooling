---
title: O RabbitMQ na prática
version: 1
---

Os scripts rodam na imagem `tools`, iniciados com `docker compose run --rm`, que constrói a imagem na
primeira vez. `--progress quiet` tira do caminho as mensagens do próprio Compose sobre criar o
contêiner, para aparecer só a saída do script.

## Publicando para ninguém

Publique dois pedidos antes de qualquer serviço declarar uma fila, e depois pergunte ao RabbitMQ que
filas ele tem:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python publish.py 2
published {"type": "OrderPlaced", "order": 1, "sku": "coffee", "qty": 1}
published {"type": "OrderPlaced", "order": 2, "sku": "coffee", "qty": 2}
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
```

O `publish.py` imprimiu as duas mensagens como publicadas, e nada levantou erro, **e o broker não guarda
nenhuma das duas**: a lista de filas está vazia. A exchange `orders` existia, nenhuma fila estava ligada a ela, então as duas mensagens
não bateram com nenhuma ligação e foram descartadas. É o caso sobre o qual a seção anterior avisou, e ele
acontece de verdade sempre que um publicador começa antes de os consumidores terem rodado alguma vez.

## Filas declaradas, mensagens guardadas

Rodar cada consumidor uma vez declara a fila dele e a liga. Sem nada para ler ainda, cada um espera dois
segundos e para:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python consume.py email
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python consume.py warehouse
```

Publique quatro pedidos agora, numerados a partir de 3 para cada pedido da aula ter o seu número, e
olhe de novo:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python publish.py 4 3
published {"type": "OrderPlaced", "order": 3, "sku": "coffee", "qty": 3}
published {"type": "OrderPlaced", "order": 4, "sku": "coffee", "qty": 4}
published {"type": "OrderPlaced", "order": 5, "sku": "coffee", "qty": 5}
published {"type": "OrderPlaced", "order": 6, "sku": "coffee", "qty": 6}
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
warehouse	4
email	4
```

**Cada fila tem a sua própria cópia dos quatro**: uma mensagem publicada, duas ligações aceitas, duas
cópias guardadas. O serviço de e-mail pode ler os seus quatro agora e os do depósito podem ficar ali,
intocados, até o depósito estar pronto. Leia a fila de e-mail:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python consume.py email
email on c34db0ff8c7f: order 3
email on c34db0ff8c7f: order 4
email on c34db0ff8c7f: order 5
email on c34db0ff8c7f: order 6
```

## Consumidores concorrentes

O depósito tem mais trabalho por pedido, então roda dois consumidores na mesma fila. Publique mais seis
pedidos, do 7 ao 12, para a fila do depósito ficar com dez, e inicie dois consumidores ao mesmo tempo, cada um no seu
contêiner:

```
ana@vm:~/lab/brokers$ docker compose --progress quiet run --rm tools python publish.py 6 7 > /dev/null
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
warehouse	10
email	6
ana@vm:~/lab/brokers$ for i in 1 2; do docker compose --progress quiet run --rm tools python consume.py warehouse & done; wait
warehouse on f1397d7a1ff4: order 3
warehouse on 0bc3105ee4db: order 4
warehouse on f1397d7a1ff4: order 5
warehouse on 0bc3105ee4db: order 6
warehouse on f1397d7a1ff4: order 7
warehouse on 0bc3105ee4db: order 8
warehouse on 0bc3105ee4db: order 10
warehouse on f1397d7a1ff4: order 9
warehouse on 0bc3105ee4db: order 12
warehouse on f1397d7a1ff4: order 11
```

Os dois contêineres, com hostnames diferentes, **dividiram as dez mensagens entre si**, cada um tratando
algumas e nenhum tratando alguma duas vezes. É assim que uma fila escala os consumidores: acrescente mais
na mesma fila, e o broker espalha as mensagens entre eles. O `prefetch_count=1` importa aqui: sem ele, o
RabbitMQ pode empurrar um lote grande para quem se conectou primeiro, e o segundo fica parado enquanto o
primeiro percorre um acúmulo que não precisava segurar. A ordem das linhas é a ordem em que os dois
terminaram, o que já mostra que **consumidores concorrentes não mantêm a ordem da fila**; a aula 7 volta
a isso.

Depois, a fila do depósito está vazia, e a fila de e-mail guarda os pedidos 7 a 12, esperando um
consumidor de e-mail que não está rodando:

```
ana@vm:~/lab/brokers$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
warehouse	0
email	6
```
