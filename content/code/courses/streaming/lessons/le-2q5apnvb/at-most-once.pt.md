---
title: No máximo uma vez: confirmar antes, e perder o que a queda interrompeu
version: 1
---

**No máximo uma vez quer dizer que uma mensagem é processada uma vez ou nenhuma, e nunca duas.** O
consumidor confirma os offsets do que leu antes de processar, então uma queda deixa o Kafka
acreditando que as mensagens interrompidas foram tratadas. No reinício elas são puladas. Nada é
feito duas vezes, e o preço é que algo pode nunca ser feito.

É a escolha certa mais vezes do que o nome sugere: um painel de vendas por minuto que perde cinco
vendas numa queda fica errado por cinco vendas durante um minuto, e um painel que as conta duas
vezes fica errado do mesmo jeito. Onde uma duplicata custa mais que um buraco, como numa métrica
que dispara um alerta, numa amostra ou num log de cliques, no máximo uma vez sai mais barato e
basta.

## Um consumidor que dá para derrubar

Este consumidor faz o processamento mais simples que existe: acrescenta o id de cada venda num
arquivo, uma por linha, para depois dar para contar o que foi processado. Ele lê em lotes de dez e
confirma na mão, antes ou depois do lote conforme o modo, e `--crash-after N` o faz terminar de
repente no meio de um lote. Salve como `~/work/crash_consumer.py`:

```schooling-example
{
  "language": "python",
  "file": "crash_consumer.py",
  "parts": [
    {
      "code": "\"\"\"crash_consumer.py: write each sale's id to a file, commit offsets, and maybe crash.\n\n    python crash_consumer.py most|least [--crash-after N]\n\nmost   commit a batch's offsets, then process it   (at most once)\nleast  process a batch, then commit its offsets    (at least once)\n\"\"\"\nimport argparse\nimport json\nimport os\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"mode\", choices=[\"most\", \"least\"])\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "Dois modos, um para cada ordem dos dois passos."
    },
    {
      "code": "consumer = Consumer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"group.id\": f\"crash-{args.mode}\",\n                     \"auto.offset.reset\": \"earliest\",\n                     \"enable.auto.commit\": False,\n                     \"session.timeout.ms\": 6000})\nconsumer.subscribe([\"sales\"])\n",
      "note": "**`enable.auto.commit` está desligado**, então nada é confirmado a não ser que o programa mande. Cada modo tem o próprio grupo, e portanto os próprios offsets confirmados. Um membro que cai continua no grupo até a sessão dele expirar, e **6 segundos é a menor sessão que o broker aceita**, então um reinício espera isso e não mais."
    },
    {
      "code": "done = 0\nwith open(f\"processed-{args.mode}.txt\", \"a\") as out:\n    while batch := consumer.consume(num_messages=10, timeout=15):\n        if args.mode == \"most\":\n            consumer.commit(asynchronous=False)",
      "note": "`consume` devolve até dez mensagens, ou uma lista vazia depois de quinze segundos sem nada novo, o que encerra o laço. **No modo `most` o commit vem primeiro**: `commit()` sem argumentos confirma a posição depois do lote que acabou de ser lido."
    },
    {
      "code": "        for msg in batch:\n            out.write(json.loads(msg.value())[\"sale\"] + \"\\n\")\n            out.flush()\n            done += 1\n            if done == args.crash_after:\n                print(f\"crashed after {done} sales\", flush=True)\n                os._exit(1)",
      "note": "Processar é uma linha num arquivo, gravada na hora para que uma queda não a deixe num buffer. **`os._exit` encerra o processo na hora**: sem `finally`, sem fechar o consumidor, sem último commit, do jeito que uma queda de energia ou um `kill -9` encerram."
    },
    {
      "code": "        if args.mode == \"least\":\n            consumer.commit(asynchronous=False)\nconsumer.close()\nprint(f\"processed {done} sales; nothing more to read\")",
      "note": "No modo `least` o commit vem depois de o lote inteiro ser processado."
    }
  ]
}
```

O tópico desta lição tem **uma partição**, para os lotes e os offsets ficarem fáceis de acompanhar.
Crie-o e ponha cinquenta vendas nele:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 1
Created topic sales.
ubuntu@stream:~/work$ python tills.py --count 50 --rate 0
sent 50 sales to sales, the last one at 09:08:39
```

Se `sales` ainda existir de uma lição anterior, comece de um cluster novo antes, com `./cluster.sh
stop`, `./cluster.sh new 1` e `./cluster.sh start`.

## Derrubando

Rode no modo `most` com queda depois de 25 vendas, depois de novo sem queda, e conte:

```
ubuntu@stream:~/work$ python crash_consumer.py most --crash-after 25
crashed after 25 sales
ubuntu@stream:~/work$ python crash_consumer.py most
processed 20 sales; nothing more to read
ubuntu@stream:~/work$ wc -l < processed-most.txt
45
ubuntu@stream:~/work$ sort processed-most.txt | uniq | wc -l
45
```

A primeira execução leu dois lotes de dez, confirmando cada um antes de escrevê-lo, depois leu o
terceiro lote, vendas 21 a 30, confirmou-o e caiu depois de escrever cinco delas. A segunda
execução começou do offset confirmado, 30, e processou as últimas 20. **O arquivo tem 45 vendas,
todas diferentes, de 50.** As vendas 26 a 30 nunca foram processadas, e nada na saída diz isso: o
arquivo simplesmente tem cinco linhas a menos, e só uma contagem contra o tópico revela.

Esse é todo o caráter do no máximo uma vez. Nenhuma duplicata, nunca, e uma perda do tamanho do que
estava em andamento quando veio a queda, que aqui foi meio lote.
