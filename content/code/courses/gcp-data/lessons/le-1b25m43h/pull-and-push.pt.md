---
title: Pull, push, e o ack
version: 1
---

**Uma mensagem fica numa assinatura até ser confirmada, e ler não é confirmar.** Puxar uma mensagem a
empresta ao leitor pelo prazo de ack (*ack deadline*), dez segundos por padrão. Se o leitor confirma
dentro desse tempo, a assinatura esquece a mensagem; se não confirma, a mensagem volta para a
assinatura e é entregue de novo. O Pub/Sub tem dois jeitos de entregar, e eles diferem em quem abre a
conexão. Numa assinatura de **pull**, o leitor pede mensagens. Numa assinatura de **push**, o Pub/Sub
manda cada mensagem como uma requisição HTTP para um endereço que a assinatura indica, e a resposta é
o ack.

## Puxando, e confirmando à mão

O `--auto-ack` escondeu a confirmação na seção anterior. Sem ele, o `gcloud` imprime o **ack id** de
cada mensagem, a alça que confirma esta entrega dela:

```
ana@laptop:~/gcp$ python3 events.py > /dev/null
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull analytics --limit=2 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,ackId)'
ID  TYPE  ACK_ID
9   view  projects/planner-dev/subscriptions/analytics:11
10  view  projects/planner-dev/subscriptions/analytics:12
ana@laptop:~/gcp$ gcloud pubsub subscriptions ack analytics --ack-ids=projects/planner-dev/subscriptions/analytics:11
Acked the messages with the following ackIds: [projects/planner-dev/subscriptions/analytics:11]
{}
```

**A mensagem 9 está confirmada, e a 10 está só emprestada.** Um ack id nomeia uma entrega, não a
mensagem: se a mensagem 10 for entregue de novo, vem com um novo, e a alça antiga não confirma mais
nada. Os ack ids do emulador terminam num contador; no serviço de verdade são strings longas e opacas.
A aula 20 deixa um prazo acabar de propósito e acompanha o que volta.

## Um streaming pull

O `gcloud` pede uma vez e imprime o que recebeu, o que é certo para olhar e errado para um serviço. Um
consumidor mantém uma conexão aberta e recebe as mensagens por ela conforme chegam, um **streaming
pull**, e a biblioteca cliente faz o trabalho. Salve como `~/gcp/subscriber.py`:

```schooling-example
{"language": "python", "file": "subscriber.py", "parts": [{"code": "import sys\nimport threading\nfrom concurrent.futures import TimeoutError\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', sys.argv[1])\nlock = threading.Lock()\n\n", "note": "A assinatura vem da linha de comando, então o mesmo programa lê `analytics` aqui e qualquer outra mais adiante."}, {"code": "def callback(message):\n    kind = message.attributes.get('type', '-')\n    with lock:\n        print(f'id {message.message_id:>3}  {kind:<12} {message.data.decode()}')\n    message.ack()\n\n\n", "note": "**O callback roda uma vez por mensagem, num conjunto de threads**, e é por isso que o print pega um lock: sem ele, duas linhas podem cair numa só. `ack()` diz ao Pub/Sub que esta assinatura terminou com a mensagem."}, {"code": "future = subscriber.subscribe(path, callback=callback)\nwith subscriber:\n    try:\n        future.result(timeout=5)\n    except TimeoutError:\n        future.cancel()\n        future.result()\n", "note": "`subscribe` abre um **streaming pull**: uma conexão longa pela qual o servidor manda as mensagens conforme chegam. Um consumidor de verdade espera em `future.result()` para sempre; este para depois de cinco segundos, para poder ser rodado e lido."}]}
```

```
ana@laptop:~/gcp$ python3 subscriber.py analytics
id  11  add_to_cart  {"product": "banana-prata", "qty": 6}
id  12  payment      {"order_id": "o-301", "cents": 4590}
id  13  search       {"text": "manga"}
id  16  view         {"product": "manga-palmer"}
id  15  payment      {"order_id": "o-302", "cents": 12800}
id  14  add_to_cart  {"product": "tomate", "qty": 2}
```

**Vieram seis das oito, e a mensagem 10 não**: ela ainda estava emprestada ao pull do `gcloud` acima,
cujo prazo não tinha acabado quando o programa começou. Nada promete a ordem das seis, também. Os
callbacks rodam em várias threads, então uma execução pode imprimir 16 antes de 14, e a próxima seção é
sobre a única configuração que devolve a ordem. A biblioteca cliente também faz algo que o `gcloud` não
faz: **enquanto um callback ainda trabalha numa mensagem, a biblioteca estende o prazo dela sozinha**, e
por padrão continua estendendo por até uma hora. Um callback lento, então, não causa nova entrega; um
processo morto causa, e é isso que a aula 20 encena.

## Push

Uma assinatura de push precisa de um endereço que o Pub/Sub alcance. No Google é um endereço HTTPS na
internet, quase sempre um serviço do Cloud Run; aqui é um servidorzinho na porta 8099 do mesmo
laptop. Salve como `~/gcp/receiver.py`:

```schooling-example
{"language": "python", "file": "receiver.py", "parts": [{"code": "import base64\nimport json\nimport time\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\nFAIL_FIRST = 2\ncalls = []\n\n\n", "note": "Um endpoint HTTP da biblioteca padrão do Python, no lugar do serviço que a Quitanda rodaria atrás de um endereço público. `FAIL_FIRST` faz ele responder as duas primeiras requisições com erro, como um serviço faz enquanto reinicia."}, {"code": "class Push(BaseHTTPRequestHandler):\n    def do_POST(self):\n        body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))\n        message = body['message']\n", "note": "**Uma requisição de push é um POST cujo corpo embrulha a mensagem em JSON**, com o nome da assinatura ao lado."}, {"code": "        calls.append(time.time())\n        status = 503 if len(calls) <= FAIL_FIRST else 204\n        data = base64.b64decode(message['data']).decode()\n        print(f\"+{calls[-1] - calls[0]:4.1f}s  {status}  id {message['messageId']}  {data}\", flush=True)\n        self.send_response(status)\n        self.end_headers()\n\n", "note": "O código de status é o ack. **Uma resposta 2xx confirma a mensagem; qualquer outra, ou nenhuma a tempo, é um nack**, e o Pub/Sub manda de novo. Os dados chegam em base64, como em toda forma JSON de uma mensagem."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nHTTPServer(('localhost', 8099), Push).serve_forever()\n", "note": "`log_message` cala a linha que o próprio servidor imprime por requisição, para só a linha do programa aparecer."}]}
```

O `&` no fim da segunda linha roda o receptor em segundo plano neste mesmo terminal, e o `push.log`
junta o que ele imprime:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions create pushed --topic=app-events --push-endpoint=http://localhost:8099/
Created subscription [projects/planner-dev/subscriptions/pushed].
ana@laptop:~/gcp$ python3 receiver.py > push.log 2>&1 &
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message='{"order_id": "o-303", "cents": 990}' --attribute=type=payment,customer_id=c-17
messageIds:
- '17'
ana@laptop:~/gcp$ cat push.log
+ 0.0s  503  id 17  {"order_id": "o-303", "cents": 990}
+ 1.0s  503  id 17  {"order_id": "o-303", "cents": 990}
+ 2.0s  204  id 17  {"order_id": "o-303", "cents": 990}
ana@laptop:~/gcp$ gcloud pubsub subscriptions delete pushed
Deleted subscription [projects/planner-dev/subscriptions/pushed].
```

**O receptor respondeu 503 duas vezes, e o Pub/Sub mandou a mesma mensagem uma segunda e uma terceira
vez**, com o mesmo id 17, até um 204 confirmá-la. Nada no `receiver.py` pediu as novas tentativas; o
código de status foi a conversa inteira. O emulador tentou de novo mais ou menos a cada segundo. O
Google documenta que o serviço, em vez disso, recua, mandando com menos frequência enquanto um endpoint
continua falhando, e a política de nova tentativa (*retry policy*) de uma assinatura de push define os
limites desse recuo. Digite `kill %1` para parar o receptor depois que a assinatura for apagada.

**A escolha entre os dois é sobre quem segura a conexão.** O pull serve a um worker que roda o tempo
todo e decide o próprio ritmo, e é o único tipo que pode ser lido pelo `gcloud`, por um job em lote ou
pelo Dataflow na aula 21. O push serve a um serviço que já responde HTTP e não deveria deixar um
processo esperando numa assinatura, e entrega a escala a quem roda o endpoint. No serviço de verdade,
uma assinatura de push pode assinar cada requisição com um token de uma conta de serviço, a flag
`--push-auth-service-account` na ajuda do `gcloud`, e o endpoint então o confere. O emulador não
assina nada, então essa parte do push não é praticada aqui.

Há mais dois tipos, que entregam num produto do Google e não a um código seu: uma **assinatura do
BigQuery** grava cada mensagem como uma linha de uma tabela, e uma **assinatura do Cloud Storage**
junta mensagens em arquivos num bucket. São o caminho pelo qual os eventos de analytics da Quitanda
poderiam chegar ao warehouse sem consumidor nenhum. O emulador aceita as duas e não entrega em
nenhuma, como mostra a última seção.
