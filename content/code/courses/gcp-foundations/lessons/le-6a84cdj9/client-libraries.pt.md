---
title: Bibliotecas cliente
version: 1
---

**Uma biblioteca cliente é a API na linguagem do seu programa.** O Google publica uma por linguagem por serviço:
`google-cloud-pubsub` para Python, que a lição 1 instalou no ambiente do laboratório, e as bibliotecas do mesmo
serviço para Go, Java, Node.js e o resto. Por baixo, cada uma faz os pedidos que a seção anterior fez à mão, por
gRPC quando pode, e acrescenta o que um programa precisa e o `curl` não tem: repetições com espera crescente,
agrupamento, paginação, e achar credenciais sozinha.

Salve isto como `~/gcp/publish.py`:

```schooling-example
{"language": "python", "file": "publish.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Publishes a few orders to the topic orders, with the client library.\n\n    python3 publish.py\n\nWhere the messages go is not in this file: the library reads\nPUBSUB_EMULATOR_HOST, and without it, Google.\n\"\"\"\n", "note": "O que ele faz, e o que ele deixa de fora de propósito: nenhum endereço e nenhuma credencial. A biblioteca acha os dois, o assunto da próxima seção."}, {"code": "from google.cloud import pubsub_v1\n\npublisher = pubsub_v1.PublisherClient()\ntopic = publisher.topic_path('planner-dev', 'orders')\n\n", "note": "O cliente publicador, e o nome completo do tópico montado a partir do projeto e do id do tópico: o mesmo `projects/planner-dev/topics/orders` que o endereço REST levava."}, {"code": "futures = []\nfor n in (1001, 1002, 1003):\n    data = f'order {n}'.encode()\n    futures.append(publisher.publish(topic, data, source='web'))\n\n", "note": "Três mensagens, cada uma um corpo de bytes e um atributo. O `publish` não espera: ele devolve um future na hora e a biblioteca agrupa e manda em segundo plano, e é isso que faz um publicador ser rápido."}, {"code": "for future in futures:\n    print('published', future.result())\n", "note": "Esperar cada future. O resultado dele é o id de mensagem que o servidor atribuiu, e uma falha ao publicar aparece aqui, como exceção, em vez de se perder."}]}
```

Rode-o, e depois leia as mensagens de volta **sem a biblioteca**, pela API REST, decodificando cada corpo do
base64 em que a API o leva:

```
ana@laptop:~/gcp$ python3 publish.py
published 1
published 2
published 3
ana@laptop:~/gcp$ curl -s -X POST http://localhost:8085/v1/projects/planner-dev/subscriptions/orders-sub:pull -H 'Content-Type: application/json' -d '{"maxMessages": 10}' | jq -c '.receivedMessages[].message | {id: .messageId, data: (.data | @base64d), attributes}'
{"id":"1","data":"order 1001","attributes":{"source":"web"}}
{"id":"2","data":"order 1002","attributes":{"source":"web"}}
{"id":"3","data":"order 1003","attributes":{"source":"web"}}
```

As três mensagens que a biblioteca publicou, lidas pelo `curl` na assinatura que a seção anterior fez à mão, com o
atributo delas. **A biblioteca e a API REST são o mesmo serviço**: nenhum lado sabe nem se importa com qual o outro
usou.

Os ids das mensagens são 1, 2 e 3 porque este é o emulador, que conta. Os do Google são números longos, únicos no
serviço, e um programa deve tratá-los como texto opaco de qualquer jeito.

## O que a biblioteca acrescenta

| | `curl` | a biblioteca cliente |
|---|---|---|
| repetições | nenhuma; um `503` é problema de quem chama | repetidas com espera, para os erros que valem repetir |
| agrupamento | um pedido por chamada | muitas mensagens por pedido, mandadas em segundo plano |
| paginação | quem chama segue o `nextPageToken` | um laço sobre os resultados que busca páginas conforme anda |
| credenciais | um cabeçalho que quem chama escreve | achadas pela biblioteca, a próxima seção |
| o protocolo | REST e JSON | gRPC onde houver, REST no resto |

Essa tabela é o argumento a favor da biblioteca num programa, e o argumento a favor do `curl` num shell: quando a
pergunta é *o que exatamente a API diz*, nada fica no meio.
