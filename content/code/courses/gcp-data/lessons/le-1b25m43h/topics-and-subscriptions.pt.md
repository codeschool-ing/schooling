---
title: Um tópico, e uma assinatura para cada leitor
version: 1
---

**Um tópico do Pub/Sub não é uma fila, e não guarda nada para ninguém.** Um publicador manda uma
mensagem a um tópico; o tópico entrega uma cópia a cada **assinatura** (*subscription*) ligada a ele,
e a assinatura é onde a mensagem espera até um leitor dizer que já cuidou dela. Dois serviços que
precisam dos mesmos eventos ganham uma assinatura cada um, e cada um vê todas as mensagens, no seu
ritmo, com o seu próprio registro do que já terminou. Um serviço rodando em várias máquinas divide uma
assinatura só, e o Pub/Sub espalha as mensagens entre as máquinas. Esse é o modelo inteiro, e cada
configuração desta aula pertence a uma das duas metades.

O app da Quitanda manda eventos conforme os clientes usam: um produto visto, um carrinho cheio, um
pagamento feito. Dois serviços os leem. A **cobrança** precisa dos pagamentos e de mais nada, em
segundos, porque um pagamento que não foi registrado é um pedido que não foi separado. O **analytics**
quer tudo, e alimenta o warehouse das aulas 13 a 18. Um tópico, duas assinaturas.

## O emulador, num terminal só dele

O Google distribui um emulador do Pub/Sub como componente da linha de comando, e a aula 1 o instalou.
Abra um terminal para ele e inicie:

```sh
cd ~/gcp
export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud beta emulators pubsub start --project=planner-dev --host-port=localhost:8085
```

É um programa Java, leva alguns segundos para subir e imprime algumas linhas para cada requisição que
atende. Deixe rodando. **Ele guarda tudo na memória**, então `Ctrl+C` o esvazia, e esta aula começa
de um vazio. Você digita no terminal da aula 1, com as linhas de "Every time you open a terminal" já
nele: `CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB` manda o `gcloud pubsub` para a porta 8085, e
`PUBSUB_EMULATOR_HOST` faz o mesmo para a biblioteca Python.

## Um tópico, duas assinaturas

```
ana@laptop:~/gcp$ gcloud pubsub topics create app-events
Created topic [projects/planner-dev/topics/app-events].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create billing --topic=app-events --message-filter='attributes.type = "payment"'
Created subscription [projects/planner-dev/subscriptions/billing].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create analytics --topic=app-events
Created subscription [projects/planner-dev/subscriptions/analytics].
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe analytics
ackDeadlineSeconds: 10
messageRetentionDuration: 604800s
name: projects/planner-dev/subscriptions/analytics
pushConfig: {}
topic: projects/planner-dev/topics/app-events
```

**Todo nome é um caminho dentro do projeto**, `projects/planner-dev/topics/app-events`, e foi assim
que o emulador aceitou `planner-dev` sem conta nenhuma por trás. A descrição traz os dois padrões que
esta aula e a próxima mexem. `ackDeadlineSeconds: 10` é quanto tempo um leitor tem para confirmar uma
mensagem antes de o Pub/Sub entregá-la de novo, o assunto da aula 20.
`messageRetentionDuration: 604800s` são sete dias, quanto uma mensagem sem confirmação espera na
assinatura antes de ser jogada fora. `pushConfig: {}` diz que nada é empurrado: esta é uma assinatura
de **pull**, em que o leitor pede.

Os eventos vêm de um programa curto. Salve como `~/gcp/events.py` com o botão do bloco:

```schooling-example
{"language": "python", "file": "events.py", "parts": [{"code": "import json\n\nfrom google.cloud import pubsub_v1\n\npublisher = pubsub_v1.PublisherClient()\ntopic = publisher.topic_path('planner-dev', 'app-events')\n\n", "note": "O `PublisherClient` acha o emulador pelo `PUBSUB_EMULATOR_HOST`, que o terminal exportou, e não manda credencial nenhuma para ele. `topic_path` só monta o nome `projects/planner-dev/topics/app-events`; não pergunta nada ao servidor."}, {"code": "EVENTS = [\n    ('c-17', 'view', {'product': 'banana-prata'}),\n    ('c-02', 'view', {'product': 'tomate'}),\n    ('c-17', 'add_to_cart', {'product': 'banana-prata', 'qty': 6}),\n    ('c-17', 'payment', {'order_id': 'o-301', 'cents': 4590}),\n    ('c-05', 'search', {'text': 'manga'}),\n    ('c-02', 'add_to_cart', {'product': 'tomate', 'qty': 2}),\n    ('c-02', 'payment', {'order_id': 'o-302', 'cents': 12800}),\n    ('c-05', 'view', {'product': 'manga-palmer'}),\n]\n\n", "note": "Oito eventos do app da Quitanda: o que três clientes olharam, puseram no carrinho e pagaram. Dois deles são pagamentos, que é o que interessa ao serviço de cobrança."}, {"code": "futures = []\nfor customer, kind, body in EVENTS:\n    data = json.dumps(body).encode()\n    futures.append(publisher.publish(topic, data, type=kind, customer_id=customer))\n\n", "note": "**O corpo é bytes e os atributos são strings.** O Pub/Sub nunca olha dentro de `data`; os argumentos nomeados viram atributos, que ele lê, e um filtro pode selecionar por eles. `publish` volta na hora com um future, porque o cliente junta as mensagens em lotes antes de mandar."}, {"code": "for (customer, kind, _), future in zip(EVENTS, futures):\n    print(f'id {future.result():>3}  {kind:<12} {customer}')\n", "note": "`result()` espera a resposta do servidor, que é o **id da mensagem** que ele atribuiu. Uma mensagem está publicada quando esse id volta, e não antes."}]}
```

```
ana@laptop:~/gcp$ python3 events.py
id   1  view         c-17
id   2  view         c-02
id   3  add_to_cart  c-17
id   4  payment      c-17
id   5  search       c-05
id   6  add_to_cart  c-02
id   7  payment      c-02
id   8  view         c-05
```

**O emulador numera as mensagens 1, 2, 3, e o Google não.** No serviço de verdade, um id de mensagem
é uma string longa de dígitos, única dentro do tópico, sem ordem nenhuma. Código que ordena por id de
mensagem, ou o lê como contagem, funciona aqui e em nenhum outro lugar.

Agora cada assinatura é lida uma vez. `--auto-ack` confirma o que puxa, e `--format` deixa três
colunas da tabela larga que o `gcloud` imprime por padrão:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull analytics --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,message.attributes.customer_id:label=CUSTOMER)'
ID  TYPE         CUSTOMER
1   view         c-17
2   view         c-02
3   add_to_cart  c-17
4   payment      c-17
5   search       c-05
6   add_to_cart  c-02
7   payment      c-02
8   view         c-05
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull billing --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,message.attributes.customer_id:label=CUSTOMER)'
ID  TYPE     CUSTOMER
4   payment  c-17
7   payment  c-02
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull analytics --auto-ack --limit=20
Listed 0 items.
```

**Uma publicação, duas entregas.** `analytics` recebeu os oito eventos e `billing` recebeu os dois
pagamentos, as mesmas mensagens com os mesmos ids 4 e 7. Confirmá-las em `analytics` as tirou só de
`analytics`, e é por isso que o terceiro pull voltou vazio enquanto os pagamentos já tinham saído de
`billing` por conta própria. Nenhuma assinatura sabe que a outra existe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O publicador events.py manda oito mensagens ao tópico app-events. O tópico entrega uma cópia a cada uma de duas assinaturas. billing tem o filtro attributes.type = &quot;payment&quot; e recebe os ids 4 e 7; analytics não tem filtro e recebe os ids 1 a 8. O serviço de cobrança lê billing e o job de análise lê analytics, e o ack numa assinatura não mexe na outra.\" data-fig=\"l19-fanout\"><rect x=\"20.0\" y=\"95.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.py</text><text x=\"75.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">publicador</text><line x1=\"132.0\" y1=\"115.0\" x2=\"182.0\" y2=\"115.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,115.0 182.0,118.0 182.0,112.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"190.0\" y=\"95.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-events</text><text x=\"250.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tópico</text><line x1=\"312.0\" y1=\"108.0\" x2=\"392.9\" y2=\"58.1\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,55.0 394.5,60.7 391.3,55.6\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"312.0\" y1=\"122.0\" x2=\"392.9\" y2=\"171.9\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,175.0 391.3,174.4 394.5,169.3\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"400.0\" y=\"30.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">billing</text><text x=\"470.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ids 4, 7</text><text x=\"470.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">attributes.type = &quot;payment&quot;</text><rect x=\"400.0\" y=\"150.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">analytics</text><text x=\"470.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ids 1 to 8</text><line x1=\"542.0\" y1=\"55.0\" x2=\"582.0\" y2=\"55.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"588.0,55.0 582.0,58.0 582.0,52.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"542.0\" y1=\"175.0\" x2=\"582.0\" y2=\"175.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"588.0,175.0 582.0,178.0 582.0,172.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"590.0\" y=\"35.0\" width=\"115.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">serviço de cobrança</text><rect x=\"590.0\" y=\"155.0\" width=\"115.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">job de análise</text><text x=\"470.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">duas assinaturas</text><text x=\"470.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cada uma guarda a sua cópia até o ack</text><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o ack numa assinatura não mexe na outra</text></svg>", "caption": "Um tópico, uma cópia por assinatura, e um filtro decidindo o que cada assinatura recebe."}
```

## Um filtro decide o que uma assinatura recebe

`billing` foi criada com `--message-filter='attributes.type = "payment"'`, e os seis eventos que não
eram pagamentos nunca chegaram a ela. **Um filtro lê atributos, nunca o corpo.** O Pub/Sub não
interpreta `data`, então o publicador precisa pôr nos atributos tudo aquilo por que um leitor possa
querer selecionar, e é por isso que o `events.py` manda `type` e `customer_id` ali. A linguagem é
pequena: `=` e `!=` num atributo, `:` para "tem este atributo", `hasPrefix()`, e `AND`, `OR` e `NOT`
para combinar. `attributes.type = "payment" OR attributes.type = "refund"` é um filtro para onde a
cobrança pode crescer.

**Um filtro é escrito quando a assinatura é criada.** `gcloud pubsub subscriptions update` não tem
flag para ele, e o emulador recusa a chamada de API de vez, numa mensagem que se identifica:
"Updating the filter field is currently unsupported in the Pub/Sub Emulator". Mudar o que a cobrança
lê significa uma assinatura nova e uma troca da antiga. E uma mensagem que um filtro recusa não sai de
graça: a página de preços do Google diz que o Pub/Sub a confirma sozinho e cobra a entrega mesmo
assim, e a última seção desta aula põe um número nisso.

## Uma assinatura começa quando é criada

Uma checagem de fraude, acrescentada uma semana depois do lançamento, também quer os eventos do app:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions create fraud --topic=app-events
Created subscription [projects/planner-dev/subscriptions/fraud].
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull fraud --auto-ack --limit=20
Listed 0 items.
ana@laptop:~/gcp$ gcloud pubsub subscriptions delete fraud
Deleted subscription [projects/planner-dev/subscriptions/fraud].
```

**Uma assinatura nova recebe o que é publicado depois que ela existe, e nada de antes.** Os oito
eventos já tinham sido entregues às duas assinaturas que existiam então, e o tópico em si não guardou
nenhum, então não havia nada para dar a `fraud`. Uma mensagem publicada num tópico sem assinatura
nenhuma é aceita, ganha um id, e ninguém a guarda. A quarta seção mostra a configuração que muda isso,
a retenção no tópico, e a leitura que o próprio emulador faz dela está na quinta. `fraud` é apagada,
porque uma assinatura que ninguém lê fica juntando mensagens por sete dias e depois as joga fora, e no
serviço de verdade, segundo o Google, uma que ninguém lê por 31 dias se apaga sozinha, a não ser que a
expiração dela seja `never`.
