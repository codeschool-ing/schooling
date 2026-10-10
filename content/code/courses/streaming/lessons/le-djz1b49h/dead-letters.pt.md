---
title: Dead letters, e mensagens que ninguém conseguiu tratar
version: 1
---

**Uma mensagem que não pode ser tratada precisa ir para outro lugar que não o começo da fila.** Um
embalador que rejeita um pedido com endereço ilegível e pede que ele volte à fila recebe o mesmo
pedido na hora, rejeita de novo, e passa o resto do dia nisso, enquanto os pedidos atrás esperam.
O conserto errado de costume é confirmar a mensagem ruim e registrá-la num log, o que apaga a única
cópia. A resposta do RabbitMQ é uma **exchange de dead-letter**: uma fila pode nomear uma exchange
para a qual ela republica toda mensagem de que desiste, e uma fila ligada lá as recolhe para uma
pessoa ou um programa examinar.

Uma fila desiste de uma mensagem por três motivos, e a mensagem carrega qual foi num cabeçalho
chamado `x-death`:

| motivo | o que aconteceu |
|---|---|
| `rejected` | um consumidor a rejeitou com `requeue=False` |
| `expired` | ela ficou na fila mais tempo que o seu tempo de vida, o **TTL** |
| `maxlen` | a fila estava cheia, no tamanho que lhe deram, e esta era a mais antiga |

Este programa monta uma fila de etiquetas de envio com uma exchange de dead-letter e um TTL de dois
segundos, põe três pedidos nela, rejeita um, trata um e deixa o terceiro em paz. Salve-o como
`~/work/rabbit_dead.py`:

```schooling-example
{
  "language": "python",
  "file": "rabbit_dead.py",
  "parts": [
    {
      "code": "\"\"\"rabbit_dead.py: a queue whose rejected and expired messages go to a dead-letter queue.\"\"\"\nimport time\n\nimport pika\n\nconn = pika.BlockingConnection(pika.ConnectionParameters(\"localhost\"))\nch = conn.channel()\nch.exchange_declare(exchange=\"pf.dead\", exchange_type=\"fanout\")\nch.queue_declare(queue=\"labels.dead\")\nch.queue_bind(queue=\"labels.dead\", exchange=\"pf.dead\")",
      "note": "O lado do dead-letter: uma exchange fanout e uma fila ligada a ela, onde vai parar tudo de que se desistiu."
    },
    {
      "code": "ch.queue_declare(queue=\"labels\", arguments={\n    \"x-dead-letter-exchange\": \"pf.dead\",\n    \"x-message-ttl\": 2000,\n})\n\nfor order in [\"web-0001\", \"web-0002\", \"web-0003\"]:\n    ch.basic_publish(exchange=\"\", routing_key=\"labels\", body=order)",
      "note": "**Os argumentos da fila são onde os dois comportamentos são definidos**: para onde vão os dead letters dela, e quanto tempo, em milissegundos, uma mensagem pode esperar. Eles ficam fixos quando a fila é criada; declará-la de novo com outros argumentos é recusado."
    },
    {
      "code": "method, _, body = ch.basic_get(queue=\"labels\")\nprint(f\"took {body.decode()}, the address is unreadable: reject it\")\nch.basic_reject(delivery_tag=method.delivery_tag, requeue=False)\nmethod, _, body = ch.basic_get(queue=\"labels\")\nprint(f\"took {body.decode()}, printed the label: ack it\")\nch.basic_ack(delivery_tag=method.delivery_tag)",
      "note": "Um pedido rejeitado sem voltar à fila, um confirmado. **`requeue=False` é a diferença entre um dead letter e um laço sem fim.**"
    },
    {
      "code": "print(\"nobody takes web-0003; waiting 3 seconds\")\ntime.sleep(3)\nwhile (m := ch.basic_get(queue=\"labels.dead\", auto_ack=True))[0]:\n    death = m[1].headers[\"x-death\"][0]\n    print(f\"dead letter {m[2].decode()}: reason {death['reason']}, from queue {death['queue']}\")\nconn.close()",
      "note": "Espera passar o TTL, depois lê a fila de dead-letter e o motivo que cada mensagem carrega."
    }
  ]
}
```

@@fence@@

Dois dead letters por dois motivos diferentes, e o que foi tratado não está entre eles. O pedido
rejeitado manteve o corpo, então alguém pode corrigir o endereço e publicá-lo de novo; o expirado
diz que expirou, então ninguém perde tempo procurando um bug no embalador.

## TTL é uma decisão, não uma limpeza

Um TTL diz **depois de tanto tempo, a mensagem não vale mais a pena**. Isso é verdade para algum
trabalho — um aviso de mudança de preço superado pelo seguinte, um lembrete de um evento que já
passou — e falso para a maioria: um pedido que esperou demais ainda precisa ser embalado. Sem
exchange de dead-letter, uma mensagem expirada é simplesmente apagada, o que é um jeito silencioso
de perder pedidos no dia mais movimentado do ano, justamente quando a fila está mais longa. Com
uma, a expiração vira uma lista que alguém pode percorrer.

**Nada tenta de novo sozinho.** Um dead letter fica na fila dele até alguma coisa lê-lo. A lição 16
faz o mesmo para o Kafka com um *tópico* de dead-letter, escrito pelo consumidor e não pelo broker,
porque um log não tem rejeição por mensagem onde pendurar isso. Os dois chegam à mesma regra de
operação: uma fila de dead-letter que ninguém observa é um jeito mais lento de apagar mensagens,
então o tamanho dela pertence à mesma tela que o da fila principal.
