---
title: O RabbitMQ em três peças, e um worker que morre
version: 1
---

**No RabbitMQ um produtor nunca escreve numa fila.** Ele publica numa **exchange**, a exchange
decide quais filas recebem uma cópia, e os consumidores leem das filas. Um **binding** é a regra
que liga uma fila a uma exchange. Essa indireção é o que a próxima seção usa para rotear; para uma
fila de trabalho simples, o RabbitMQ tem uma **exchange padrão**, de nome vazio, que entrega a
mensagem à fila cujo nome é igual à routing key dela. Então publicar em `""` com a chave `packing`
põe a mensagem na fila `packing`, e a exchange fica fora de vista.

O lado do site põe os pedidos na fila. Salve isto como `~/work/rabbit_send.py`:

@@fence@@

O `queue_declare` cria a fila se ela não existe e não faz nada se existe, então os dois lados o
chamam e qualquer um pode subir primeiro. **`durable=True` faz a fila sobreviver a um reinício do
servidor, e o modo de entrega persistente faz o mesmo por cada mensagem**; o RabbitMQ precisa dos
dois, e uma fila durável cheia de mensagens não persistentes volta vazia.

O lado do embalador, como `~/work/rabbit_work.py`:

```schooling-example
{
  "language": "python",
  "file": "rabbit_work.py",
  "parts": [
    {
      "code": "\"\"\"rabbit_work.py: a packer. Takes orders off the queue one at a time.\n\n    python rabbit_work.py NAME [--seconds S] [--crash-after N]\n\"\"\"\nimport argparse\nimport json\nimport os\nimport time\n\nimport pika\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"name\")\nargs.add_argument(\"--seconds\", type=float, default=1)\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()",
      "note": "Um embalador, com um nome para distinguir a saída dele, um tempo por pedido e um jeito de cair de propósito."
    },
    {
      "code": "conn = pika.BlockingConnection(pika.ConnectionParameters(\"localhost\"))\nch = conn.channel()\nch.queue_declare(queue=\"packing\", durable=True)\nch.basic_qos(prefetch_count=1)\ndone = 0",
      "note": "**`prefetch_count=1` faz o servidor mandar a este consumidor uma mensagem não confirmada por vez.** Sem isso, o RabbitMQ empurra quantas conseguir, e um embalador lento segura pedidos que um livre poderia estar embalando."
    },
    {
      "code": "def pack(ch, method, properties, body):\n    global done\n    order = json.loads(body)\n    again = \" (redelivered)\" if method.redelivered else \"\"\n    print(f\"{args.name}: packing {order['order']}{again}\", flush=True)\n    time.sleep(args.seconds)",
      "note": "O trabalho. `method.redelivered` é o servidor dizendo que já entregou esta mensagem antes."
    },
    {
      "code": "    if args.crash_after and done == args.crash_after:\n        print(f\"{args.name}: crashed before acknowledging {order['order']}\", flush=True)\n        os._exit(1)",
      "note": "Com `--crash-after N`, o embalador termina N pedidos e morre no meio do seguinte, **depois do trabalho e antes da confirmação**, o pior momento possível. `os._exit` encerra o processo na hora, como um kill faria."
    },
    {
      "code": "    ch.basic_ack(delivery_tag=method.delivery_tag)\n    done += 1",
      "note": "**`basic_ack` é o momento em que a mensagem é apagada.** Até ele chegar, o servidor guarda o pedido, marcado como não confirmado, só para este consumidor."
    },
    {
      "code": "ch.basic_consume(queue=\"packing\", on_message_callback=pack)\ntry:\n    ch.start_consuming()\nexcept KeyboardInterrupt:\n    print(f\"{args.name}: stopped after {done} orders\")\n    conn.close()",
      "note": "Registra o callback e espera mensagens, para sempre. Ctrl+C fecha a conexão com educação, o que devolve tudo o que ainda não foi confirmado."
    }
  ]
}
```

## Dois embaladores, e um que morre

Ponha seis pedidos na fila e pergunte ao servidor o que ele guarda. `messages_ready` esperam um
consumidor, `messages_unacknowledged` foram entregues e ainda não confirmadas:

@@fence@@

Agora dois embaladores. No **segundo shell**, a Ana, que embala tudo o que recebe:

@@fence@@

E num **terceiro shell** — abra mais um, do jeito que abriu o segundo — a Bia, que vai cair durante o
segundo pedido dela:

@@fence@@

Depois de alguns segundos o shell da Bia volta ao prompt:

@@fence@@

A Ana continua esperando mais. No primeiro shell, pergunte ao servidor de novo:

@@fence@@

A fila está vazia, e um consumidor, a Ana, continua conectado. Pare-a com Ctrl+C, e o shell dela
mostra o que ela fez:

@@fence@@

Siga o `web-0004`. O servidor o deu à Bia; a Bia o embalou e morreu antes de avisar. **A conexão
fechar bastou para o servidor saber**: uma mensagem não confirmada cujo consumidor sumiu volta para
a fila, e a Ana a recebeu, marcada como `redelivered`. Nada se perdeu. E o `web-0004` foi embalado
duas vezes — uma pela Bia, cujo trabalho não foi a lugar nenhum, outra pela Ana. Isso é entrega
pelo menos uma vez, a garantia da lição 7, num outro broker; a marca `redelivered` é um aviso de
que o trabalho talvez já tenha acontecido, e tornar a própria embalagem idempotente é a resposta da
lição 8, não do broker.

**As seis mensagens sumiram do servidor.** Não há offset para voltar nem `--from-beginning` para
acrescentar: os pedidos agora só existem no que os embaladores fizeram com eles.
