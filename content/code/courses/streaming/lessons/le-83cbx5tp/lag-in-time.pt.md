---
title: Lag em mensagens, e lag em segundos
version: 1
---

**Um lag de mil mensagens não diz nada sozinho.** Num tópico que recebe mil vendas por segundo, é um
segundo de atraso, e ninguém vai notar. Num tópico que recebe uma venda por minuto, são quase
dezessete horas, e o site está errado desde ontem. O número que o `kafka-consumer-groups.sh`
imprime é uma contagem, e a pergunta que as pessoas fazem sobre um stream é uma duração: *quão velha
é a coisa mais nova de que o consumidor já cuidou?*

Há dois jeitos de transformar uma na outra, e eles respondem perguntas um pouco diferentes.

**Dividir pela taxa.** Se o lag é de 400 mensagens e o consumidor trata dez por segundo, ele precisa
de quarenta segundos para alcançar o fim, desde que nada mais chegue. Esse é o tempo para esvaziar, e
é o número certo para decidir se faltam consumidores. Ele erra quando a taxa muda, o que nos caixas
de uma loja acontece a toda hora.

**Olhar a própria mensagem.** Todo registro do Kafka carrega um timestamp, definido pelo produtor
quando o criou, a menos que o tópico diga outra coisa (a lição 9 separa os dois tipos). A primeira
mensagem que o grupo não tratou está esperando no offset confirmado; leia-a, subtraia o timestamp
dela do relógio, e você tem há quanto tempo ela espera. **Esse é o lag em tempo, e é o que um cliente
sente**: o estoque no site tem essa quantidade de segundos.

## Medindo

A ferramenta do próprio Kafka não imprime o segundo tipo, então aqui vai um programa pequeno que
imprime. Ele pede ao cluster os offsets confirmados do grupo, lê a mensagem que espera em cada um e
compara o timestamp dela com o relógio. Salve como `~/work/lag_seconds.py`:

```schooling-example
{
  "language": "python",
  "file": "lag_seconds.py",
  "parts": [
    {
      "code": "\"\"\"lag_seconds.py: how far behind a consumer group is, in messages and in seconds.\n\n    python lag_seconds.py GROUP\n\"\"\"\nimport sys\nimport time\n\nfrom confluent_kafka import Consumer, TopicPartition\n\ngroup = sys.argv[1]\nconf = {\"bootstrap.servers\": \"localhost:9092\", \"enable.auto.commit\": False}\n",
      "note": "O grupo a medir é o argumento. Nada aqui entra nesse grupo."
    },
    {
      "code": "asker = Consumer({**conf, \"group.id\": group})\nreader = Consumer({**conf, \"group.id\": \"lag-seconds\"})\n",
      "note": "Dois consumidores com dois trabalhos. **`asker` leva o id do grupo só para pedir os offsets dele**: nunca assina o tópico, então o grupo não rebalanceia porque alguém olhou. `reader` busca uma mensagem por partição, num grupo próprio."
    },
    {
      "code": "topic = asker.list_topics(\"sales\").topics[\"sales\"]\nparts = [TopicPartition(\"sales\", p) for p in sorted(topic.partitions)]\nnow = time.time()\nfor tp in asker.committed(parts, timeout=10):\n    low, high = asker.get_watermark_offsets(tp, timeout=10)\n    at = tp.offset if tp.offset >= 0 else low\n    if at >= high:\n        print(f\"partition {tp.partition}: 0 messages behind\")\n        continue\n",
      "note": "As partições de `sales`, e para cada uma o offset confirmado do grupo e o fim da partição, que é o mesmo par que a ferramenta do grupo subtrai."
    },
    {
      "code": "    reader.assign([TopicPartition(\"sales\", tp.partition, at)])\n    msg = reader.poll(10)\n    written = msg.timestamp()[1] / 1000\n    print(f\"partition {tp.partition}: {high - at} messages behind,\",\n          f\"the oldest written {now - written:.0f} s ago\")\nasker.close()\nreader.close()",
      "note": "A mensagem que espera no offset confirmado. `timestamp()` dá o tipo e os milissegundos desde 1970; a diferença para agora é quanto ela esperou."
    }
  ]
}
```

Rode-o no primeiro shell enquanto os caixas da seção anterior ainda estão vendendo:

```
ubuntu@stream:~/work$ python lag_seconds.py stock
partition 0: 54 messages behind, the oldest written 11 s ago
partition 1: 182 messages behind, the oldest written 12 s ago
partition 2: 0 messages behind
```

Ponha ao lado da saída da ferramenta do grupo logo antes e os dois concordam na contagem, mais ou
menos as vendas que chegaram entre um e outro. O que o segundo número acrescenta é que **as duas
partições estão atrasadas em contagens muito diferentes e mais ou menos no mesmo tempo**. O consumidor pega
mensagens das duas conforme chegam, então a mensagem mais antiga esperando em cada uma foi escrita
mais ou menos no mesmo momento; a partição 1 simplesmente recebe mais lojas. Um painel que somasse
as contagens diria que o problema é a partição 1. O tempo diz que é o consumidor inteiro.

Quando o consumidor alcança o fim, o mesmo programa não tem nada esperando para ler:

```
ubuntu@stream:~/work$ python lag_seconds.py stock
partition 0: 0 messages behind
partition 1: 0 messages behind
partition 2: 0 messages behind
```

## Qual pôr numa tela

| número | responde | use para |
|---|---|---|
| lag em mensagens | quanto trabalho está na fila | dimensionar: quantos consumidores, quanto tempo para esvaziar |
| lag em tempo | quão velha está a saída | promessas: "o estoque nunca tem mais de um minuto" |
| como o lag muda | se está piorando | alertas, na última seção desta lição |

O lag em tempo tem uma armadilha própria. **Ele confia no timestamp do registro**, e um produtor com
o relógio errado, ou um caixa que manda de uma vez as vendas que guardou enquanto estava offline,
faz ele mentir para qualquer lado. A lição 9 é exatamente sobre isso; para o lag do seu próprio
consumidor, em que o produtor é um programa que você roda, o timestamp do registro basta.
