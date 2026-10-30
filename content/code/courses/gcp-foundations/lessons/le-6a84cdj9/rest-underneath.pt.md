---
title: O REST por baixo
version: 1
---

**Toda ferramenta deste curso é cliente das mesmas APIs.** O gcloud, o provider do Terraform, as bibliotecas
cliente e o console transformam o que você pediu em pedidos HTTP a `*.googleapis.com`, ou em gRPC, o irmão
binário dele, nos mesmos serviços. Cada API é um conjunto de recursos com nomes que parecem caminhos,
`projects/planner-dev/topics/orders`, e uns poucos verbos sobre eles. Ver os pedidos é o jeito mais rápido de
entender qualquer uma das ferramentas, e o gcloud os mostra.

## O gcloud, com os pedidos à mostra

O `--log-http` faz o gcloud imprimir todo pedido que manda e toda resposta que recebe. O log completo é longo,
quase todo cabeçalhos, então o `sed` guarda o endereço, o método, os corpos e o status:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders --log-http 2>&1 | sed -n '/^uri:/p;/^method:/p;/^== body start/,/^== body end/p;/^status:/p;/^-- body start/,/^-- body end/p'
uri: http://localhost:8085/v1/projects/planner-dev/topics/orders?alt=json
method: PUT
== body start ==
{"name": "projects/planner-dev/topics/orders"}
== body end ==
status: 200
-- body start --
{
  "name": "projects/planner-dev/topics/orders"
}

-- body end --
```

**Criar um tópico é um `PUT` do nome dele no próprio endereço dele.** O endereço é o nome do recurso sob `/v1/`, o
corpo é o recurso, e a resposta é o recurso como o servidor agora o guarda. Ele foi para `localhost:8085` porque a
lição 1 definiu `api_endpoint_overrides/pubsub`; sem essa propriedade, o mesmo pedido iria para
`https://pubsub.googleapis.com/v1/projects/planner-dev/topics/orders`.

## A mesma API, à mão

Com a forma conhecida, o `curl` faz o que o gcloud fez. Crie uma assinatura do mesmo jeito, um `PUT` de um recurso
cujo corpo nomeia o tópico:

```
ana@laptop:~/gcp$ curl -s -X PUT http://localhost:8085/v1/projects/planner-dev/subscriptions/orders-sub -H 'Content-Type: application/json' -d '{"topic": "projects/planner-dev/topics/orders"}'
{
  "name": "projects/planner-dev/subscriptions/orders-sub",
  "topic": "projects/planner-dev/topics/orders",
  "pushConfig": {
  },
  "ackDeadlineSeconds": 10,
  "messageRetentionDuration": "604800s"
}
```

A resposta tem campos que ninguém mandou, `ackDeadlineSeconds` e `messageRetentionDuration`, que são os padrões da
assinatura: a API preenche o que não foi dito, exatamente como os planos do Terraform mostravam com *known after
apply*.

Contra o Google, a única diferença é um cabeçalho, `Authorization: Bearer` e um token de acesso. Com o token de
mentira do laboratório:

```
ana@laptop:~/gcp$ curl -s https://pubsub.googleapis.com/v1/projects/planner-dev/topics -H "Authorization: Bearer $(cat ~/gcp/placeholder-token)"
{
  "error": {
    "code": 401,
    "message": "Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
    "status": "UNAUTHENTICATED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "CREDENTIALS_MISSING",
        "metadata": {
          "method": "google.pubsub.v1.Publisher.ListTopics",
          "service": "pubsub.googleapis.com"
        }
      }
    ]
  }
}
```

**Essa é a recusa que toda ferramenta deste curso citou**, sem ferramenta no meio: um erro em JSON com um código,
um status, e um `ErrorInfo` nomeando o serviço e o método, `google.pubsub.v1.Publisher.ListTopics`, que é o nome
gRPC do que o endereço REST chamou. Os erros do gcloud, os do Terraform e os das bibliotecas são esse corpo,
reescrito.
