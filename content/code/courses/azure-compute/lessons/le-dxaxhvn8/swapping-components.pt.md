---
title: Trocando um componente, e o que vem junto
version: 1
---

Esta é a promessa que o Dapr faz, e a seção a testa: apontar o broker para o Azure Service Bus
escrevendo outro arquivo YAML, manter o nome `pubsub` e não mudar nem o `subscriber.py` nem o pedido
que publica. **Funciona, depois de uma configuração, e a entrega deixa de ser a mesma.** As duas
metades são praticadas, contra o emulador do Service Bus da Microsoft, com os mesmos três programas
da seção anterior.

A imagem a trocar é a de que um componente é um endereço: troca-se o arquivo e só o destino muda.
Um componente é um cliente de um produto, com os padrões desse produto, e ele os traz junto. Um
deles barra a troca na primeira tentativa, e outro muda quem recebe o quê sem um único erro.

## Um Service Bus no laptop

A lição 20 é sobre o próprio Service Bus e roda o emulador como se deve. Aqui ele é só um broker,
então a apresentação é curta. O emulador são dois contêineres, o broker e o SQL Server em que ele
guarda as mensagens, e ele lê de um arquivo as entidades que deve criar. Crie um diretório
`~/azure/servicebus` e salve isto como `~/azure/servicebus/Config.json`:

```json
{
  "UserConfig": {
    "Namespaces": [
      {
        "Name": "sbemulatorns",
        "Queues": [
          {
            "Name": "orders"
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

Um namespace, cujo nome `sbemulatorns` é do próprio emulador e não pode mudar, com uma fila,
`orders`, com o nome do tópico que os programas já usam. Inicie os dois contêineres na `shop-net`,
para que os sidecars alcancem o broker pelo nome, `servicebus`. **`ACCEPT_EULA=Y` aceita duas
licenças**, a do emulador e a do SQL Server; leia as duas nos endereços que a documentação da
Microsoft dá antes de definir isso. A senha é de um banco que nasce e morre no seu laptop. O SQL
Server ocupa a maior parte do meio minuto que a verificação de saúde espera:

```
ana@laptop:~/azure$ docker run -d --name mssql --network shop-net -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=Shop-lab-2026 mcr.microsoft.com/mssql/server:2022-latest > /dev/null
ana@laptop:~/azure$ docker run -d --name servicebus --network shop-net -p 5300:5300 -v ~/azure/servicebus/Config.json:/ServiceBus_Emulator/ConfigFiles/Config.json -e SQL_SERVER=mssql -e MSSQL_SA_PASSWORD=Shop-lab-2026 -e ACCEPT_EULA=Y mcr.microsoft.com/azure-messaging/servicebus-emulator:2.0.1 > /dev/null
ana@laptop:~/azure$ until curl -sf localhost:5300/health; do sleep 2; done; echo
{"status":"healthy","message":"Service is healthy."}
```

## A troca

O componente novo vai num diretório próprio, `~/azure/components-sb`, para que o do Redis fique como
estava. Salve isto como `~/azure/components-sb/pubsub.yaml`:

```yaml
# components-sb/pubsub.yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.azure.servicebus.queues
  version: v1
  metadata:
  - name: connectionString
    value: "Endpoint=sb://servicebus;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
```

O nome continua `pubsub`. O tipo é o componente do Dapr para filas do Service Bus, e a sua única
configuração é a connection string do emulador, que é fixa e igual em toda máquina, exceto pelo
host: `servicebus`, o nome do contêiner, e não `localhost`, que dentro de um sidecar é o app dele.
`UseDevelopmentEmulator=true` diz ao cliente para falar AMQP puro, sem TLS. O armazenamento de
estado não muda, então é copiado, e os três sidecars são substituídos para ler o diretório novo:

```
ana@laptop:~/azure$ cp components/statestore.yaml components-sb/
ana@laptop:~/azure$ ls components-sb
pubsub.yaml
statestore.yaml
ana@laptop:~/azure$ docker rm -f shop-dapr billing-dapr audit-dapr > /dev/null
ana@laptop:~/azure$ for app in shop billing audit; do docker run -d --name $app-dapr --network container:$app -v ~/azure/components-sb:/components daprio/daprd:1.17.16 ./daprd --app-id $app --app-port 8080 --resources-path /components > /dev/null; done
```

Depois, a mesma publicação de antes, com a resposta guardada num arquivo para a mensagem poder ser
lida:

```
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -o err.json -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{"id": 2, "item": "tea", "qty": 1}'
500
ana@laptop:~/azure$ jq -r .message err.json
error when publishing to topic orders in pubsub pubsub: failed to create a sender: could not get queue orders: Get "https://servicebus/orders?api-version=2021-05": dial tcp 172.20.0.7:443: connect: connection refused
```

**O componente fez mais do que o código pediu.** Antes de enviar, ele perguntou ao endpoint de
gerenciamento do namespace, por HTTPS na porta 443, se a fila `orders` existe, porque por padrão os
componentes do Service Bus do Dapr criam as filas e assinaturas de que precisam. O emulador não
responde ali, e a publicação falhou com 500. Contra um namespace de verdade, o mesmo padrão exige
uma credencial que possa gerenciar entidades, e não só enviar e receber; a documentação do Dapr diz
isso para uma política de acesso compartilhado. Aqui a fila já está declarada no `Config.json`,
então a correção é mandar o componente não gerenciá-la. É uma configuração, acrescentada ao
arquivo:

```
ana@laptop:~/azure$ printf '  - name: disableEntityManagement\n    value: "true"\n' >> components-sb/pubsub.yaml
ana@laptop:~/azure$ tail -n 4 components-sb/pubsub.yaml
  - name: connectionString
    value: "Endpoint=sb://servicebus;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
  - name: disableEntityManagement
    value: "true"
ana@laptop:~/azure$ docker rm -f shop-dapr billing-dapr audit-dapr > /dev/null
ana@laptop:~/azure$ for app in shop billing audit; do docker run -d --name $app-dapr --network container:$app -v ~/azure/components-sb:/components daprio/daprd:1.17.16 ./daprd --app-id $app --app-port 8080 --resources-path /components > /dev/null; done
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{"id": 2, "item": "tea", "qty": 1}'
204
ana@laptop:~/azure$ docker logs billing
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
ana@laptop:~/azure$ docker logs audit
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 2, "item": "tea", "qty": 1}, "from": "shop", "type": "com.dapr.event.sent"}
```

`204`, e nenhuma linha do `subscriber.py` ou da publicação mudou. Essa é a metade da promessa que
se cumpre.

## Os mesmos dois programas, outra entrega

Mais quatro pedidos, e depois o que cada assinante imprimiu desde que iniciou:

```
ana@laptop:~/azure$ for id in 3 4 5 6; do curl -s -o /dev/null -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d "{\"id\": $id}"; done
ana@laptop:~/azure$ docker logs billing | tail -n +2
{"order": {"id": 3}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 5}, "from": "shop", "type": "com.dapr.event.sent"}
ana@laptop:~/azure$ docker logs audit | tail -n +2
{"order": {"id": 2, "item": "tea", "qty": 1}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 4}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 6}, "from": "shop", "type": "com.dapr.event.sent"}
```

O pedido 1 está nos dois logs: ele veio pelo Redis, na seção anterior, uma cópia por app. Os
pedidos 2 a 6 vieram pelo Service Bus, e **cada um deles chegou a exatamente um dos dois**. Qual
pegou qual muda de uma execução para outra; que cada um foi para um só, não muda. O billing nunca
teria cobrado alguns desses pedidos, e nada em lugar nenhum registrou um erro.

O motivo está no nome do componente. `pubsub.azure.servicebus.queues` liga o tópico `orders` à fila
`orders`, e todo app que assina lê essa mesma fila, então billing e audit são dois receptores nela,
e uma fila entrega cada mensagem a um receptor. O Redis dava a cada app id um grupo de consumidores
próprio. A API que os dois programas chamaram foi a mesma; a entrega é do componente, e o
componente mudou. O Redis não recebeu nada desta vez, e o sidecar diz qual é o broker novo:

```
ana@laptop:~/azure$ docker exec redis redis-cli XLEN orders
1
ana@laptop:~/azure$ curl -s localhost:3500/v1.0/metadata | jq -c '.components[]'
{"name":"pubsub","type":"pubsub.azure.servicebus.queues","version":"v1","capabilities":["MESSAGE_TTL","BULK_PUBSUB"]}
{"name":"statestore","type":"state.redis","version":"v1","capabilities":["ETAG","TRANSACTIONAL","TTL","QUERY_API","KEYS_LIKE","ACTOR"]}
```

O que billing e audit esperavam é o que faz o outro componente do Service Bus do Dapr,
`pubsub.azure.servicebus.topics`: o tópico vira um tópico do Service Bus, e cada app ganha uma
assinatura própria nele, com o nome do seu consumer ID, que é o app id a menos que o componente
defina outro. Com o gerenciamento de entidades desligado, como aqui, as assinaturas `billing` e
`audit` teriam de existir antes, declaradas no `Config.json` ou em Bicep. Isso não é executado nesta
lição. **Escolher entre os dois é uma pergunta sobre o sistema, e nenhum arquivo dele a responde por
você**: uma fila serve para trabalho que um único worker deve fazer uma vez, e um tópico para
notícias que toda equipe interessada deve ouvir. A lição 20 traça essa linha para o próprio Service
Bus.

Então, diante da promessa:

| | Redis | filas do Service Bus |
| --- | --- | --- |
| `subscriber.py` e a publicação | iguais | iguais |
| o nome do componente, `pubsub` | igual | igual |
| criar a fila | desnecessário | tentado por padrão, recusado aqui |
| dois apps num tópico | uma cópia para cada | uma cópia entre os dois |

O código não mudou, e duas das quatro linhas mudaram.
