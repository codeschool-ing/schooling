---
title: "Event Grid: um aviso empurrado para quem pediu"
version: 1
---

O Event Grid aparece ao lado do Service Bus em toda lista de serviços de mensageria do Azure, e é
fácil tomá-lo por mais uma fila. **Ele é um roteador, e não guarda nada para ninguém buscar.** Um
publicador posta um *evento*, um aviso curto de que algo aconteceu, num **tópico**. Cada **event
subscription** desse tópico diz quais eventos quer e para onde vão, e o Event Grid *empurra* cada
evento que casa para lá, como uma requisição HTTP, na hora. Ninguém consulta e nada fica esperando
ser recebido: se o handler está fora do ar, o Event Grid tenta de novo no próprio cronograma e depois
desiste. Uma mensagem do Service Bus é trabalho que alguém precisa fazer; um evento do Event Grid é
uma notícia que pode interessar a alguém.

**Nada num laptop roda o Event Grid**, e a Microsoft não publica emulador para ele, então esta seção
é lida. O que roda é a declaração, que o compilador Bicep confere, e a ajuda da CLI.

## De onde vêm os eventos

Um **system topic** leva os eventos de um serviço do Azure: uma storage account anunciando que um blob
foi criado, um resource group anunciando que um recurso foi gravado. Só o serviço publica nele, então
ele não tem endpoint nem chave seus, e há um system topic por origem. Um **custom topic** é da própria
aplicação: a loja cria um, recebe um endpoint e uma chave de acesso, e posta os eventos dela lá.

Um evento chega num de dois formatos. O schema do Event Grid é o da própria Microsoft; o
**CloudEvents 1.0** é uma especificação aberta da Cloud Native Computing Foundation, e o Event Grid o
aceita e o entrega nativamente. Este é o evento que a API de pedidos da loja postaria quando um pedido
é feito. Ele foi escrito para esta lição, não recebido de lugar nenhum:

```json
{
  "specversion": "1.0",
  "type": "shop.order.placed",
  "source": "/shop/orders",
  "id": "order-42-placed",
  "time": "2026-10-30T14:05:00Z",
  "subject": "orders/42",
  "datacontenttype": "application/json",
  "data": {"order": 42, "total": 150000}
}
```

O envelope é o da especificação: `type` diz o que aconteceu, `source` e `subject` dizem onde, `id`
nomeia este evento, e `data` é da loja, aqui um total em centavos. O `id` importa no fim desta lição,
porque é por ele que um handler que já viu um evento o reconhece.

## Uma assinatura, declarada e compilada

A loja quer que pedidos grandes sejam revistos por uma pessoa. Uma assinatura no custom topic resolve:
ela pega só `shop.order.placed`, só acima de R$ 1.000,00, e manda para o endereço do serviço de
revisão. O endereço é um parâmetro marcado `@secure()`, porque o endereço de um webhook muitas vezes
leva uma chave na query string, e o compilador avisa quando um está escrito no arquivo. Salve isto
como `~/azure/events.bicep`:

```bicep
// events.bicep
param location string = 'brazilsouth'

@secure()
param reviewUrl string

resource topic 'Microsoft.EventGrid/topics@2025-02-15' = {
  name: 'shop-orders'
  location: location
  properties: {
    inputSchema: 'CloudEventSchemaV1_0'
  }
}

resource bigOrders 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: topic
  name: 'big-orders'
  properties: {
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: reviewUrl
      }
    }
    filter: {
      includedEventTypes: [
        'shop.order.placed'
      ]
      advancedFilters: [
        {
          operatorType: 'NumberGreaterThan'
          key: 'data.total'
          value: 100000
        }
      ]
    }
    retryPolicy: {
      maxDeliveryAttempts: 10
      eventTimeToLiveInMinutes: 120
    }
    deadLetterDestination: {
      endpointType: 'StorageBlob'
      properties: {
        resourceId: resourceId('Microsoft.Storage/storageAccounts', 'shopdeadletters')
        blobContainerName: 'undelivered'
      }
    }
  }
}
```

O filtro tem os três níveis que o Event Grid oferece: tipos de evento, um subject que começa ou
termina com algo (não usado aqui), e **advanced filters** sobre qualquer campo do evento, `data.total`
inclusive. Compile, e depois compile duas cópias com um valor mudado em cada, um operador escrito
errado e uma contagem de tentativas elevada a 50:

```
ana@laptop:~/azure$ bicep build events.bicep
ana@laptop:~/azure$ sed "s/NumberGreaterThan/NumberGreaterThen/" events.bicep > typo.bicep; bicep build typo.bicep
/home/ana/azure/typo.bicep(32,25) : Warning BCP088: The property "operatorType" expected a value of type "'BoolEquals' | 'IsNotNull' | 'IsNullOrUndefined' | 'NumberGreaterThan' | 'NumberGreaterThanOrEquals' | 'NumberIn' | 'NumberInRange' | 'NumberLessThan' | 'NumberLessThanOrEquals' | 'NumberNotIn' | 'NumberNotInRange' | 'StringBeginsWith' | 'StringContains' | 'StringEndsWith' | 'StringIn' | 'StringNotBeginsWith' | 'StringNotContains' | 'StringNotEndsWith' | 'StringNotIn'" but the provided value is of type "'NumberGreaterThen'". Did you mean "'NumberGreaterThan'"? [https://aka.ms/bicep/core-diagnostics#BCP088]
ana@laptop:~/azure$ sed "s/maxDeliveryAttempts: 10/maxDeliveryAttempts: 50/" events.bicep > fifty.bicep; bicep build fifty.bicep
```

O arquivo limpo compila sem uma palavra. O operador escrito errado recebe um aviso, que este curso
trata como recusa, com a lista dos dezenove operadores que ele poderia ter sido e o que ele mais
provavelmente era. **A contagem de 50 passou, embora a documentação da Microsoft só permita de 1 a
30**: o tipo do recurso diz que a propriedade é um número e nada sobre a faixa, que vive no serviço.
A ajuda da CLI a informa, offline:

```
ana@laptop:~/azure$ az eventgrid event-subscription create --help | grep -A2 -E -- "--(max-delivery-attempts|event-ttl) "
    --event-ttl                                           : Event time to live (in minutes). Must be
                                                            a number between 1 and 1440.  Default:
                                                            1440.
--
    --max-delivery-attempts                               : Maximum number of delivery attempts.
                                                            Must be a number between 1 and 30.
                                                            Default: 30.
--
            --max-delivery-attempts 10 --event-ttl 120
```

Então os dois limites de uma retry policy têm uma cerca que o compilador não conhece: de 1 a 30
tentativas, e de 1 a 1440 minutos, um dia, para o time to live do evento. Implantar o arquivo é um
comando, não executado neste curso porque precisa de uma assinatura:

```sh
az deployment group create --resource-group shop-rg --template-file events.bicep --parameters reviewUrl="$REVIEW_URL"
```

## Empurrar, tentar de novo, dead-letter

**O Event Grid entrega pelo menos uma vez, e sem ordem garantida.** Ele posta o evento e espera 30
segundos por uma resposta. Um código de sucesso encerra o assunto. Uma falha, ou nenhuma resposta, põe
o evento num cronograma de novas tentativas. A documentação da Microsoft o dá como 10 segundos, 30
segundos, 1 minuto, 5, 10 e 30 minutos, 1, 3 e 6 horas, e depois a cada 12 horas até 24. Alguma
aleatoriedade é somada, e tentativas são puladas para um endpoint que parece doente. Algumas respostas nem
são tentadas de novo, porque tentar não adianta: para um webhook, 400, 401, 403 e 413.

Quando as tentativas ou o time to live acabam, o que vier primeiro, o evento vai para **dead-letter**
se a assinatura indicar um contêiner de blob para isso, cinco minutos depois da última tentativa, e é
descartado se não indicar. O dead-letter fica desligado até você ligá-lo, e é por isso que o
`events.bicep` o liga: um pedido acima de R$ 1.000,00 que ninguém revisou deve deixar um arquivo para
trás, não um silêncio. Uma consequência de tudo isso é a mesma de qualquer fila: um endpoint que
responde devagar pode receber o mesmo evento duas vezes, e a documentação diz isso com todas as
letras.

## O handshake

Um sistema que posta em qualquer endereço que lhe dão poderia ser apontado para o servidor de outra
pessoa, então o Event Grid pede a um webhook que prove que espera o tráfego antes de entregar
qualquer coisa. Com o schema do Event Grid, ele manda um
`Microsoft.EventGrid.SubscriptionValidationEvent` cujo `data` traz um `validationCode`, e o endpoint o
devolve como `{"validationResponse": "<the code>"}`. Um endpoint que não consegue responder assim
pode, em vez disso, abrir a `validationUrl` do mesmo evento em até dez minutos. Com CloudEvents, como
aqui, a verificação é a da própria especificação: uma requisição HTTP `OPTIONS` com um cabeçalho
`WebHook-Request-Origin`, que o endpoint responde com `WebHook-Allowed-Origin`.

**Uma Azure Function com trigger do Event Grid pula tudo isso**, e o mesmo vale para Logic Apps e
Azure Automation: o próprio Azure valida esses endpoints. Uma function app do tipo que a lição 15
construiu, com um trigger do Event Grid, é o caminho curto para um handler; uma aplicação web comum,
como a própria API da loja, precisa responder ao handshake no próprio código.

Mais dois destinos mudam o quadro. Uma assinatura pode entregar numa fila do Service Bus ou num
event hub em vez de num webhook. Isso põe o roteamento do Event Grid na frente de um consumidor que
recebe no próprio ritmo, com as travas e a dead-letter subqueue da primeira seção. E o Event Grid
também oferece **pull delivery**, para tópicos num namespace do Event Grid, em que o consumidor se
conecta e lê os eventos em vez de expor um endpoint; a loja não precisa disso.
