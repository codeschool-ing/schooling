---
title: Quantas partições
version: 1
---

**O número de partições é a configuração de maior consequência de um tópico, e a mais difícil de
mudar depois.** Ele é o teto de quantas cópias de um consumidor podem ler o tópico ao mesmo tempo, é
como o tópico se espalha pelos brokers, e faz parte do hash que manda cada chave para uma partição.
Duas dessas coisas são fáceis de raciocinar. A terceira é a armadilha.

## O que mais partições compram e custam

| mais partições | compram | custam |
|---|---|---|
| leitura | mais consumidores num grupo trabalhando ao mesmo tempo (lição 4) | nada, até passarem do número de consumidores que você roda |
| escrita | escritas espalhadas por mais brokers | lotes menores e em maior número; cada partição faz os seus lotes |
| o cluster | carga espalhada por mais máquinas | mais arquivos abertos, mais réplicas para manter em dia, uma recuperação mais longa quando um broker cai (lição 5) |
| ordem | nada; a ordem por chave vale com qualquer número | nada |

Um jeito útil de escolher: estime o máximo de consumidores que você vai querer lendo o tópico num
grupo, e quanto um consumidor aguenta, e escolha um número igual ou acima disso. Um tópico que recebe
alguns milhares de mensagens por segundo não precisa de cem partições, e uma dúzia custa pouco. Os
caixas de cinco lojas seriam servidos por três durante anos.

## Acrescentar partições muda chaves de lugar

O número de partições está no hash: uma chave vai para `hash(key) % partitions`. Mude o número e a
resposta muda para algumas chaves. O Kafka deixa acrescentar partições a um tópico, e não move uma
única mensagem existente, então depois da mudança **as mensagens antigas de uma chave ficam numa
partição e as novas em outra**:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 4
ubuntu@stream:~/work$ python keys.py --partitioner murmur2_random shops recife=4p olinda=4p caruaru=4p natal=4p joao-pessoa=4p
recife       partition 0  offset 5
caruaru      partition 0  offset 6
olinda       partition 1  offset 8
natal        partition 2  offset 2
joao-pessoa  partition 2  offset 3
```

Com três partições, o `murmur2_random` mandava o Recife para a 2, Olinda e João Pessoa para a 0, e
Caruaru e Natal para a 1. Com quatro, Recife e Caruaru foram para a 0, Olinda para a 1, e Natal e João
Pessoa para a 2. **As cinco lojas mudaram.** As mensagens antigas de cada loja ficam onde estavam,
então a história do Recife agora está dividida entre a partição 2, até a mudança, e a partição 0,
depois dela. Um consumidor lendo as duas partições não vê ordem nenhuma entre as duas metades, que é a
reordenação contra a qual a lição 2 alertou, criada por uma mudança de configuração. Só uma chave cujo
hash por acaso dá o mesmo resto fica no lugar, e com cinco chaves nenhuma ficou.

## Menos, nunca

Remover partições não é possível de jeito nenhum:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 2
Error while executing topic command : The topic shops currently has 4 partition(s); 2 would not be an increase.
[2026-10-10 17:01:51,108] ERROR org.apache.kafka.common.errors.InvalidPartitionsException: The topic shops currently has 4 partition(s); 2 would not be an increase.
 (org.apache.kafka.tools.TopicCommand)
```

`2 would not be an increase`. Uma partição guarda mensagens e offsets em que consumidores registraram
posições, e juntar duas delas daria às duas uma ordem nova e quebraria todo offset registrado, então o
Kafka não oferece isso.

Então **escolha o número no dia em que criar o tópico**, com folga para crescer, porque os jeitos de
mudá-lo depois são uma migração: um tópico novo com o número novo, todo leitor movido para ele, e o
antigo mantido até ninguém precisar dele. A lição 16 faz esse tipo de mudança por outro motivo, o
reprocessamento.
