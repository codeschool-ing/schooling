---
title: Offsets, partição por partição
version: 1
---

**Um offset é uma posição numa partição, e não quer dizer nada fora dela.** Cada partição conta a
partir de 0 por conta própria, então um tópico de três partições tem três offsets 0, e os offsets de
duas partições não dizem nada sobre qual mensagem foi escrita primeiro. O `minilog.py` da lição 2
tinha um contador; um tópico tem um por partição.

Mande mil vendas com os caixas da lição 1, tão rápido quanto o Kafka aceitar, e pergunte até onde
cada partição chegou:

```
ubuntu@stream:~/work$ python tills.py --count 1000 --rate 0
sent 1000 sales to sales, the last one at 11:56:20
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic sales
sales:0:211
sales:1:789
sales:2:0
```

O `kafka-get-offsets.sh` imprime `tópico:partição:offset`, e sem `--time` o offset é o **log-end
offset**: o offset que a próxima mensagem daquela partição vai receber, que também é quantas
mensagens ela já recebeu, desde que nada tenha sido apagado. A partição 0 tem 211 vendas e a partição
1 tem 789. **A partição 2 não tem nenhuma**, e a seção anterior diz por quê: o `tills.py` usa o
particionador padrão do cliente Python, e nenhum dos cinco nomes de loja cai na partição 2 por esse
hash. Um tópico de três partições é, para essas vendas, um tópico de duas, uma delas quase quatro
vezes mais movimentada que a outra. Nada avisa sobre isso; este comando é como você descobre.

## As duas pontas de uma partição

A outra ponta é o offset **mais antigo**, o primeiro ainda guardado:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic sales --time earliest
sales:0:0
sales:1:0
sales:2:0
```

Os três são 0, porque nada foi apagado ainda. Entre as duas pontas, todo offset guarda uma mensagem,
e um leitor pode começar em qualquer um deles. A seção sobre retenção move a ponta mais antiga, e a
de compactação deixa buracos no meio.

| nome | o que é | como ver |
|---|---|---|
| mais antigo, ou **log start offset** | o primeiro offset ainda guardado | `kafka-get-offsets.sh --time earliest` |
| mais recente, ou **log-end offset** | o offset que a próxima mensagem vai receber | `kafka-get-offsets.sh` |
| o **offset commitado** de um consumer group | de onde aquele grupo vai continuar | lição 4 |

## Lendo a partir de um offset escolhido

O console consumer consegue ler uma partição a partir de qualquer offset dela:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --partition 1 --offset 5 --max-messages 2 --formatter-property print.offset=true
Offset:5	{"sale": "rec-000006", "shop": "recife", "book": "bk-06", "qty": 1, "cents": 6200, "at": "2026-03-02T09:00:43-03:00"}
Offset:6	{"sale": "rec-000007", "shop": "recife", "book": "bk-01", "qty": 2, "cents": 7980, "at": "2026-03-02T09:00:44-03:00"}
Processed a total of 2 messages
```

Os offsets 5 e 6 da partição 1 são `rec-000006` e `rec-000007`, duas vendas do Recife na ordem em que
o caixa as registrou. O offset 5 da partição 0 é outra venda completamente: a partição 0 só guarda as
de Caruaru, a única loja que caiu lá pelo hash. **Um offset só é um endereço junto com a sua
partição.** A lição 4 faz o mesmo a partir de Python, e move um consumer group inteiro para um offset
ou para um horário.
