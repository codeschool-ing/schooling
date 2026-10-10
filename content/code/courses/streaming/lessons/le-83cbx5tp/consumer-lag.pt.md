---
title: Lag do consumidor, o primeiro número a vigiar
version: 1
---

**Um consumidor mais lento que o produtor não falha. Ele fica para trás, em silêncio, e continua
ficando.** Nada no programa acusa erro: toda venda que ele trata é tratada corretamente, só que cada
vez mais tarde. O estoque no site da Ponto Final está certo para dez minutos atrás, depois vinte,
depois uma hora, e a primeira pessoa a perceber é um cliente. A distância entre o que foi escrito e o
que foi lido se chama **lag do consumidor** (consumer lag), e é o número que todo mundo que opera um
stream aprende a vigiar primeiro.

## Um consumidor sem pressa

Para ver lag você precisa de um consumidor mais lento que os caixas. Este finge que atualizar o
estoque de cada venda leva um décimo de segundo, e a cada cinquenta vendas diz até onde chegou. Salve
como `~/work/slow_consumer.py`:

```schooling-example
{
  "language": "python",
  "file": "slow_consumer.py",
  "parts": [
    {
      "code": "\"\"\"slow_consumer.py: a consumer that takes its time over every sale.\n\n    python slow_consumer.py [--group G] [--delay S] [--max-poll MS]\n\nFor each sale it pretends to update the stock by sleeping --delay seconds.\n--max-poll is how long, in milliseconds, it may go between two polls before\nthe group gives up on it.\n\"\"\"\nimport argparse\nimport json\nimport time\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--group\", default=\"stock\")\nargs.add_argument(\"--delay\", type=float, default=0.1)\nargs.add_argument(\"--max-poll\", type=int, default=300000)\nargs = args.parse_args()\n",
      "note": "Para que ele serve, e os três ajustes. `--max-poll` espera pela seção de backpressure; deixe-o quieto por enquanto."
    },
    {
      "code": "consumer = Consumer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"auto.commit.interval.ms\": 1000,\n    \"max.poll.interval.ms\": args.max_poll,\n    \"session.timeout.ms\": min(args.max_poll, 45000),\n    \"partition.assignment.strategy\": \"roundrobin\",\n})\n",
      "note": "**A posição confirmada do grupo é o que as ferramentas de lag leem**, então ela é confirmada a cada segundo em vez de a cada cinco, o padrão, para manter os números perto da verdade. `roundrobin` distribui as partições uma a uma quando um grupo tem vários membros; a seção de backpressure precisa disso."
    },
    {
      "code": "def now():\n    return time.strftime(\"%H:%M:%S\")\n\ndef assigned(consumer, parts):\n    print(now(), \"assigned\", [p.partition for p in parts], flush=True)\n\ndef revoked(consumer, parts):\n    print(now(), \"revoked\", [p.partition for p in parts], flush=True)\n\nconsumer.subscribe([\"sales\"], on_assign=assigned, on_revoke=revoked)\n",
      "note": "Dois callbacks que imprimem quando o grupo entrega as partições a este consumidor e quando as tira. A lição 4 os apresentou; aqui eles são a prova de um rebalanceamento."
    },
    {
      "code": "done = 0\ntry:\n    while True:\n        msg = consumer.poll(1.0)\n        if msg is None:\n            continue\n        if msg.error():\n            print(now(), \"error:\", msg.error().str(), flush=True)\n            continue\n        sale = json.loads(msg.value())\n        time.sleep(args.delay)\n        done += 1\n        if done % 50 == 0 or args.delay >= 1:\n            print(now(), f\"{done} done, last {sale['sale']}\",\n                  f\"from partition {msg.partition()} offset {msg.offset()}\", flush=True)\nexcept KeyboardInterrupt:\n    pass\nfinally:\n    consumer.close()",
      "note": "O laço. **O `sleep` é a parte lenta**: uma escrita num banco, uma chamada a outro serviço, o que quer que o seu consumidor de verdade faça com uma venda."
    }
  ]
}
```

Comece de um tópico vazio, o mesmo `sales` com três partições da lição 1. Se o seu já tem vendas,
`./cluster.sh stop`, `new 1` e `start` dão um limpo.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

No segundo shell, inicie o consumidor. Ele entra no grupo `stock` e espera:

```
ubuntu@stream:~/work$ python slow_consumer.py --delay 0.1
```

Esta seção precisa de um **terceiro shell**, aberto do mesmo jeito que o segundo, com `multipass
shell stream`. Nele, faça os caixas registrarem 600 vendas a vinte por segundo, o dobro do que o
consumidor dá conta. Leva meio minuto, e o primeiro shell fica livre para observar:

```
ubuntu@stream:~/work$ python tills.py --count 600 --rate 20
```

## Lendo o lag

`kafka-consumer-groups.sh --describe` pergunta ao cluster onde um grupo está. Dez segundos depois
do início:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

Uma linha por partição, e três números em cada uma que são o assunto inteiro desta seção:

| coluna | o que é |
|---|---|
| `LOG-END-OFFSET` | o offset que a próxima mensagem escrita na partição vai receber: quanto já foi escrito |
| `CURRENT-OFFSET` | a posição confirmada do grupo: a próxima mensagem que ele vai ler |
| `LAG` | a diferença: mensagens escritas e ainda não tratadas |

A partição 2 mostra `-`: nenhuma das chaves das cinco lojas cai nela (a lição 3 explica por que
chaves e partições se combinam do jeito que se combinam), então o grupo não tem nada para confirmar
ali. Dez segundos depois:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

**O lag cresceu, e cresce pela diferença entre as duas taxas**: vinte por segundo entrando, dez por
segundo saindo, então mais ou menos dez a mais a cada segundo. No terceiro shell os caixas terminam
no horário, trinta segundos depois de começar, faça o consumidor o que fizer:

```
ubuntu@stream:~/work$ python tills.py --count 600 --rate 20
```

A partir daí o lag para de crescer e começa a encolher na velocidade total do consumidor:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma partição desenhada como uma fileira de mensagens numeradas. O produtor acrescenta à direita; o log-end offset é a próxima posição livre. O offset confirmado do grupo de consumidores fica mais à esquerda, na primeira mensagem ainda não tratada. As mensagens entre os dois são o lag.\" data-fig=\"l16-lag\"><defs><marker id=\"l16-lag-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l16-lag-ah-2105\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"57.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"78\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"116\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"133.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"154\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"192\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"209.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"230\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"247.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"268\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"306\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"344\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"361.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"382\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"399.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"420\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"437.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"458\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11</text><rect x=\"496\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"513.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12</text><rect x=\"534\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"551.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13</text><rect x=\"572\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"589.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14</text><rect x=\"610\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"627.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">15</text><path d=\"M 40 78 L 40 72 L 302 72 L 302 78\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"171.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tratadas</text><path d=\"M 306 78 L 306 72 L 606 72 L 606 78\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"456.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">esperando: o lag</text><line x1=\"323.0\" y1=\"154\" x2=\"323.0\" y2=\"128\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l16-lag-ah-726)\"></line><text x=\"323.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CURRENT-OFFSET</text><text x=\"323.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próxima a ler</text><line x1=\"627.0\" y1=\"154\" x2=\"627.0\" y2=\"128\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#l16-lag-ah-2105)\"></line><text x=\"607.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">LOG-END-OFFSET</text><text x=\"607.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próxima a escrever</text><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">lag = 15 − 7 = 8</text><path d=\"M 668 107.0 L 648 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-lag-ah-2105)\"></path><text x=\"656\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o produtor acrescenta</text></svg>", "caption": "O lag é contado entre duas posições na mesma partição: onde o grupo vai ler em seguida e onde o produtor vai escrever em seguida."}
```

Meio minuto depois, o consumidor alcançou o fim e o lag é zero em toda partição que tem dados:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

Duas coisas nesses números merecem desconfiança. **O lag é medido a partir do último commit, não da
mensagem sendo tratada**, então aqui ele está até um segundo desatualizado, e até cinco com o
intervalo padrão; um consumidor que nunca confirma mostra um lag que nunca se move, mesmo enquanto
trabalha. E lag zero diz que o grupo leu tudo, não que tratou tudo corretamente. Deixe o consumidor
rodando: a seção sobre replay precisa dele.
