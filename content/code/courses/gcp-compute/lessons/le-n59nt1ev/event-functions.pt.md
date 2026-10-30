---
title: Funções de evento e o CloudEvent
version: 1
---

Uma função HTTP é chamada por alguém que quer uma resposta. **Uma função de evento é chamada porque
algo aconteceu, e ninguém está esperando o que ela devolve.** Um arquivo chegou num bucket, uma
mensagem chegou num tópico, uma linha mudou. O trabalho da função é reagir, e a única resposta dela
é se deu certo.

## O formato de um evento

O Google entrega todo evento a uma função num único formato: um **CloudEvent**, uma especificação
aberta da Cloud Native Computing Foundation. Um CloudEvent é um conjunto pequeno de atributos sobre
o que aconteceu mais os dados em si:

| atributo | o que diz | um exemplo |
|---|---|---|
| `id` | este evento, único para a sua origem | `7f3e-1042` |
| `source` | o que o produziu | `//shop/web` |
| `type` | que tipo de coisa aconteceu | `shop.order.created` |
| `specversion` | a versão da especificação | `1.0` |
| `time`, `subject` | opcionais: quando, e sobre o quê | |

Por HTTP os atributos viajam como cabeçalhos com o nome `ce-` mais o atributo, e os dados são o
corpo. Esse é o **modo de conteúdo binário**, e é o que a entrega de eventos do Google usa.

## Uma função que recebe um

**Crie `~/gcp/notify` e salve isto como `main.py` dentro dela:**

```python
# notify/main.py
import functions_framework


@functions_framework.cloud_event
def on_event(event):
    print(f"{event['type']} from {event['source']}, id {event['id']}", flush=True)
    print(f'data: {event.data}', flush=True)
```

O decorador desta vez é `cloud_event`, e a função recebe o evento e não devolve nada. O
`flush=True` faz cada linha chegar ao terminal na hora; no Google Cloud cada linha vira uma entrada
de log. Inicie-a no segundo terminal, parando antes a função de cotação se ela ainda estiver
rodando:

```
ana@laptop:~/gcp/notify$ functions-framework --target on_event --signature-type cloudevent
```

Nada no seu laptop produz os eventos do Google, então no primeiro terminal **o `curl` faz o papel
do remetente**: ele envia os cabeçalhos e o corpo que uma entrega carrega. É o curl, não o Google, e
o tipo do evento é um que a loja inventou:

```
ana@laptop:~/gcp/notify$ curl -s -w ' %{http_code}\n' localhost:8080 -H 'ce-specversion: 1.0' -H 'ce-type: shop.order.created' -H 'ce-source: //shop/web' -H 'ce-id: 7f3e-1042' -H 'content-type: application/json' -d '{"order": 1042, "total_cents": 14900}'
OK 200
ana@laptop:~/gcp/notify$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080 -H 'ce-specversion: 1.0' -H 'ce-type: shop.order.created' -H 'ce-source: //shop/web' -H 'content-type: application/json' -d '{"order": 1043}'
400
```

A primeira chamada levava todos os atributos, e o remetente recebeu `OK` e um 200, que é tudo que
um remetente fica sabendo. A segunda deixou de fora o `ce-id`, e recebeu um 400 com uma página HTML
explicando que nenhum CloudEvent pôde ser lido da requisição; o `-o /dev/null` esconde a página e
mantém o status. O que a função fez aparece só no terminal dela:

```
shop.order.created from //shop/web, id 7f3e-1042
data: {'order': 1042, 'total_cents': 14900}
```

O primeiro evento chegou inteiro: o tipo, a origem e o id vindos dos cabeçalhos, o corpo lido como
JSON porque o content type dizia isso. **A segunda requisição nunca chegou ao seu código**: sem id
não é um CloudEvent, e o framework a recusou antes de chamar a função, e é por isso que o terminal
dela mostra um evento e não dois.

## Sucesso é não lançar exceção

Para uma função de evento, **voltar normalmente significa sucesso e lançar uma exceção significa
falha**. O framework transforma o primeiro num 2xx e o segundo num 500, e no Google Cloud é esse
status que decide se o evento é entregue de novo. A seção 04 desta lição e toda a lição 18 se
apoiam nessa única regra, então vale dizer com todas as letras: capture um erro que você tratou, e
deixe escapar um que você não tratou.
