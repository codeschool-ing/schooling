---
title: "Event Hubs: um log que cada leitor percorre no próprio ritmo"
version: 1
---

O Event Hubs recebe eventos, como os outros dois, e por isso é tentador lê-lo como uma fila que dá
conta de mais deles. **Ler de um event hub não remove nada e não liquida nada.** Um event hub é um log
só de acréscimo, dividido em **partições**; cada evento é escrito no fim de uma delas e fica lá até o
tempo de retenção acabar, uma hora por padrão no nível Standard e no máximo sete dias. Um leitor é uma
posição no log, não uma trava sobre uma mensagem. Duas aplicações leem os mesmos eventos por dois
**consumer groups**, cada um com as próprias posições, e nenhuma pode tirar um evento da outra. Até
onde um leitor chegou é assunto do próprio leitor, e salvar isso se chama **checkpointing**.

## O emulador, com o armazenamento ao lado

O emulador do Event Hubs é outra imagem da Microsoft, e o armazenamento de que ele precisa é o
Azurite, o emulador do Azure Storage. A declaração dele nomeia um event hub, `orders`, com duas
partições e dois consumer groups da loja; um terceiro, `$Default`, existe em todo event hub sem ser
declarado. Salve-a como `~/azure/eventhubs/Config.json`:

```json
{
  "UserConfig": {
    "NamespaceConfig": [
      {
        "Type": "EventHub",
        "Name": "emulatorNs1",
        "Entities": [
          {
            "Name": "orders",
            "PartitionCount": "2",
            "ConsumerGroups": [
              {
                "Name": "billing"
              },
              {
                "Name": "analytics"
              }
            ]
          }
        ]
      }
    ],
    "LoggingConfig": {
      "Type": "Console"
    }
  }
}
```

E os dois contêineres como `~/azure/eventhubs/compose.yaml`. A porta 10000 é o serviço de blobs do
Azurite, que os checkpoints vão usar:

```yaml
# eventhubs/compose.yaml
name: eventhubs
services:
  emulator:
    container_name: eventhubs-emulator
    image: mcr.microsoft.com/azure-messaging/eventhubs-emulator:2.2.1
    volumes:
      - ./Config.json:/Eventhubs_Emulator/ConfigFiles/Config.json
    ports:
      - "5672:5672"
      - "5300:5300"
    environment:
      BLOB_SERVER: azurite
      METADATA_SERVER: azurite
      ACCEPT_EULA: "Y"
    depends_on:
      - azurite
  azurite:
    container_name: azurite
    image: mcr.microsoft.com/azure-storage/azurite:3.37.0
    ports:
      - "10000:10000"
```

A connection string é a do emulador do Service Bus, caractere por caractere, porque os dois emuladores
respondem em `localhost:5672`, e é também por isso que só um deles pode rodar de cada vez. A do
armazenamento é a conta de desenvolvimento publicada do Azurite, igual em toda máquina:

```
ana@laptop:~/azure$ docker compose -f eventhubs/compose.yaml up -d
 Network eventhubs_default Creating 
 Network eventhubs_default Creating 
 Network eventhubs_default Created 
 Network eventhubs_default Created 
 Container azurite Creating 
 Container azurite Created 
 Container eventhubs-emulator Creating 
 Container eventhubs-emulator Created 
 Container azurite Starting 
 Container azurite Started 
 Container eventhubs-emulator Starting 
 Container eventhubs-emulator Started 
ana@laptop:~/azure$ until curl -sf localhost:5300/health; do sleep 2; done; echo
{"status":"healthy","message":"Service is healthy."}
ana@laptop:~/azure$ export EVENTHUBS="Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
ana@laptop:~/azure$ export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
```

## Partições e a partition key

O produtor manda cada passo de um pedido com o pedido como **partition key**. O Event Hubs calcula um
hash da chave para escolher uma partição, então todo evento com a mesma chave cai na mesma partição,
na ordem em que foi mandado. Salve-o como `~/azure/produce.py`:

```python
# produce.py
import json
import os
import sys

from azure.eventhub import EventData, EventHubProducerClient

producer = EventHubProducerClient.from_connection_string(os.environ["EVENTHUBS"], eventhub_name="orders")
with producer:
    for arg in sys.argv[1:]:
        order, step = arg.split(":")
        batch = producer.create_batch(partition_key=f"order-{order}")
        batch.add(EventData(json.dumps({"order": int(order), "step": step})))
        producer.send_batch(batch)
        print(f"sent order {order} {step}")
```

O leitor recebe o nome de um consumer group e lê todas as partições desde o começo do log, a posição
`"-1"`. Um consumidor nunca termina sozinho, então este se fecha depois de cinco segundos. Salve-o como
`~/azure/consume.py`:

```python
# consume.py
import os
import sys
import threading

from azure.eventhub import EventHubConsumerClient

group = sys.argv[1]
consumer = EventHubConsumerClient.from_connection_string(os.environ["EVENTHUBS"], consumer_group=group, eventhub_name="orders")


def on_event(partition_context, event):
    print(f"{group}: partition {partition_context.partition_id} seq {event.sequence_number}: {event.body_as_str()}")


threading.Timer(5, consumer.close).start()
with consumer:
    consumer.receive(on_event=on_event, starting_position="-1")
```

Seis eventos de três pedidos, e depois os dois consumer groups leem. Cada leitura passa por `sort`,
porque as partições são lidas lado a lado e a ordem *entre* elas não é definida: muda de uma execução
para outra, e a ordem dentro de cada uma é a que vale olhar.

```
ana@laptop:~/azure$ messaging/bin/python produce.py 42:paid 43:paid 42:packed 43:packed 42:shipped 44:paid
sent order 42 paid
sent order 43 paid
sent order 42 packed
sent order 43 packed
sent order 42 shipped
sent order 44 paid
ana@laptop:~/azure$ messaging/bin/python consume.py billing | sort
billing: partition 0 seq 0: {"order": 42, "step": "paid"}
billing: partition 0 seq 1: {"order": 42, "step": "packed"}
billing: partition 0 seq 2: {"order": 42, "step": "shipped"}
billing: partition 0 seq 3: {"order": 44, "step": "paid"}
billing: partition 1 seq 0: {"order": 43, "step": "paid"}
billing: partition 1 seq 1: {"order": 43, "step": "packed"}
ana@laptop:~/azure$ messaging/bin/python consume.py analytics | sort
analytics: partition 0 seq 0: {"order": 42, "step": "paid"}
analytics: partition 0 seq 1: {"order": 42, "step": "packed"}
analytics: partition 0 seq 2: {"order": 42, "step": "shipped"}
analytics: partition 0 seq 3: {"order": 44, "step": "paid"}
analytics: partition 1 seq 0: {"order": 43, "step": "paid"}
analytics: partition 1 seq 1: {"order": 43, "step": "packed"}
```

**Cada pedido ficou numa partição, e manteve a ordem lá dentro**: `paid`, `packed`, `shipped` do pedido
42 na partição 0 com números de sequência 0, 1 e 2. O hash do pedido 43 caiu na outra partição, e o do
44 na mesma do 42; uma chave decide *qual* partição, nunca que ela tem uma só para si. O número de
sequência conta a partir de 0 dentro de cada partição e não quer dizer nada entre elas. **E `analytics`
leu exatamente o que `billing` tinha lido**, desde o começo, porque ler não tirou nada: os eventos
continuam no log para quem mais pedir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"O event hub orders como duas partições, cada uma uma fileira de eventos na ordem em que foram escritos. A partição 0 guarda o pedido 42 paid, packed e shipped, depois o pedido 44 paid, números de sequência 0 a 3. A partição 1 guarda o pedido 43 paid, packed e shipped, números de sequência 0 a 2. Eventos novos entram à direita. O consumer group billing tem um checkpoint depois do último evento de cada partição. O consumer group analytics não tem nenhum e lê desde o começo.\"><defs><marker id=\"log-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"log-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"16\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-weight=\"600\">partição 0</text><text x=\"166.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 0</text><rect x=\"120\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"166.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">42 paid</text><text x=\"264.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 1</text><rect x=\"218\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"264.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">42 packed</text><text x=\"362.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 2</text><rect x=\"316\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"362.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">42 shipped</text><text x=\"460.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 3</text><rect x=\"414\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"460.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">44 paid</text><path d=\"M509.0 44 L509.0 90\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"515.0\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">billing</text><text x=\"515.0\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">checkpoint</text><path d=\"M116 44 L116 90\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></path><text x=\"16\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-weight=\"600\">partição 1</text><text x=\"166.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 0</text><rect x=\"120\" y=\"140\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"166.0\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43 paid</text><text x=\"264.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 1</text><rect x=\"218\" y=\"140\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"264.0\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43 packed</text><text x=\"362.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 2</text><rect x=\"316\" y=\"140\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"362.0\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43 shipped</text><path d=\"M411.0 134 L411.0 180\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"417.0\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">billing</text><text x=\"417.0\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">checkpoint</text><path d=\"M116 134 L116 180\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></path><path d=\"M570 65 L650 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#log-p)\"></path><text x=\"610\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">eventos novos</text><text x=\"610\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entram no fim</text><text x=\"116\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">analytics</text><text x=\"180\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem checkpoint: lê desde o começo</text></svg>", "caption": "Duas partições, cada uma na ordem em que foi escrita, e dois consumer groups com posições próprias. Ler não moveu nada: os eventos ficam até a retenção acabar.", "same": ["checkpoint"]}
```

O número de partições é fixado quando o event hub é criado, e no nível Standard continua fixo. Os
níveis Premium e Dedicated podem acrescentar partições depois, e fazer isso move chaves para partições novas,
o que quebra a ordem de tudo o que estiver em trânsito. **É também o máximo de leitores que um consumer
group consegue aproveitar**, já que dentro de um grupo um leitor é dono de uma partição por vez: duas
partições, como aqui, quer dizer no máximo dois workers de faturamento dividindo a carga.

## Checkpoints: até onde um leitor chegou

O `consume.py` começou do início toda vez, o que é certo para um relatório e errado para o
faturamento, que precisa cobrar cada pedido uma vez. A biblioteca guarda a posição de um leitor num
**checkpoint store**, um contêiner de blobs, e o Azurite fornece um. Crie o contêiner com a CLI do
Azure, que funciona contra o Azurite sem login, porque a connection string leva a chave:

```
ana@laptop:~/azure$ az storage container create --name checkpoints
{
  "created": true
}
```

Salve o leitor que faz checkpoint como `~/azure/checkpoint.py`:

```schooling-example
{"language": "python", "file": "checkpoint.py", "parts": [{"code": "# checkpoint.py\nimport os\nimport sys\nimport threading\n\nfrom azure.eventhub import EventHubConsumerClient\nfrom azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore\n\ngroup = sys.argv[1]\nsave = sys.argv[2:] != [\"nocheckpoint\"]\nstore = BlobCheckpointStore.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"], container_name=\"checkpoints\")\nconsumer = EventHubConsumerClient.from_connection_string(os.environ[\"EVENTHUBS\"], consumer_group=group, eventhub_name=\"orders\", checkpoint_store=store)\n", "note": "O mesmo consumidor de antes, com um checkpoint store: o contêiner `checkpoints` no Azurite. Com um store, a biblioteca também reparte as partições entre todos os leitores do grupo que estão rodando, pelo mesmo contêiner."}, {"code": "\n\ndef on_event(partition_context, event):\n    print(f\"{group}: partition {partition_context.partition_id} seq {event.sequence_number}: {event.body_as_str()}\")\n    if save:\n        partition_context.update_checkpoint(event)\n", "note": "O trabalho, aqui uma linha impressa, e depois o checkpoint: o leitor desta partição terminou este evento. Com `nocheckpoint`, ele faz o trabalho e não salva nada."}, {"code": "\n\nthreading.Timer(10, consumer.close).start()\nwith consumer:\n    consumer.receive(on_event=on_event, starting_position=\"-1\")\n", "note": "O `\"-1\"` agora vale só para uma partição que ainda não tem checkpoint; uma que tem começa depois dele. Dez segundos em vez de cinco, porque reivindicar as partições pelo store leva alguns."}]}
```

Ele roda duas vezes, depois mais um evento é mandado, e uma execução que faz o trabalho e para antes
do checkpoint é seguida por uma que faz o checkpoint:

```
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing | sort
billing: partition 0 seq 0: {"order": 42, "step": "paid"}
billing: partition 0 seq 1: {"order": 42, "step": "packed"}
billing: partition 0 seq 2: {"order": 42, "step": "shipped"}
billing: partition 0 seq 3: {"order": 44, "step": "paid"}
billing: partition 1 seq 0: {"order": 43, "step": "paid"}
billing: partition 1 seq 1: {"order": 43, "step": "packed"}
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing | sort
ana@laptop:~/azure$ messaging/bin/python produce.py 43:shipped
sent order 43 shipped
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing nocheckpoint
billing: partition 1 seq 2: {"order": 43, "step": "shipped"}
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing
billing: partition 1 seq 2: {"order": 43, "step": "shipped"}
```

A primeira execução leu os seis eventos, desde o começo de cada partição, porque ainda não existia
checkpoint nenhum, e salvou um depois de cada. A segunda não leu nada: as duas partições já tinham um
checkpoint, e nada tinha sido escrito depois dele. **A execução `nocheckpoint` é um consumidor que caiu
depois de fazer o trabalho**, e a execução seguinte leu o mesmo evento de novo. Isso não é defeito do
emulador nem da biblioteca: a posição é salva depois do trabalho, então sempre há um momento em que o
trabalho está feito e a posição não, e uma queda nesse momento quer dizer uma segunda entrega. Salvar a
posição *antes* do trabalho muda o buraco de lado: uma queda que perde o evento. Os checkpoints em si
são blobs, cujos metadados guardam o número de sequência e o offset do último evento que o leitor
de cada partição terminou:

```
ana@laptop:~/azure$ az storage blob list --container-name checkpoints --include m --query "[?contains(name, 'checkpoint')].{name: name, seq: metadata.sequencenumber, offset: metadata.offset}" --output table
Name                                   Seq    Offset
-------------------------------------  -----  --------
localhost/orders/billing/checkpoint/0  3      432
localhost/orders/billing/checkpoint/1  2      288
```

Pare o emulador quando terminar:

```
ana@laptop:~/azure$ docker compose -f eventhubs/compose.yaml down
 Container eventhubs-emulator Stopping 
 Container eventhubs-emulator Stopped 
 Container eventhubs-emulator Removing 
 Container eventhubs-emulator Removed 
 Container azurite Stopping 
 Container azurite Stopped 
 Container azurite Removing 
 Container azurite Removed 
 Network eventhubs_default Removing 
 Network eventhubs_default Removed 
```

## Fila, evento, fluxo

| | Service Bus | Event Grid | Event Hubs |
| --- | --- | --- | --- |
| o que leva | uma mensagem: trabalho que alguém precisa fazer | um evento: notícia de algo que aconteceu | um fluxo: uma série de eventos, guardada |
| como chega ao consumidor | o consumidor recebe e liquida | o Event Grid empurra para o handler | o consumidor lê a partir de uma posição |
| depois de tratado | some, quando completado | some, quando entregue | continua lá até a retenção acabar |
| vários consumidores | competindo numa fila, uma cópia por assinatura num tópico | uma cópia por event subscription | uma visão inteira por consumer group |
| ordem | por sessão | nenhuma prometida | por partição |
| quando não dá para tratar | dead-letter subqueue | contêiner de dead-letter, se houver | nada: o leitor decide |

A loja usa os três, cada um para o que ele é. O Service Bus leva pedidos, que precisam ser cobrados e
despachados exatamente tantas vezes quantas foram pagos. O Event Grid leva avisos: um pedido grande
precisa de uma pessoa, o relatório de vendas noturno chegou numa storage account. O Event Hubs leva o
fluxo de todo clique e toda visualização de página que o site produz, lido por um relatório e por
verificações de fraude, cada um no próprio ritmo.

## Pelo menos uma vez, então quem decide é o handler

**Os três entregam pelo menos uma vez.** Duas segundas entregas apareceram na tela nesta lição, uma
trava que expirou e um leitor que parou antes do checkpoint, e a documentação do Event Grid cita a
dele, uma nova tentativa depois de uma resposta que veio tarde demais. A detecção de duplicatas do
Service Bus remove as repetições do remetente dentro de uma janela, e nada remove as do consumidor.
Então o consumidor é escrito para ser **idempotente**: tratar a mesma mensagem duas vezes tem o efeito
de tratá-la uma vez.

O jeito de fazer isso é uma chave que nomeia a unidade de trabalho, levada na mensagem, e um registro
das chaves já feitas, guardado num armazenamento que sobrevive a qualquer mensagem. O `MessageId` da
primeira seção, `order-41`, é uma dessas chaves; o `id` de um CloudEvent é outra; os eventos de um
event hub levam o pedido e o passo. O faturamento insere `charge-42` numa tabela em que essa coluna é
única, dentro da mesma transação da cobrança, e uma segunda inserção falha, então a segunda cópia é
reconhecida e pulada. **A unicidade é conferida pelo banco, não pelo programa**, e é isso que impede
dois workers com duas cópias no mesmo instante de ganharem os dois.
