---
title: Um primeiro stream, e um leitor que não para
version: 1
---

A Ponto Final é uma rede de cinco livrarias no Nordeste, e o exemplo que atravessa este curso. Até
agora as vendas dela chegavam ao warehouse uma vez por noite, num arquivo por loja. O que o stream
muda é que **cada venda vira uma mensagem no instante em que o caixa a registra**, e quem quiser
saber das vendas as lê enquanto acontecem.

Um **tópico** é um stream de mensagens com nome no Kafka, aquilo em que os produtores escrevem e de
onde os consumidores leem. Crie um chamado `sales`, com três **partições** (a lição 3 diz o que são;
por ora, o tópico é guardado em três pedaços):

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
```

`--bootstrap-server` é o endereço que uma ferramenta do Kafka contata primeiro, para descobrir o
resto do cluster. Todo comando do Kafka recebe um, e neste laboratório é `localhost:9092`.

## Um leitor que espera

O Kafka vem com um consumidor que imprime tudo o que chega. Inicie-o no seu **segundo shell**, e
deixe lá:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --formatter-property print.key=true
```

Ele imprime uma linha sobre o KIP-848, um protocolo mais novo de coordenação de consumidores a que a
lição 4 volta, e depois nada, e não volta ao prompt. **Essa é a primeira coisa diferente num
stream.** Uma consulta lê o que existe e termina; isto lê o que existe e depois espera pelo que
ainda não existe, por quanto tempo você deixar.

## Algo para ler

Ninguém vai passar livros no caixa para você, então o curso traz um caixa. Este programa inventa
vendas para as cinco lojas, com um relógio próprio que começa às nove horas de 2 de março de 2026, e
manda cada uma para o Kafka. Salve-o como `~/work/tills.py`:

```schooling-example
{
  "language": "python",
  "file": "tills.py",
  "parts": [
    {
      "code": "\"\"\"tills.py: the sales of Ponto Final's shops, as events, into Kafka.\n\n    python tills.py [--count N] [--rate R] [--topic T] [--seed S]\n\nEach event is one sale at one till. The shops, the books and the clock are\nmade up and fixed by the seed, so two runs with the same seed send the same\nsales. --rate is sales per second; 0 sends them as fast as Kafka takes them.\n\"\"\"\nimport argparse\nimport json\nimport random\nimport time\nfrom datetime import datetime, timedelta, timezone\n\nfrom confluent_kafka import Producer\n",
      "note": "O que ele faz e como chamar. Toda execução com o mesmo `--seed` manda as mesmas vendas, e é isso que permite a uma lição citar os números que você vai ver."
    },
    {
      "code": "SHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\nBOOKS = {\"bk-01\": 3990, \"bk-02\": 5490, \"bk-03\": 2990, \"bk-04\": 7900,\n         \"bk-05\": 4490, \"bk-06\": 6200, \"bk-07\": 3500, \"bk-08\": 8990}\nOPEN = datetime(2026, 3, 2, 9, 0, tzinfo=timezone(timedelta(hours=-3)))\n",
      "note": "Cinco lojas e oito livros, cada um com preço **em centavos**, porque dinheiro nunca é float."
    },
    {
      "code": "args = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=20)\nargs.add_argument(\"--rate\", type=float, default=5)\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--seed\", type=int, default=1)\nargs = args.parse_args()\n",
      "note": "Os argumentos, com padrões que servem às lições."
    },
    {
      "code": "rng = random.Random(args.seed)\nproducer = Producer({\"bootstrap.servers\": \"localhost:9092\"})\nclock = OPEN",
      "note": "**Um produtor é o cliente que escreve.** Ele precisa de um endereço para começar, e descobre o resto do cluster a partir desse nó."
    },
    {
      "code": "for n in range(1, args.count + 1):\n    clock += timedelta(seconds=rng.randint(1, 20))\n    shop, book = rng.choice(SHOPS), rng.choice(list(BOOKS))\n    qty = rng.choice([1, 1, 1, 2, 3])\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": book,\n            \"qty\": qty, \"cents\": BOOKS[book] * qty, \"at\": clock.isoformat()}",
      "note": "Uma venda por volta do laço. O relógio avança até vinte segundos de tempo da loja, seja qual for o tempo real, e **o instante da venda viaja dentro do evento**, como `at`."
    },
    {
      "code": "    producer.produce(args.topic, key=shop, value=json.dumps(sale))\n    producer.poll(0)\n    if args.rate:\n        time.sleep(1 / args.rate)",
      "note": "`produce` entrega a mensagem ao cliente, que a envia em segundo plano. **A loja é a chave da mensagem**, que a lição 3 mostra decidir onde ela é guardada. `poll(0)` deixa o cliente relatar o que já enviou."
    },
    {
      "code": "producer.flush()\nprint(f\"sent {args.count} sales to {args.topic}, the last one at {clock:%H:%M:%S}\")",
      "note": "`flush` espera até o broker confirmar cada mensagem. Sem ele o programa poderia terminar com vendas ainda na memória, e elas se perderiam."
    }
  ]
}
```

Agora, no **primeiro shell**, mande cinco vendas a duas por segundo:

```
ubuntu@stream:~/work$ python tills.py --count 5 --rate 2
sent 5 sales to sales, the last one at 09:00:24
```

Leva dois segundos e meio. No segundo shell, as vendas chegaram enquanto eram enviadas, uma linha
por vez, e o consumidor continua esperando a sexta. Pare-o com Ctrl+C, e ele diz quantas viu:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
joao-pessoa	{"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
natal	{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
olinda	{"sale": "oli-000003", "shop": "olinda", "book": "bk-02", "qty": 2, "cents": 10980, "at": "2026-03-02T09:00:22-03:00"}
natal	{"sale": "nat-000004", "shop": "natal", "book": "bk-07", "qty": 3, "cents": 10500, "at": "2026-03-02T09:00:23-03:00"}
natal	{"sale": "nat-000005", "shop": "natal", "book": "bk-05", "qty": 1, "cents": 4490, "at": "2026-03-02T09:00:24-03:00"}
Processed a total of 5 messages
```

Cada linha é a chave, um tab e a mensagem: a loja, depois a venda. Elas saíram na ordem em que
entraram, o que, com três partições, é algo que o Kafka promete menos vezes do que parece; a lição 3
diz exatamente quando vale.

## Lendo de novo

Rode o mesmo consumidor de novo e ele não imprime nada: começou no fim, onde as mensagens novas vão
chegar, então as cinco antigas ficaram para trás. Acrescente `--from-beginning`:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --from-beginning --max-messages 5
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
{"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
{"sale": "oli-000003", "shop": "olinda", "book": "bk-02", "qty": 2, "cents": 10980, "at": "2026-03-02T09:00:22-03:00"}
{"sale": "nat-000004", "shop": "natal", "book": "bk-07", "qty": 3, "cents": 10500, "at": "2026-03-02T09:00:23-03:00"}
{"sale": "nat-000005", "shop": "natal", "book": "bk-05", "qty": 1, "cents": 4490, "at": "2026-03-02T09:00:24-03:00"}
Processed a total of 5 messages
```

**As cinco vendas continuam lá.** Ler não as removeu, e um segundo leitor, ou o mesmo uma hora
depois, recebe todas de novo. Essa é a segunda coisa diferente, e é nela que a lição 2 se apoia: o
Kafka não é uma fila que entrega cada mensagem a um só interessado e a esquece, mas um log que
guarda o que foi escrito pelo tempo que mandarem.
