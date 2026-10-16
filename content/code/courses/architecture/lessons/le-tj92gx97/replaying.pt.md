---
title: Lag, um segundo grupo, e ler tudo de novo
version: 1
---

Chegam mais dois pedidos enquanto o grupo de e-mail não está rodando. O Kafka os guarda; os offsets do
grupo não se mexem, e o lag mostra exatamente o que está esperando:

```
ana@vm:~/lab/brokers$ printf "ana:order 6\ncarla:order 7\n" | kafka console-producer --topic orders --property parse.key=true --property key.separator=:
ana@vm:~/lab/brokers$ kafka consumer-groups --describe --group email

Consumer group 'email' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
email           orders          0          0               0               0               -               -               -
email           orders          1          2               3               1               -               -               -
email           orders          2          3               4               1               -               -               -
```

`LAG` é 1 na partição 1 e 1 na partição 2: um pedido novo de ana, um de carla. Quando os consumidores de
e-mail voltarem, começam do `CURRENT-OFFSET`, leem esses dois e mais nada.

## Um segundo grupo lê tudo

O depósito decide ler o tópico também. Um grupo novo não tem offsets guardados, então começa da mensagem
mais antiga ainda retida, e **lê os sete pedidos, inclusive os cinco que o grupo de e-mail leu há muito
tempo**:

```
ana@vm:~/lab/brokers$ kafka console-consumer --topic orders --group warehouse --from-beginning --max-messages 7 --property print.partition=true --property print.key=true
Partition:1	ana	order 1
Partition:1	ana	order 3
Partition:1	ana	order 6
Partition:2	bruno	order 2
Partition:2	carla	order 4
Partition:2	bruno	order 5
Partition:2	carla	order 7
Processed a total of 7 messages
```

Nada do que o grupo de e-mail fez afetou o grupo do depósito, e nada do que o depósito lê afeta o lag do
grupo de e-mail. No RabbitMQ o depósito precisaria ter a fila ligada antes de os pedidos serem publicados;
aqui ele chegou depois e não perdeu nada, enquanto a retenção do tópico guardar as mensagens.

## Rebobinando

Suponha que o serviço de e-mail tinha um bug que mandou toda confirmação com o endereço errado da loja,
e agora está corrigido. Com um log as mensagens continuam lá, então **a correção pode ser aplicada ao
passado**: volte os offsets do grupo e deixe-o ler de novo. A ferramenta se recusa a mover os offsets de
um grupo com consumidores ativos, e é por isso que o consumidor de console acima pôde sair:

```
ana@vm:~/lab/brokers$ kafka consumer-groups --group email --reset-offsets --to-earliest --topic orders --execute

GROUP                          TOPIC                          PARTITION  NEW-OFFSET     
email                          orders                         0          0              
email                          orders                         1          0              
email                          orders                         2          0              
ana@vm:~/lab/brokers$ kafka consumer-groups --describe --group email

Consumer group 'email' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
email           orders          0          0               0               0               -               -               -
email           orders          1          0               3               3               -               -               -
email           orders          2          0               4               4               -               -               -
```

O offset de cada partição voltou a 0, o lag é o tópico inteiro, e a próxima execução dos consumidores de
e-mail vai mandar as sete confirmações de novo. **Esse é o poder e o perigo de uma releitura**: o
consumidor vai agir sobre mensagens velhas como se fossem novas, então um consumidor que pode ser relido
precisa ser seguro para rodar duas vezes sobre a mesma mensagem. Essa propriedade se chama idempotência,
e é o primeiro assunto da aula 7.

Pare os brokers da aula antes de seguir; a próxima seção não precisa de nada rodando:

```sh
docker compose down -v
```
