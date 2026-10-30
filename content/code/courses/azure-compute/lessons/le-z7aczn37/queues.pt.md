---
title: "Filas do Service Bus: travar, liquidar, dead-letter"
version: 1
---

A imagem que quase todo mundo traz de uma fila é a de um cano: a mensagem entra por uma ponta, um
consumidor a tira pela outra, e ela some. **Receber uma mensagem de uma fila do Service Bus não a
remove.** No modo padrão, peek-lock, a fila entrega a mensagem e a trava por um tempo, a lock
duration, para que nenhum outro consumidor fique com ela. Depois o consumidor a *liquida*:
*complete* a remove, *abandon* a devolve na hora, *dead-letter* a põe de lado de vez. Um consumidor
que não faz nenhuma das três, porque caiu, deixa a trava expirar, e a mensagem volta. Cada volta conta, e passado um limite a fila desiste. Esta seção roda os quatro
desfechos na fila de pedidos da loja.

O outro modo, receive-and-delete, remove a mensagem no instante em que ela é enviada ao consumidor.
Um consumidor que morre no meio do caminho perde a mensagem, o que a documentação da Microsoft chama
de processamento at-most-once; serve para dados que não valem nada um minuto depois, e não para um
pedido que alguém pagou.

## O emulador, e do que ele é feito

Nenhum namespace do Service Bus existe num laptop, mas o plano de dados dele existe. A Microsoft
publica um emulador como imagem Docker que fala AMQP, o protocolo que as bibliotecas cliente usam, e
aceita a mesma forma de connection string de um namespace no Azure. Ele guarda as mensagens num SQL
Server, que roda ao lado como um segundo contêiner. **As filas e os tópicos dele são declarados num
arquivo lido na partida**, `Config.json`, e nada mais os cria: uma mudança no arquivo pede um
reinício, e um reinício esquece todas as mensagens. A documentação da Microsoft lista o que fica de
fora, entre outras coisas entidades particionadas, login pelo Entra ID e autoscale, e limita o
emulador a um namespace e 50 filas ou tópicos; ele pede 2 GB de memória.

Crie um diretório para ele, `~/azure/servicebus`, e salve a declaração como
`~/azure/servicebus/Config.json`. Ela declara tudo o que esta lição usa, e a próxima seção usa o
resto:

```json
{
  "UserConfig": {
    "Namespaces": [
      {
        "Name": "sbemulatorns",
        "Queues": [
          {
            "Name": "orders",
            "Properties": {
              "LockDuration": "PT5S",
              "MaxDeliveryCount": 3
            }
          },
          {
            "Name": "order-steps",
            "Properties": {
              "RequiresSession": true
            }
          },
          {
            "Name": "payments",
            "Properties": {
              "RequiresDuplicateDetection": true,
              "DuplicateDetectionHistoryTimeWindow": "PT1M"
            }
          }
        ],
        "Topics": [
          {
            "Name": "order-paid",
            "Subscriptions": [
              {
                "Name": "billing"
              },
              {
                "Name": "shipping",
                "Rules": [
                  {
                    "Name": "physical-only",
                    "Properties": {
                      "FilterType": "Sql",
                      "SqlFilter": {
                        "SqlExpression": "kind = 'physical'"
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ],
    "Logging": {
      "Type": "Console"
    }
  }
}
```

O nome do namespace, `sbemulatorns`, é do próprio emulador e não pode ser trocado. A fila `orders`
traz duas configurações que importam agora. **`LockDuration` é quanto tempo uma mensagem recebida
fica travada**, escrito como duração ISO 8601: `PT5S` são cinco segundos, escolhidos para o
laboratório andar depressa; o padrão é um minuto e o máximo, cinco. **`MaxDeliveryCount` é quantas
entregas uma mensagem recebe** antes de a fila desistir dela; o padrão é 10, e 3 basta para
observar.

Os dois contêineres sobem com o Docker Compose, que o curso `docker` usou. Salve isto como
`~/azure/servicebus/compose.yaml`:

```yaml
# servicebus/compose.yaml
name: servicebus
services:
  emulator:
    container_name: servicebus-emulator
    image: mcr.microsoft.com/azure-messaging/servicebus-emulator:2.0.1
    volumes:
      - ./Config.json:/ServiceBus_Emulator/ConfigFiles/Config.json
    ports:
      - "5672:5672"
      - "5300:5300"
    environment:
      SQL_SERVER: mssql
      MSSQL_SA_PASSWORD: "Shop-lab-2026"
      ACCEPT_EULA: "Y"
    depends_on:
      - mssql
  mssql:
    container_name: mssql
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "Shop-lab-2026"
```

**`ACCEPT_EULA: "Y"` aceita duas licenças**, a do emulador e a do SQL Server, e nenhum dos dois
contêineres sobe sem isso; leia as duas nos endereços que a documentação da Microsoft dá antes de
pôr o valor. A senha é de um banco que nasce e morre no seu laptop, e o SQL Server só pede que ela
tenha oito caracteres ou mais e misture tipos de caractere. A porta 5672 é o AMQP, por onde as
mensagens passam, e a 5300 responde a uma verificação de saúde. Suba os dois e espere a verificação
dizer que está pronto; o SQL Server leva a maior parte do meio minuto:

```
ana@laptop:~/azure$ docker compose -f servicebus/compose.yaml up -d
 Network servicebus_default Creating 
 Network servicebus_default Creating 
 Network servicebus_default Created 
 Network servicebus_default Created 
 Container mssql Creating 
 Container mssql Created 
 Container servicebus-emulator Creating 
 Container servicebus-emulator Created 
 Container mssql Starting 
 Container mssql Started 
 Container servicebus-emulator Starting 
 Container servicebus-emulator Started 
ana@laptop:~/azure$ until curl -sf localhost:5300/health; do sleep 2; done; echo
{"status":"healthy","message":"Service is healthy."}
```

Os programas abaixo usam a biblioteca Python da Microsoft, `azure-servicebus`, na versão 7.15.0. Ela
vai num ambiente virtual próprio, `~/azure/messaging`, para que não possa trocar uma biblioteca de
que a CLI do Azure depende, junto com as duas bibliotecas de que a seção do Event Hubs precisa:

```
ana@laptop:~/azure$ python3 -m venv messaging
ana@laptop:~/azure$ messaging/bin/pip install -q azure-servicebus==7.15.0 azure-eventhub==5.15.1 azure-eventhub-checkpointstoreblob==1.2.0
ana@laptop:~/azure$ messaging/bin/pip list 2>/dev/null | grep -E "^azure-(servicebus|eventhub)"
azure-eventhub                     5.15.1
azure-eventhub-checkpointstoreblob 1.2.0
azure-servicebus                   7.15.0
```

A connection string do emulador é fixa e igual em toda máquina. `UseDevelopmentEmulator=true` diz à
biblioteca para falar AMQP puro com `localhost` em vez de TLS com um namespace no Azure, e a chave é
um marcador que o emulador aceita. Ponha-a no ambiente do terminal, onde os programas a leem:

```sh
export SERVICEBUS="Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
```

## Mandar, receber, completar

O primeiro programa da Ana manda uma mensagem por número de pedido que recebe. O id da mensagem é o
do pedido, `order-41`, e não um que a biblioteca inventaria, e a próxima seção mostra por que isso
importa. Salve-o como `~/azure/send.py`:

```python
# send.py
import json
import os
import sys

from azure.servicebus import ServiceBusClient, ServiceBusMessage

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client, client.get_queue_sender("orders") as sender:
    for order in sys.argv[1:]:
        body = json.dumps({"order": int(order)})
        sender.send_messages(ServiceBusMessage(body, message_id=f"order-{order}"))
        print(f"sent order-{order}")
```

O segundo recebe uma mensagem e a encerra do jeito que mandarem. Salve-o como `~/azure/work.py`:

```schooling-example
{"language": "python", "file": "work.py", "parts": [{"code": "# work.py\nimport os\nimport sys\n\nfrom azure.servicebus import ServiceBusClient\n\naction = sys.argv[1]\nclient = ServiceBusClient.from_connection_string(os.environ[\"SERVICEBUS\"])\n", "note": "O desfecho é o primeiro argumento: `complete`, `abandon`, `reject` ou qualquer outra coisa, como `crash`, que não liquida nada. A connection string vem do ambiente, então o arquivo não guarda chave nenhuma."}, {"code": "with client, client.get_queue_receiver(\"orders\") as receiver:\n    received = receiver.receive_messages(max_message_count=1, max_wait_time=2)\n    if not received:\n        sys.exit(\"nothing to receive\")\n    msg = received[0]\n    print(f\"{msg.message_id}: delivery_count {msg.delivery_count}, locked until {msg.locked_until_utc:%H:%M:%S} UTC\")\n", "note": "Um receiver é peek-lock a não ser que se diga outra coisa. Ele espera até dois segundos por uma mensagem, e o que volta fica travado para este receiver até `locked_until_utc`."}, {"code": "    if action == \"complete\":\n        receiver.complete_message(msg)\n    elif action == \"abandon\":\n        receiver.abandon_message(msg)\n    elif action == \"reject\":\n        receiver.dead_letter_message(msg, reason=\"UnknownProduct\", error_description=\"no such product in the catalogue\")\n    print(f\"{msg.message_id}: {action}\")\n", "note": "As três liquidações, cada uma um pedido ao broker enquanto a trava ainda vale. Qualquer outra palavra passa direto, e o programa sai do bloco `with` com uma mensagem que nunca liquidou, que é como uma queda parece vista da fila."}]}
```

Três pedidos entram, e o primeiro é recebido e completado:

```
ana@laptop:~/azure$ messaging/bin/python send.py 41 42 43
sent order-41
sent order-42
sent order-43
ana@laptop:~/azure$ messaging/bin/python work.py complete
order-41: delivery_count 0, locked until 18:51:16 UTC
order-41: complete
```

**A contagem de entregas de uma primeira entrega aparece como 0 nesta biblioteca**: é a contagem de
tentativas anteriores do cabeçalho AMQP, não de entregas até agora. A trava dura cinco segundos a
partir do recebimento, o que a hora ao lado mostra em UTC.

## Abandonar, cair, rejeitar

O pedido 42 é abandonado três vezes, como faria um consumidor que falha nele toda vez. O pedido 43 é
recebido por um consumidor que cai, o que `crash` imita saindo sem liquidar:

```
ana@laptop:~/azure$ for i in 1 2 3; do messaging/bin/python work.py abandon; done
order-42: delivery_count 0, locked until 18:51:18 UTC
order-42: abandon
order-42: delivery_count 1, locked until 18:51:21 UTC
order-42: abandon
order-42: delivery_count 2, locked until 18:51:24 UTC
order-42: abandon
ana@laptop:~/azure$ messaging/bin/python work.py crash
order-43: delivery_count 0, locked until 18:51:27 UTC
order-43: crash
ana@laptop:~/azure$ messaging/bin/python work.py complete
nothing to receive
ana@laptop:~/azure$ sleep 5; messaging/bin/python work.py reject
order-43: delivery_count 1, locked until 18:51:39 UTC
order-43: reject
```

Leia de cima para baixo. Cada abandon liberou `order-42` na hora, e a contagem dele subiu um. Depois
do terceiro, a fila não o entregou de novo: uma quarta entrega passaria de `MaxDeliveryCount`, então
ela moveu a mensagem para a **dead-letter subqueue** da fila. Por isso o recebimento seguinte pegou
`order-43`. A queda deixou `order-43` travada, então o recebimento logo depois não achou nada, embora
a fila não estivesse vazia. Cinco segundos depois a trava tinha expirado e a mensagem estava de
volta, com a contagem aumentada, e dessa vez o consumidor a rejeitou de propósito, com um motivo
próprio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A vida de uma mensagem na fila orders. Uma mensagem disponível é recebida e fica travada por 5 segundos para um consumidor. Da trava há três saídas: complete_message a remove; abandon_message, ou a trava expirando, a deixa disponível de novo com a contagem de entregas aumentada em um; dead_letter_message, ou uma entrega que passaria de MaxDeliveryCount, a move para a dead-letter subqueue.\"><defs><marker id=\"settle-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"settle-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"95\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">disponível</text><text x=\"95\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na fila</text><rect x=\"285\" y=\"100\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"360\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">travada por 5 s</text><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">para um consumidor</text><rect x=\"550\" y=\"16\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"625\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">removida</text><text x=\"625\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o trabalho foi feito</text><rect x=\"550\" y=\"184\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"625\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dead-letter subqueue</text><text x=\"625\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guardada até alguém ler</text><path d=\"M172 112 L282 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-p)\"></path><text x=\"227\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">receive_messages</text><path d=\"M285 142 L174 142\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-a)\"></path><text x=\"227\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">abandon_message</text><text x=\"227\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ou a trava expira</text><text x=\"227\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">contagem de entregas + 1</text><path d=\"M435 108 L547 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-p)\"></path><text x=\"462\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">complete_message</text><path d=\"M435 144 L547 200\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-a)\"></path><text x=\"476\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dead_letter_message</text><text x=\"476\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ou a contagem passa de MaxDeliveryCount</text></svg>", "caption": "Receber trava a mensagem; liquidá-la decide o que vem depois. Todo caminho de volta para a fila aumenta a contagem de entregas, e passado o limite a fila a põe de lado.", "same": ["dead-letter subqueue"]}
```

Toda fila, e toda assinatura de um tópico, tem a própria dead-letter subqueue, e **nada sai de lá
sozinho**: nenhum time-to-live vale ali, e uma mensagem fica até alguém recebê-la da subqueue e
completá-la. O terceiro programa olha sem tirar. Salve-o como `~/azure/dead.py`:

```python
# dead.py
import os

from azure.servicebus import ServiceBusClient, ServiceBusSubQueue

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
dlq = client.get_queue_receiver("orders", sub_queue=ServiceBusSubQueue.DEAD_LETTER)
with client, dlq:
    for msg in dlq.peek_messages(max_message_count=10):
        print(f"{msg.message_id}: {msg.dead_letter_reason}: {msg.dead_letter_error_description}")
```

```
ana@laptop:~/azure$ messaging/bin/python dead.py
order-42: MaxDeliveryCountExceeded: Message could not be consumed after 3 delivery attempts.
order-43: UnknownProduct: no such product in the catalogue
```

**Espiar lê uma mensagem sem travá-la**, então não muda nada: rode duas vezes e as mesmas duas linhas
voltam. Os dois motivos são os dois caminhos de entrada. `MaxDeliveryCountExceeded` é o da própria
fila, com a frase dela; `UnknownProduct` é o que o `work.py` escreveu. A documentação da Microsoft
sugere pôr o tipo da exceção no motivo e o stack trace na descrição, para que quem abrir a subqueue
depois saiba o que falhou. Um alerta na contagem de mensagens da subqueue acima de zero é como alguém
fica sabendo, e a lição 8 de `azure-operations` o constrói com o Azure Monitor.

## A mesma fila no Azure

Numa assinatura, a fila é um recurso de um namespace, e as duas configurações são opções do comando
que a cria. Não executado neste curso: precisa de uma assinatura.

```sh
az servicebus namespace create --resource-group shop-rg --name shop-bus --sku Standard
az servicebus queue create --resource-group shop-rg --namespace-name shop-bus --name orders \
  --lock-duration PT30S --max-delivery-count 10
```

O nível Basic só tem filas; os tópicos, que a próxima seção usa, pedem Standard ou Premium. **Uma
trava é um aluguel, e um trabalho longo precisa renová-la**: a biblioteca pode renová-la sozinha, e a
documentação da Microsoft recomenda uma lock duration maior que o tempo normal de processamento, para
que a renovação seja exceção. Uma trava também se perde junto com a conexão que a segura, e liquidar
uma mensagem depois disso falha; a resposta documentada é receber a mensagem de novo em vez de
repetir a liquidação.

Deixe o emulador rodando: a próxima seção o usa.
