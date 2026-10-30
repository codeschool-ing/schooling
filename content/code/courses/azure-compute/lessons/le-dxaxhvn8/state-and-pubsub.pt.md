---
title: Estado e pub/sub, pelo sidecar
version: 1
---

Um componente é um arquivo YAML curto com um nome, um tipo e as configurações desse tipo. **O nome é
o que o código diz, e o tipo é aquilo a que o sidecar se conecta.** A URL `/v1.0/state/statestore`
nomeia um componente chamado `statestore`; se ele é Redis, Cosmos DB ou uma tabela em algum lugar
está escrito no arquivo e em nenhum ponto do programa. Esta seção dá ao sidecar da loja dois
componentes, um armazenamento de estado e um broker de mensagens, os dois no Redis, e usa cada um.
Ela é praticada por inteiro.

É fácil sair daqui achando que o sidecar guarda o estado ou segura as mensagens. Ele não guarda
nada. Quem guarda é o Redis, e o sidecar é um cliente do Redis com a API do Dapr na frente. O que
o sidecar acrescenta é o formato do pedido e o arranjo do que vai parar no Redis, e os dois
aparecem abaixo.

## Dois componentes

O Redis entra na mesma rede da loja, com o nome `redis`, que é como o sidecar vai encontrá-lo:

```
ana@laptop:~/azure$ docker run -d --name redis --network shop-net redis:8-alpine > /dev/null
```

Salve o armazenamento de estado como `~/azure/components/statestore.yaml`:

```yaml
# components/statestore.yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis:6379
```

e o broker como `~/azure/components/pubsub.yaml`:

```yaml
# components/pubsub.yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis:6379
```

Os dois arquivos diferem no `name` e no `type` e em mais nada. `state.redis` guarda valores no
Redis; `pubsub.redis` usa os streams do Redis como broker. A lista `metadata` leva o que o tipo
precisar, aqui só o endereço. `redis:6379` é resolvido na `shop-net`, e dentro do sidecar
`localhost` seria a loja.

Este sidecar lê os componentes quando inicia, então ele é substituído, não avisado:

```
ana@laptop:~/azure$ ls components
pubsub.yaml
statestore.yaml
ana@laptop:~/azure$ docker rm -f shop-dapr > /dev/null
ana@laptop:~/azure$ docker run -d --name shop-dapr --network container:shop -v ~/azure/components:/components daprio/daprd:1.17.16 ./daprd --app-id shop --app-port 8080 --resources-path /components > /dev/null
ana@laptop:~/azure$ docker logs shop-dapr 2>&1 | grep -o 'msg="Component loaded[^"]*"'
msg="Component loaded: pubsub (pubsub.redis/v1)"
msg="Component loaded: statestore (state.redis/v1)"
ana@laptop:~/azure$ docker logs shop | tail -n 2
{"path": "/dapr/config", "status": "404", "version": "1.0"}
{"path": "/dapr/subscribe", "status": "404", "version": "1.0"}
```

Os dois componentes carregaram, e o log da loja tem uma linha que não tinha antes. Com um broker
carregado, o sidecar perguntou ao app o que ele assina, e a loja respondeu 404: ela não assina
nada, o que está certo.

## Estado

Guardar é um POST de uma lista de chaves e valores; ler é um GET de uma chave:

```
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{"key": "order-1", "value": {"item": "coffee", "qty": 2}}]'
204
ana@laptop:~/azure$ curl -s -w '\n' localhost:3500/v1.0/state/statestore/order-1
{"item":"coffee","qty":2}
```

Agora olhe o próprio Redis, com quem a loja nunca falou:

```
ana@laptop:~/azure$ docker exec redis redis-cli KEYS '*'
shop||order-1
ana@laptop:~/azure$ docker exec redis redis-cli HGETALL 'shop||order-1'
data
{"item":"coffee","qty":2}
version
1
```

**A chave no Redis não é `order-1`. É `shop||order-1`, com o app id na frente**, e o valor é um hash
com os dados e uma versão. O prefixo é o que permite a dois apps dividir um armazenamento sem ler as
chaves um do outro, como o fim desta seção mostra. Ele também quer dizer que este Redis agora
guarda dados no formato do Dapr, e a seção 05 volta ao que isso custa.

A versão é a proteção do armazenamento contra dois escritores. O Dapr a entrega como ETag; uma
escrita que leva uma só funciona se ela ainda bater:

```
ana@laptop:~/azure$ curl -s -D - -o /dev/null localhost:3500/v1.0/state/statestore/order-1 | grep -i etag
Etag: 1
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{"key": "order-1", "value": {"item": "coffee", "qty": 3}, "etag": "1"}]'
204
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -o err.json -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{"key": "order-1", "value": {"item": "coffee", "qty": 5}, "etag": "1"}]'
409
ana@laptop:~/azure$ jq -r .errorCode err.json
ERR_STATE_SAVE
ana@laptop:~/azure$ curl -s -w '\n' localhost:3500/v1.0/state/statestore/order-1
{"item":"coffee","qty":3}
```

A primeira escrita levou o ETag 1, bateu e passou a versão para 2. A segunda levou o mesmo 1, já
vencido, e foi recusada com 409, então a quantidade 5 nunca entrou e o valor continua 3. O Dapr
chama isso de first-write-wins. Uma escrita sem ETag nunca é recusada, então vale a última: esse é
o padrão, e a documentação manda você presumir que é ele.

## Publicar e assinar

Um assinante é qualquer programa que responda a duas coisas: uma lista do que ele assina e um POST
para cada mensagem. Salve isto como `~/azure/subscriber.py`:

```schooling-example
{"language": "python", "file": "subscriber.py", "parts": [{"code": "# subscriber.py\nimport json\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\n", "note": "De novo só a biblioteca padrão, como na loja: a imagem em que ele roda não precisa de nada do PyPI, e nada no arquivo é do Dapr."}, {"code": "SUBSCRIPTIONS = [{'pubsubname': 'pubsub', 'topic': 'orders', 'route': '/orders'}]\n\n\n", "note": "A assinatura, como dado. Ela nomeia o componente (`pubsub`), o tópico e o caminho neste programa onde o sidecar deve entregar cada mensagem. Nada aqui diz Redis ou Service Bus."}, {"code": "class Subscriber(BaseHTTPRequestHandler):\n    def answer(self, body):\n        data = json.dumps(body).encode()\n        self.send_response(200)\n        self.send_header('Content-Type', 'application/json')\n        self.send_header('Content-Length', str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n", "note": "Toda resposta sai como JSON com o tamanho declarado, o mesmo auxiliar da loja."}, {"code": "    def do_GET(self):\n        if self.path == '/dapr/subscribe':\n            self.answer(SUBSCRIPTIONS)\n        else:\n            self.send_error(404)\n\n", "note": "O sidecar pede `GET /dapr/subscribe` uma vez, ao iniciar, e assina em nome do app o que vier na resposta. Qualquer outra página é um 404, que é também o que o sidecar recebe quando pede `/dapr/config`."}, {"code": "    def do_POST(self):\n        size = int(self.headers.get('Content-Length', 0))\n        event = json.loads(self.rfile.read(size))\n        print(json.dumps({'order': event['data'], 'from': event['source'],\n                          'type': event['type']}), flush=True)\n        self.answer({'status': 'SUCCESS'})\n\n", "note": "Uma entrega chega como um POST na rota. O corpo é um CloudEvent: o pedido que o publicador mandou está em `data`, o app id do publicador em `source`. A resposta `SUCCESS` diz ao sidecar que a mensagem está resolvida."}, {"code": "    def log_message(self, fmt, *args):\n        pass\n\n\n", "note": "A linha que a biblioteca padrão escreve por requisição é silenciada, para o log ter só o que foi recebido."}, {"code": "if __name__ == '__main__':\n    HTTPServer(('0.0.0.0', 8080), Subscriber).serve_forever()\n", "note": "Ele escuta na 8080, a mesma porta da loja. Não há conflito: cada cópia roda num namespace próprio, com o seu próprio `localhost`."}]}
```

Duas equipes da loja precisam de todo pedido: o billing, para cobrar, e o audit, para registrar. O
mesmo arquivo faz o papel dos dois. Cada um roda num contêiner próprio, a partir de
`python:3.12-slim`, como o usuário `nobody`, com o seu próprio sidecar e o seu próprio app id:

```
ana@laptop:~/azure$ for app in billing audit; do docker run -d --name $app --user nobody --network shop-net -v ~/azure/subscriber.py:/subscriber.py:ro python:3.12-slim python /subscriber.py > /dev/null; done
ana@laptop:~/azure$ for app in billing audit; do docker run -d --name $app-dapr --network container:$app -v ~/azure/components:/components daprio/daprd:1.17.16 ./daprd --app-id $app --app-port 8080 --resources-path /components > /dev/null; done
ana@laptop:~/azure$ docker logs billing-dapr 2>&1 | grep -o 'msg="app is subscribed[^"]*"'
msg="app is subscribed to the following topics: [[orders]] through pubsub=pubsub"
```

O sidecar leu `/dapr/subscribe` e assinou `orders` para o `billing` pelo componente chamado
`pubsub`. Agora o lado da loja publica um pedido. O código da loja não publica, então o `curl` no
laptop faz o papel da linha que uma versão futura da loja levaria; o pedido é o mesmo nos dois
casos:

```
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{"id": 1, "item": "coffee", "qty": 2}'
204
ana@laptop:~/azure$ docker logs billing
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
ana@laptop:~/azure$ docker logs audit
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
```

`204` quer dizer que o broker aceitou. Os dois assinantes imprimiram o pedido, e o envelope em volta
diz quem mandou: `from` é `shop`, o app id do publicador, e `type` é `com.dapr.event.sent`. **O Dapr
embrulha toda mensagem publicada num CloudEvent**, um formato aberto para descrever um evento, e
põe o que você mandou em `data`. Um assinante que responde `SUCCESS` terminou com a mensagem;
`RETRY` pede que ela venha de novo e `DROP` a descarta, e um app que responde 404 tem a mensagem
descartada com um erro no log do sidecar.

O que isso fez no Redis:

```
ana@laptop:~/azure$ docker exec redis redis-cli XLEN orders
1
ana@laptop:~/azure$ docker exec redis redis-cli XINFO GROUPS orders | paste - - | grep -E '^(name|entries-read)'
name	audit
entries-read	1
name	billing
entries-read	1
```

Uma mensagem no stream `orders` e dois grupos de consumidores com os nomes dos dois app ids, cada
um tendo lido a mensagem uma vez. **O Dapr dá a cada app id um grupo próprio, então cada app recebe
a sua cópia.** Duas réplicas do billing dividiriam o grupo `billing` e repartiriam as mensagens
entre si, que é para isso que serve uma segunda réplica. Esse arranjo é do componente do Redis, e
a seção 04 mostra que ele não sobrevive à troca sem mudar.

## As chaves de cada app

O prefixo de antes, visto do lado do billing. Pede-se ao sidecar do billing a mesma chave que a
loja guardou:

```
ana@laptop:~/azure$ docker exec billing python -c "import urllib.request as u; r = u.urlopen('http://localhost:3500/v1.0/state/statestore/order-1'); print(r.status, r.read())"
204 b''
```

`204` e corpo vazio: não há nada. O sidecar do billing procurou `billing||order-1`, que não existe.
Dois apps num armazenamento só veem as próprias chaves, a menos que o componente diga o contrário.
A configuração `keyPrefix` do armazenamento pode pôr na frente o nome do componente em vez do app
id, ou nada, então dividir estado entre apps é uma linha que alguém escreve no componente, nunca um
acidente.
