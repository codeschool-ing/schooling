---
title: Um objeto chega, uma função roda
version: 1
---

O Cloud Storage anuncia as suas mudanças de dois jeitos há anos, e os dois continuam em uso. **O
mais antigo grava uma notificação num tópico do Pub/Sub que você escolhe; o mais novo é o gatilho
do Eventarc da seção 02**, que entrega um evento `google.cloud.storage.object.v1.finalized` com os
metadados do objeto como dados. Os metadados são o mesmo JSON nos dois. Só o envelope muda.

O primeiro é o que um laptop consegue rodar, porque o fake-gcs-server, a imitação de código aberto
do Cloud Storage que você baixou na lição 1, sabe publicar notificações no formato do próprio Cloud
Storage para o emulador de Pub/Sub. **O fake-gcs-server não é do Google**, e imita a API de
armazenamento em vez de rodá-la; o que ele publica segue o formato que o Google documenta para
notificações por Pub/Sub, que é o que esta seção lê.

## Os dois emuladores

Primeiro o emulador de Pub/Sub, exatamente como na lição 17, com a variável definida e o tópico em
que o bucket vai escrever:

```
ana@laptop:~/gcp$ docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev
b44651b57aa618e675b7a02c7336ee35894972d9e5af206650b8595ae9a7579e
ana@laptop:~/gcp$ export PUBSUB_EMULATOR_HOST=localhost:8085
ana@laptop:~/gcp$ python3 pubsub.py topic photo-uploads
projects/planner-dev/topics/photo-uploads
```

Depois o fake-gcs-server, na mesma rede, sabendo onde está o emulador de Pub/Sub e em que tópico
publicar. O `-event.list` diz quais mudanças valem um anúncio:

```
ana@laptop:~/gcp$ docker run -d --name gcs --network host -e PUBSUB_EMULATOR_HOST=localhost:8085 fsouza/fake-gcs-server:1.56.1 -scheme http -port 4443 -backend memory -event.pubsub-project-id planner-dev -event.pubsub-topic photo-uploads -event.list finalize,delete
2b863ead44c23640e7de1b16a9ea4378cbc9450f757c0f86b9f39ff36932451d
```

## A função

A notificação põe os metadados do objeto, em JSON, nos dados da mensagem, e um resumo nos
atributos. **Crie `~/gcp/thumbnails` e salve isto como `main.py` dentro dela:**

```python
# thumbnails/main.py
import base64
import json

import functions_framework


@functions_framework.cloud_event
def on_upload(event):
    message = event.data['message']
    attrs = message['attributes']
    obj = json.loads(base64.b64decode(message['data']))
    print(f"{attrs['eventType']} gs://{attrs['bucketId']}/{attrs['objectId']}"
          f" {obj['size']} bytes {obj['contentType']}", flush=True)
```

Ela não faz miniatura nenhuma: o que importa aqui é o que lhe contam. Inicie-a no segundo terminal
e aponte uma assinatura de push para ela a partir do primeiro, com o `pubsub.py` da lição 17:

```
ana@laptop:~/gcp/thumbnails$ functions-framework --target on_upload --signature-type cloudevent
```

```
ana@laptop:~/gcp$ python3 pubsub.py push thumbnails photo-uploads http://localhost:8080/
projects/planner-dev/subscriptions/thumbnails -> http://localhost:8080/
```

## O upload

Sem conta, nem o `gcloud storage` nem mais nada do Google fala com a imitação, então **o curl faz o
upload**, falando a API JSON do Cloud Storage com o fake-gcs-server: primeiro o bucket, depois uma
foto, depois a remoção dela:

```
ana@laptop:~/gcp$ curl -s -X POST 'localhost:4443/storage/v1/b?project=planner-dev' -H 'content-type: application/json' -d '{"name": "shop-photos"}' | jq -r .name
shop-photos
ana@laptop:~/gcp$ head -c 48213 /dev/urandom > 1042.jpg
ana@laptop:~/gcp$ curl -s -X POST --data-binary @1042.jpg -H 'content-type: image/jpeg' 'localhost:4443/upload/storage/v1/b/shop-photos/o?uploadType=media&name=products/1042.jpg' | jq -r '.name, .size'
products/1042.jpg
48213
ana@laptop:~/gcp$ curl -s -o /dev/null -w '%{http_code}\n' -X DELETE localhost:4443/storage/v1/b/shop-photos/o/products%2F1042.jpg
200
```

E no terminal da função:

```
OBJECT_FINALIZE gs://shop-photos/products/1042.jpg 48213 bytes image/jpeg
OBJECT_DELETE gs://shop-photos/products/1042.jpg 0 bytes image/jpeg
```

**Dois eventos, um para cada mudança**, cada um com o bucket e o objeto nos atributos, então uma
função que só precisa saber o que mudou nunca precisa decodificar os dados. Os dados trazem o
resto: tamanho, content type, checksums e a geração do objeto, o número que distingue duas versões
de `products/1042.jpg`. Um detalhe é da imitação: ela informa 0 como tamanho de um objeto apagado,
então não leia nada no tamanho de uma remoção aqui.

Pare os dois emuladores quando terminar:

```sh
docker rm -f gcs pubsub
```

## O que muda no Google Cloud

Com o gatilho do Eventarc da seção 02, o evento chega como
`google.cloud.storage.object.v1.finalized`, com o JSON do objeto como dados do CloudEvent e o bucket
no `subject`; não há `message` para desembrulhar. Com uma notificação por Pub/Sub, o seu código lê
exatamente o que leu aqui. **O trabalho é o mesmo nos dois e a leitura muda**, o que é um motivo
para deixar a leitura numa função pequena e o trabalho em outra.
