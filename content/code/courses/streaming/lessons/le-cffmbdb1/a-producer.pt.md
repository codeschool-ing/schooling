---
title: Um produtor, e a resposta dele
version: 1
---

**Chamar `produce` não manda uma mensagem. Põe a mensagem num buffer e retorna na hora**; uma thread
dentro da biblioteca cliente junta as mensagens em lotes, um por partição, e manda os lotes quando
estão cheios ou já esperaram o bastante. Se uma mensagem chegou ao broker só se sabe depois, quando o
cliente chama uma função que você lhe deu, o **relatório de entrega**. Um programa que nunca olha os
relatórios de entrega não sabe se alguma coisa que produziu foi guardada.

Essa é a imagem errada comum: que o retorno do `produce` quer dizer que a mensagem está no Kafka. O
`tills.py` da lição 1 se safou porque chamava `flush` no fim, que espera toda mensagem ser confirmada,
e nada deu errado. Este produtor diz o que aconteceu com cada mensagem. Salve-o como
`~/work/producer.py`:

```schooling-example
{
  "language": "python",
  "file": "producer.py",
  "parts": [
    {
      "code": "\"\"\"producer.py: send sales to Kafka, and hear back about every one of them.\n\n    python producer.py [--count N] [--linger-ms MS] [--rate R]\n                       [--topic T] [--timeout-ms MS]\n\"\"\"\nimport argparse\nimport json\nimport time\nfrom collections import Counter\n\nfrom confluent_kafka import Producer\n\nSHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=10)\nargs.add_argument(\"--linger-ms\", type=int, default=5)\nargs.add_argument(\"--rate\", type=float, default=0)\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--timeout-ms\", type=int, default=300000)\nargs = args.parse_args()\n",
      "note": "O que ele manda e como chamar. Dez vendas por padrão, cada uma com a loja como chave; `--rate` deixa o envio mais lento, o que o experimento de lotes precisa."
    },
    {
      "code": "producer = Producer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"partitioner\": \"murmur2_random\",\n    \"linger.ms\": args.linger_ms,\n    \"batch.size\": 16384,\n    \"message.timeout.ms\": args.timeout_ms,\n})\n",
      "note": "A configuração. **`murmur2_random`** é o particionador da lição 3, para que as cinco lojas cheguem às três partições. `linger.ms` e `batch.size` dão forma aos lotes; `message.timeout.ms` é quanto tempo o cliente insiste antes de desistir de uma mensagem."
    },
    {
      "code": "delivered, failed = Counter(), Counter()\n\n\ndef report(err, msg):\n    if err is None:\n        delivered[msg.partition()] += 1\n    else:\n        failed[err.str()] += 1\n",
      "note": "**O relatório de entrega.** O cliente o chama uma vez para cada mensagem, de dentro do `poll` ou do `flush`, com um erro ou com a partição em que a mensagem foi guardada."
    },
    {
      "code": "\nfor n in range(1, args.count + 1):\n    shop = SHOPS[n % len(SHOPS)]\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": \"bk-01\", \"qty\": 1, \"cents\": 3990}\n    producer.produce(args.topic, key=shop, value=json.dumps(sale), on_delivery=report)\n    producer.poll(0)\n    if args.rate:\n        time.sleep(1 / args.rate)\n",
      "note": "O laço. `produce` só põe a mensagem no buffer; `poll(0)` dá ao cliente a chance de rodar os relatórios das mensagens já respondidas, sem esperar."
    },
    {
      "code": "left = producer.flush(30)\nprint(\"delivered per partition:\", dict(sorted(delivered.items())))\nfor reason, n in failed.items():\n    print(f\"failed: {n} x {reason}\")\nif left:\n    print(f\"still waiting after 30 s: {left}\")",
      "note": "O `flush` espera, aqui por até 30 segundos, até toda mensagem ter um relatório, e devolve quantas ainda não têm. Depois o resumo: o que foi entregue, por partição, e o que falhou, e por quê."
    }
  ]
}
```

Crie um tópico `sales` novo e mande as dez vendas do padrão. Se você ainda tem o cluster da lição 3,
rode antes `./cluster.sh stop`, `./cluster.sh new 1` e `./cluster.sh start`, como a lição 3 fez:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
ubuntu@stream:~/work$ python producer.py
delivered per partition: {0: 4, 1: 4, 2: 2}
```

Dez relatórios de entrega, todos sem erro, contados por partição. Com `murmur2_random`, Olinda e João
Pessoa vão para a partição 0, Caruaru e Natal para a 1, o Recife para a 2, como a lição 3 descobriu, e
as dez vendas passam pelas cinco lojas em ciclo: quatro, quatro e duas.

## Lotes, e para que serve o linger.ms

**`linger.ms` é quanto tempo o cliente espera por mais mensagens antes de mandar um lote que não está
cheio.** Com 0 ele manda assim que pode; com 100 segura um lote por até um décimo de segundo, para que
mais mensagens entrem nele. `batch.size` limita um lote a 16 384 bytes. Mande duzentas vendas a
duzentas por segundo, uma vez com cada configuração, para dois tópicos de uma partição:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger0 --partitions 1
Created topic linger0.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger100 --partitions 1
Created topic linger100.
ubuntu@stream:~/work$ python producer.py --topic linger0 --count 200 --rate 200 --linger-ms 0
delivered per partition: {0: 200}
ubuntu@stream:~/work$ python producer.py --topic linger100 --count 200 --rate 200 --linger-ms 100
delivered per partition: {0: 200}
```

Depois conte os lotes no disco com o `kafka-dump-log.sh` da lição 3, que imprime uma linha
`baseOffset` por lote:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/linger0-0/00000000000000000000.log | grep -c baseOffset
197
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/linger100-0/00000000000000000000.log | grep -c baseOffset
11
```

As mesmas duzentas mensagens levaram **197 lotes** sem espera e **11** com 100 ms. Chegava uma
mensagem a cada 5 ms, então sem esperar quase toda mensagem viajou sozinha; com um décimo de segundo de
espera, umas dezoito dividiram cada viagem. Essa é a troca: cada mensagem espera até 100 ms a mais, e o
broker atende dezoito vezes menos requisições, cada uma levando mais. Sob carga pesada os lotes enchem
por tamanho antes de a espera acabar, então a configuração pesa mais em taxas moderadas como esta. O
padrão de 5 ms do programa é também o do librdkafka.

## Quando o broker não está lá

Pare o cluster e mande cinco vendas, desistindo de cada uma depois de cinco segundos em vez dos cinco
minutos do padrão (`message.timeout.ms`, 300 000):

```
ubuntu@stream:~/work$ ./cluster.sh stop
node 1: stopped
ubuntu@stream:~/work$ python producer.py --count 5 --timeout-ms 5000 2>/dev/null
delivered per partition: {}
failed: 5 x Local: Message timed out
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
```

O `produce` aceitou as cinco sem reclamar, porque aceitar no buffer é tudo o que ele faz. Cinco
segundos depois o cliente desistiu de cada uma e **disse isso no relatório de entrega**: `Local:
Message timed out`, em que `Local` quer dizer que o erro foi levantado pelo cliente, não mandado por um
broker. Sem o callback essas cinco vendas teriam sumido, e o programa teria terminado normalmente.
Enquanto espera, o librdkafka também escreve no stderr uma linha para cada tentativa de conexão que
falha; o `2>/dev/null` joga essas linhas fora, e é por isso que o comando o tem.

O timeout é uma decisão. Cinco minutos aguentam um broker reiniciando; cinco segundos transformam uma
queda curta em vendas perdidas. Seja como for, o relatório de entrega é onde o programa fica sabendo,
e o que ele faz então, se grava a venda num arquivo, tenta de novo depois ou para o caixa, é escolha do
programa. A lição 7 volta ao que acontece quando a mensagem chegou e só a resposta se perdeu.
