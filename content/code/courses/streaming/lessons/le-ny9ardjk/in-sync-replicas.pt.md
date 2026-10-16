---
title: Réplicas em sincronia: as cópias que contam
version: 1
---

**As réplicas em sincronia, a ISR (*in-sync replicas*), são as réplicas que acompanharam o líder
recentemente o bastante para merecer confiança com os dados dele.** Uma réplica que fica para trás
é tirada da lista, e enquanto está fora ninguém espera por ela: o high watermark anda com as
réplicas que continuam na lista, e uma escrita que precisa de todas as cópias precisa só das
delas. Ela volta para a lista quando alcança o líder.

"Recentemente o bastante" é uma configuração, lida do broker:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --broker 1 | grep replica.lag.time.max.ms
  replica.lag.time.max.ms=30000 sensitive=false synonyms={DEFAULT_CONFIG:replica.lag.time.max.ms=30000}
```

**Trinta segundos, e medidos em tempo, não em mensagens.** Um seguidor sai da ISR quando não esteve
totalmente em dia com o líder em nenhum momento dos últimos trinta segundos. Versões antigas do
Kafka também contavam quantas mensagens um seguidor estava atrás, o que tirava seguidores
saudáveis sempre que chegava uma rajada de escritas; um limite de tempo só tira um seguidor que
está de fato travado.

## Um nó que para sem morrer

Uma queda é o caso fácil: o processo some e as conexões caem. O difícil é um nó vivo que não
trabalha, preso numa pausa longa de coleta de lixo, num disco que ficou lento, ou numa máquina
virtual que o host congelou. O `kill -STOP` produz exatamente isso: o processo mantém a memória, as
portas e os arquivos, e para de rodar. Congele o nó 3 e espere mais de trinta segundos:

```
ubuntu@stream:~/work$ kill -STOP $(pgrep -f "^[^ ]*java .*node3/")
ubuntu@stream:~/work$ sleep 40; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2	Elr: 	LastKnownElr: 
```

O padrão no `pgrep` casa com o processo Java cuja linha de comando cita o diretório do nó 3, o
mesmo padrão que o `cluster.sh` usa; um mais solto, como `node3` sozinho, poderia casar com o seu
próprio shell.

O nó 3 saiu de todas as ISRs. A partição 2, de que ele era líder, agora tem o nó 1 como líder,
porque um líder congelado não responde a ninguém e os controllers pararam de ter notícias dele. Toda
partição ainda tem um líder e duas cópias em sincronia, o que basta para receber escritas sob
`min.insync.replicas=2`,
como explica a próxima seção.

Agora solte-o:

```
ubuntu@stream:~/work$ kill -CONT $(pgrep -f "^[^ ]*java .*node3/")
ubuntu@stream:~/work$ sleep 10; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

Dez segundos depois de voltar, o nó 3 tinha buscado o que perdeu e estava de novo em todas as ISRs.
Ele **não** recuperou a liderança da partição 2: uma réplica que volta, volta como seguidora, e a
seção sobre um nó que morre mostra como a liderança retorna ao preferido.

## Por que a lista importa

A ISR é a resposta a duas perguntas que toda escrita e toda falha fazem:

- **Quem precisa ter um registro antes de ele contar como confirmado?** Cada membro da ISR. Não
  toda réplica, ou um nó morto pararia todas as escritas; não só o líder, ou um registro
  confirmado poderia se perder junto com ele.
- **Quem pode virar líder quando o líder cai?** Um membro da ISR, porque só deles se sabe que têm
  todo registro confirmado. Escolher qualquer outro é a eleição não limpa de que trata uma seção
  mais adiante nesta lição.

Uma ISR encolhendo é também o primeiro sinal de problema que um operador vê. Uma partição cuja ISR
é menor que a lista de réplicas está **sub-replicada** (*under-replicated*), e a lição 16 põe isso
na lista do que deve gerar alerta.
