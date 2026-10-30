---
title: "Tópicos, sessões e duplicatas"
version: 1
---

Quando um pedido é pago, o faturamento precisa saber e a expedição também. O primeiro desenho que
vem à cabeça é uma fila que os dois leem. **Uma fila entrega cada mensagem a um consumidor**, então
faturamento e expedição dividiriam os pedidos entre si, cada um vendo mais ou menos a metade e
nenhum percebendo. O que eles precisam é de um **tópico**. Quem manda, manda para um tópico do mesmo
jeito que manda para uma fila, mas ninguém recebe do tópico em si: cada **assinatura** do tópico é
uma fila própria que recebe uma cópia de toda mensagem, com trava própria, contagem de entregas
própria e dead-letter subqueue própria. Esta seção usa o tópico, a fila com sessões e a fila que
detecta duplicatas que o `Config.json` declarou na seção anterior; o emulador de lá continua
rodando.

## Uma mensagem, uma cópia por assinatura

O tópico é `order-paid`, e ele tem duas assinaturas. `billing` não tem regra, o que lhe dá a regra
padrão: um filtro sempre verdadeiro, então ela recebe tudo. `shipping` tem uma regra chamada
`physical-only` cujo filtro é `kind = 'physical'`, porque um produto digital não tem nada para
despachar.

O publicador da Ana põe o tipo de cada pedido numa **application property**, um nome e um valor que
vão ao lado do corpo, porque é isso que um filtro lê; o corpo é opaco para o broker. Salve-o como
`~/azure/publish.py`:

```python
# publish.py
import json
import os
import sys

from azure.servicebus import ServiceBusClient, ServiceBusMessage

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client, client.get_topic_sender("order-paid") as sender:
    for arg in sys.argv[1:]:
        order, kind = arg.split(":")
        body = json.dumps({"order": int(order), "kind": kind})
        msg = ServiceBusMessage(body, message_id=f"order-{order}-paid", application_properties={"kind": kind})
        sender.send_messages(msg)
        print(f"published order {order} ({kind})")
```

E um leitor que esvazia uma assinatura, dada na linha de comando, como `~/azure/read.py`:

```python
# read.py
import os
import sys

from azure.servicebus import ServiceBusClient

subscription = sys.argv[1]
client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client, client.get_subscription_receiver("order-paid", subscription) as receiver:
    for msg in receiver.receive_messages(max_message_count=10, max_wait_time=2):
        print(f"{subscription}: {msg}")
        receiver.complete_message(msg)
```

Dois pedidos são pagos, um físico e um digital:

```
ana@laptop:~/azure$ messaging/bin/python publish.py 42:physical 43:digital
published order 42 (physical)
published order 43 (digital)
ana@laptop:~/azure$ messaging/bin/python read.py billing
billing: {"order": 42, "kind": "physical"}
billing: {"order": 43, "kind": "digital"}
ana@laptop:~/azure$ messaging/bin/python read.py shipping
shipping: {"order": 42, "kind": "physical"}
```

**O faturamento recebeu os dois e a expedição recebeu um.** O broker avaliou a regra quando a
mensagem chegou e nunca pôs o pedido digital em `shipping`, então nenhum consumidor precisou
recebê-lo para jogá-lo fora. Cada assinatura foi esvaziada à parte: completar uma mensagem em
`billing` não fez nada com a cópia dela em `shipping`.

A linguagem do filtro é um subconjunto de SQL. Ela lê application properties pelo nome e as
propriedades do próprio broker com o prefixo `sys.`, como em `sys.MessageId LIKE 'order-%'`, e tem
`AND`, `OR`, `NOT`, comparações, `EXISTS` e `LIKE`. Um **correlation filter** é o outro tipo comum: um
conjunto de propriedades que precisam ser todas iguais, sem expressão para avaliar. Uma assinatura
com várias regras recebe uma cópia se qualquer uma delas casar. Uma regra também pode trazer uma
**action** que muda as propriedades da cópia, e aí cada regra com action que casa produz uma cópia
própria; esta lição não usa nenhuma.

## Ordem por chave: sessões

Uma fila entrega as mensagens mais ou menos na ordem em que chegaram, mas, com vários consumidores
tirando dela, os passos de um mesmo pedido podem ser tratados lado a lado ou fora de ordem: `shipped`
processado antes de `packed` terminar. A resposta do Service Bus é a **sessão**. Toda mensagem leva
um session id, aqui o do pedido. Um receiver aceita uma sessão inteira de cada vez e segura uma
trava exclusiva sobre ela, então as mensagens de uma sessão vão para um receiver, em ordem, enquanto
outros receivers pegam outras sessões. A fila `order-steps` foi declarada com `RequiresSession`.
Salve isto como `~/azure/steps.py`:

```python
# steps.py
import os

from azure.servicebus import NEXT_AVAILABLE_SESSION, ServiceBusClient, ServiceBusMessage

STEPS = [("order-42", "paid"), ("order-43", "paid"), ("order-42", "packed"),
         ("order-43", "packed"), ("order-42", "shipped")]

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client:
    with client.get_queue_sender("order-steps") as sender:
        for order, step in STEPS:
            sender.send_messages(ServiceBusMessage(step, session_id=order))
    for _ in range(2):
        receiver = client.get_queue_receiver("order-steps", session_id=NEXT_AVAILABLE_SESSION, max_wait_time=2)
        with receiver:
            msgs = receiver.receive_messages(max_message_count=10, max_wait_time=2)
            print(receiver.session.session_id, [str(m) for m in msgs])
            for m in msgs:
                receiver.complete_message(m)
```

Os cinco passos entram intercalados, e cada receiver pega a sessão que estiver livre. Qual das duas
vem primeiro pode mudar de uma execução para outra; a ordem dentro de cada uma, não. O último comando
manda para a mesma fila sem session id:

```
ana@laptop:~/azure$ messaging/bin/python steps.py
order-42 ['paid', 'packed', 'shipped']
order-43 ['paid', 'packed']
ana@laptop:~/azure$ messaging/bin/python -c 'import os; from azure.servicebus import *; c = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"]); c.get_queue_sender("order-steps").send_messages(ServiceBusMessage("paid"))' 2>&1 | grep -o "ServiceBusError: [^.]*\."
ServiceBusError: The SessionId was not set on a message, and it cannot be sent to the entity.
```

**Numa fila com sessões, uma mensagem sem session id é recusada**, e, ligadas as sessões, todo
remetente e todo receiver daquela fila precisa usá-las. O Service Bus não define começo nem fim para
uma sessão: a documentação da Microsoft diz que uma mensagem com o mesmo id um ano depois pertence à
mesma sessão, então onde a história de um pedido termina é a aplicação que diz. O nível Basic não tem
sessões, nem detecção de duplicatas.

## Duplicatas que a fila descarta

Um remetente que manda, perde a conexão antes de a resposta voltar e manda de novo pôs a mesma
mensagem duas vezes na fila, e não tem como saber que pôs. Com a **detecção de duplicatas** ligada, a
fila lembra todo `MessageId` que aceitou durante uma janela e descarta em silêncio uma mensagem
posterior com o mesmo id; o envio continua informando sucesso. A fila `payments` tem uma janela de um
minuto. Salve isto como `~/azure/pay.py`, que manda a mesma cobrança duas vezes e depois lê a fila:

```python
# pay.py
import os

from azure.servicebus import ServiceBusClient, ServiceBusMessage

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client:
    with client.get_queue_sender("payments") as sender:
        for charge in ["charge-42", "charge-42", "charge-43"]:
            sender.send_messages(ServiceBusMessage(charge, message_id=charge))
            print(f"sent {charge}")
    with client.get_queue_receiver("payments", max_wait_time=2) as receiver:
        for msg in receiver.receive_messages(max_message_count=10, max_wait_time=2):
            print(f"received {msg.message_id}")
            receiver.complete_message(msg)
```

```
ana@laptop:~/azure$ messaging/bin/python pay.py
sent charge-42
sent charge-42
sent charge-43
received charge-42
received charge-43
```

Três envios foram aceitos, e duas mensagens chegaram. **Só o `MessageId` é comparado**, nunca o
corpo, e é por isso que ele precisa vir do negócio, `charge-42`, e não ser um id aleatório que a
biblioteca inventa a cada envio: uma nova tentativa ganharia outro, e nada casaria. A janela é de dez
minutos por padrão e pode ir de 20 segundos a 7 dias; uma mais longa custa vazão, porque cada id novo
é conferido contra todos os ids lembrados.

A detecção de duplicatas cobre a metade do remetente e nada mais. Um consumidor que cobra o cartão e
cai antes de completar a mensagem a recebe de novo quando a trava expira, com o mesmo id, e a fila
não tem o que descartar: a mensagem só foi mandada uma vez. Essa metade é do consumidor, e a última
seção desta lição volta a ela.

Pare o emulador agora. O emulador do Event Hubs usa a mesma porta, e o `down` remove os dois
contêineres e a rede que o Compose criou:

```
ana@laptop:~/azure$ docker compose -f servicebus/compose.yaml down
 Container servicebus-emulator Stopping 
 Container servicebus-emulator Stopped 
 Container servicebus-emulator Removing 
 Container servicebus-emulator Removed 
 Container mssql Stopping 
 Container mssql Stopped 
 Container mssql Removing 
 Container mssql Removed 
 Network servicebus_default Removing 
 Network servicebus_default Removed 
```
