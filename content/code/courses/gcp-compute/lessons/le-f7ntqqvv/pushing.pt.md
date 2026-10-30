---
title: Fazendo push de uma imagem, e quem deixa
version: 1
---

Fazer push no Artifact Registry é `docker push` para um endereço comprido, e quase tudo que dá
errado dá errado antes de um byte ser enviado: o Docker precisa provar quem você é. **O gcloud
resolve isso virando o auxiliar de credenciais do Docker para os hosts de registry do Google**, de
modo que todo push e todo pull pedem ao gcloud um token de vida curta em vez de guardar uma senha.

## Dizendo ao Docker para perguntar ao gcloud

Este comando só edita um arquivo no seu laptop, então roda aqui exatamente como rodaria com uma
conta:

```
ana@laptop:~/gcp$ gcloud auth configure-docker southamerica-east1-docker.pkg.dev --quiet
Adding credentials for: southamerica-east1-docker.pkg.dev
Docker configuration file updated.
ana@laptop:~/gcp$ jq . ~/.docker/config.json
{
  "credHelpers": {
    "southamerica-east1-docker.pkg.dev": "gcloud"
  }
}
```

**Foi só isso que ele fez**: uma entrada no `~/.docker/config.json` dizendo que, para
`southamerica-east1-docker.pkg.dev`, o Docker deve rodar o `docker-credential-gcloud`, um programa
que veio com a linha de comando do Google Cloud. Nenhuma senha foi gravada, e nenhuma nunca é. Com
uma conta, cada push faria o gcloud entregar ao Docker um token OAuth que expira em menos de uma
hora. Neste laboratório o auxiliar pararia na falta de conta, e é por isso que o push para o próprio
Google não aparece abaixo.

Num servidor de build, que não tem pessoa para fazer login, o mesmo auxiliar funciona com a conta de
serviço do servidor; o Cloud Build não precisa de nada, porque faz push com a própria identidade.

## O protocolo, praticado no seu laptop

O Artifact Registry fala o **protocolo OCI Distribution**, a mesma API HTTP que todo registry de
contêiner fala, e é por isso que um `docker push` comum funciona contra ele. O `registry`, o
registry de código aberto que você baixou na lição 1, também fala esse protocolo. **Ele não é o
Artifact Registry**: não tem permissões, nem varredura, nem políticas de limpeza. O que ele mostra
fielmente é o que são um push e um pull.

Inicie-o, depois construa uma imagem pequena para a frente web da loja. **Crie `~/gcp/web` e salve
estes dois arquivos dentro dela:**

```python
# web/app.py
from http.server import BaseHTTPRequestHandler, HTTPServer


class Hello(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'shop web 1.4.0\n')


HTTPServer(('', 8080), Hello).serve_forever()
```

```dockerfile
# web/Dockerfile
FROM python:3.12.13-slim
COPY app.py /app/app.py
CMD ["python3", "/app/app.py"]
```

```
ana@laptop:~/gcp/web$ docker run -d --name registry -p 5000:5000 registry:3.1.2
e28bf383389bf1f15f9bfcec1894aa1970a933cda96ef70311f13a16880fa9f9
ana@laptop:~/gcp/web$ docker build -q -t localhost:5000/shop/web:1.4.0 .
sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4
ana@laptop:~/gcp/web$ docker push localhost:5000/shop/web:1.4.0
The push refers to repository [localhost:5000/shop/web]
44136fa355b3: Pushed
b3c7a9bdb4f2: Pushed
afa7bc74001e: Pushed
5a31db4cd478: Pushed
7ff48d07785c: Pushed
c85ad0bcaca8: Pushed
26c307b5e35a: Pushed
1.4.0: digest: sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4 size: 856
```

O endereço é o host e a porta do registry, depois o caminho do repositório, depois a tag, que é o
mesmo formato de um endereço do Artifact Registry com `localhost:5000` onde estaria
`southamerica-east1-docker.pkg.dev/planner-dev`. **Leia a última linha do push**: o registry
respondeu com um **digest**, o SHA-256 do manifesto da imagem, e a seção 04 é sobre por que essa
linha importa mais que a tag.

## O que o registry guarda agora

O protocolo é HTTP puro, então o curl pode perguntar ao registry o que ele tem:

```
ana@laptop:~/gcp/web$ curl -s localhost:5000/v2/_catalog
{"repositories":["shop/web"]}
ana@laptop:~/gcp/web$ curl -s localhost:5000/v2/shop/web/tags/list
{"name":"shop/web","tags":["1.4.0"]}
```

**Todo repositório do Artifact Registry responde às mesmas duas perguntas do mesmo jeito**, atrás de
autenticação. Esse é o contrato inteiro que um registry oferece: nomes, tags e blobs endereçados
pelo digest.

Deixe-o rodando: a seção 04 o usa, e diz quando pará-lo.
