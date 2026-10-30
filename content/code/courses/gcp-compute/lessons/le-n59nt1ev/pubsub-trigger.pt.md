---
title: Um gatilho de Pub/Sub, de ponta a ponta
version: 1
---

Um gatilho de Pub/Sub soa como se a função escutasse o tópico. **Não escuta: o Pub/Sub empurra cada
mensagem para a função por HTTP**, por uma assinatura de push que o Google cria para você quando
você publica uma função com esse gatilho. A função é um endpoint HTTP o tempo todo, e o gatilho é
uma assinatura apontada para ela. Com isso claro, a cadeia inteira roda no seu laptop com o
emulador de Pub/Sub do próprio Google.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma mensagem vai da esquerda para a direita. O publicador, pubsub.py, manda dados e atributos para o tópico orders. O tópico guarda uma cópia para cada assinatura. A assinatura de push orders-fn manda a sua cópia como um POST HTTP para o endpoint. Lá, o Functions Framework transforma o corpo do push num CloudEvent e chama on_order com ele. O tópico e a assinatura ficam dentro do emulador do Pub/Sub.\"><defs><marker id=\"f17chain-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"178\" y=\"22\" width=\"336\" height=\"188\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"346\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o emulador do Pub/Sub</text><rect x=\"12\" y=\"60\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">publicador</text><text x=\"82\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">pubsub.py</text><text x=\"82\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dados e</text><text x=\"82\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atributos</text><rect x=\"190\" y=\"60\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">tópico</text><text x=\"260\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">orders</text><text x=\"260\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma cópia para</text><text x=\"260\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada assinatura</text><rect x=\"362\" y=\"60\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"432\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">assinatura de push</text><text x=\"432\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">orders-fn</text><text x=\"432\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um POST para</text><text x=\"432\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endpoint</text><rect x=\"540\" y=\"60\" width=\"168\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"624\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Functions Framework</text><rect x=\"552\" y=\"98\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"624\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o corpo do push</text><text x=\"624\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vira um CloudEvent</text><rect x=\"552\" y=\"148\" width=\"144\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"624\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">on_order(event)</text><path d=\"M152 125 L188 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f17chain-phosphor)\"></path><path d=\"M330 125 L360 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f17chain-phosphor)\"></path><path d=\"M502 125 L538 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f17chain-phosphor)\"></path></svg>", "caption": "Ninguém escuta o tópico. A assinatura empurra cada mensagem para a função por HTTP, e o framework transforma o push no CloudEvent que o seu código recebe.", "same": ["Functions Framework"]}
```
## Iniciando o emulador

O emulador está na imagem que você baixou na lição 1. **Inicie-o em segundo plano**, na rede da
própria máquina, para ele alcançar uma função em `localhost`:

```
ana@laptop:~/gcp$ docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev
3bdd3d2bec700689b7c8152f38c65b2ac598aa1666add1bb03f8cb03a94dafb5
```

A linha hexadecimal comprida é o id do contêiner, e o seu vai ser outro. O emulador leva alguns
segundos para subir; `docker logs pubsub` mostra `Server started, listening on 8085` quando ele
está pronto. Ele guarda tudo na memória, então `docker rm -f pubsub` o esvazia, e é assim que
começa toda lição que o usa.

## Falando com ele

O gcloud recusa todo comando `pubsub` sem conta, com emulador ou sem, então o curso usa um programa
curto feito com a biblioteca cliente do Google. **Salve-o como `~/gcp/pubsub.py`**; as lições 18 e
20 também o usam:

```schooling-example
{"language": "python", "file": "pubsub.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"A small command line for the Pub/Sub emulator, for lessons 17, 18 and 20.\n\ngcloud refuses every Pub/Sub command without an account, emulator or not, so\nthis does the same few things with Google's own client library, which talks\nto whatever PUBSUB_EMULATOR_HOST names and needs no credentials there.\n\n    python3 pubsub.py topic NAME\n    python3 pubsub.py push NAME TOPIC URL     # a push subscription\n    python3 pubsub.py sub NAME TOPIC          # a pull subscription\n    python3 pubsub.py publish TOPIC DATA [KEY=VALUE ...]\n    python3 pubsub.py pull NAME               # print and acknowledge\n\"\"\"\n", "note": "A docstring diz por que isto existe: o gcloud não fala com o emulador sem conta, e a biblioteca cliente do Google fala, sem credencial nenhuma."}, {"code": "import os\nimport sys\n\nfrom google.cloud import pubsub_v1\n\nPROJECT = os.environ.get('CLOUDSDK_CORE_PROJECT', 'planner-dev')\n\n", "note": "A biblioteca de Pub/Sub do Google, instalada na lição 1. O projeto vem da variável que todo terminal do curso define."}, {"code": "def main():\n    if 'PUBSUB_EMULATOR_HOST' not in os.environ:\n        sys.exit('PUBSUB_EMULATOR_HOST is not set: this would talk to the real Pub/Sub')\n    cmd, args = sys.argv[1], sys.argv[2:]\n    pub, sub = pubsub_v1.PublisherClient(), pubsub_v1.SubscriberClient()\n    topic = lambda name: pub.topic_path(PROJECT, name)\n", "note": "A trava. Sem `PUBSUB_EMULATOR_HOST` a mesma biblioteca iria ao Pub/Sub real, então o programa se recusa a rodar."}, {"code": "    if cmd == 'topic':\n        print(pub.create_topic(name=topic(args[0])).name)\n    elif cmd in ('push', 'sub'):\n        push = {'push_endpoint': args[2]} if cmd == 'push' else None\n        s = sub.create_subscription(name=sub.subscription_path(PROJECT, args[0]),\n                                    topic=topic(args[1]), push_config=push)\n        print(s.name, '->', s.push_config.push_endpoint or 'pull')\n", "note": "Um tópico é um nome. Uma assinatura é um nome, um tópico e um endpoint de push ou nada, o que a torna uma assinatura de pull."}, {"code": "    elif cmd == 'publish':\n        attrs = dict(a.split('=', 1) for a in args[2:])\n        print('message', pub.publish(topic(args[0]), args[1].encode(), **attrs).result())\n", "note": "Publicar: os dados são bytes, e o que vier depois na forma `CHAVE=VALOR` vira atributo da mensagem. O `.result()` espera o id da mensagem."}, {"code": "    elif cmd == 'pull':\n        path = sub.subscription_path(PROJECT, args[0])\n        got = sub.pull(subscription=path, max_messages=10, timeout=5).received_messages\n        for m in got:\n            print(m.message.message_id, m.message.data.decode(), dict(m.message.attributes))\n        if got:\n            sub.acknowledge(subscription=path, ack_ids=[m.ack_id for m in got])\n        print(len(got), 'message(s)')\n\nif __name__ == '__main__':\n    main()\n", "note": "Puxar: até dez mensagens, impressas com os atributos, depois confirmadas para não serem entregues de novo."}]}
```

A biblioteca procura uma variável, e é essa variável que mantém tudo isto no seu laptop.
**Exporte-a no terminal que você usa para o emulador**:

```sh
export PUBSUB_EMULATOR_HOST=localhost:8085
```

## A função

Uma mensagem do Pub/Sub chega dentro dos dados do CloudEvent, sob `message`, com o conteúdo
codificado em base64 e os atributos ao lado. **Crie `~/gcp/orders-events` e salve isto como
`main.py` dentro dela:**

```python
# orders-events/main.py
import base64

import functions_framework


@functions_framework.cloud_event
def on_order(event):
    message = event.data['message']
    order = base64.b64decode(message['data']).decode()
    source = message.get('attributes', {}).get('source', '?')
    print(f'order {order} from {source}, event {event["id"]}', flush=True)
```

Inicie-a no segundo terminal:

```
ana@laptop:~/gcp/orders-events$ functions-framework --target on_order --signature-type cloudevent
```

## A cadeia

No primeiro terminal, um tópico, uma assinatura de push apontada para a função e uma mensagem:

```
ana@laptop:~/gcp$ python3 pubsub.py topic orders
projects/planner-dev/topics/orders
ana@laptop:~/gcp$ python3 pubsub.py push orders-fn orders http://localhost:8080/
projects/planner-dev/subscriptions/orders-fn -> http://localhost:8080/
ana@laptop:~/gcp$ python3 pubsub.py publish orders 1042 source=web
message 1
```

E no terminal da função, um instante depois:

```
order 1042 from web, event 1
```

**Nada chamou a função diretamente.** A mensagem foi para o tópico, a assinatura de push a entregou
como um `POST` HTTP, e o framework reconheceu um push do Pub/Sub e entregou ao seu código um
CloudEvent com o atributo que você definiu. No Google Cloud a entrega tem mais um passo, um token
de identidade que prova que quem chama é o Pub/Sub, e o tópico, a assinatura e a função moram no
seu projeto, não num contêiner. O formato é o que você acabou de rodar.

Quando terminar, `docker rm -f pubsub` para o emulador e esquece o tópico.
