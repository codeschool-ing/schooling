---
title: Um build é uma lista de contêineres que compartilham um diretório
version: 1
---

**O Cloud Build roda um build como uma série de contêineres, um por passo, e todo passo vê o mesmo
diretório, `/workspace`.** Esse é o modelo inteiro. Não há servidor de build com ferramentas instaladas
nem estado sobrando de ontem: cada passo nomeia uma imagem, o Cloud Build a baixa, roda com o seu
código-fonte montado em `/workspace` e passa ao passo seguinte quando ela sai com status 0. Um passo
que sai com qualquer outro valor para o build. O que um passo escreve em `/workspace`, o seguinte pode
ler, e é a única coisa que passa entre eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três contêineres de passo em fila, teste, build e envio, cada um ligado por uma linha tracejada a um diretório compartilhado, /workspace, que guarda o repositório. Uma seta entre os passos tem o rótulo exit 0. Um passo que sai com qualquer outro valor termina o build como FAILURE.\"><defs><marker id=\"ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um build, três contêineres, um diretório</text><rect x=\"20\" y=\"44\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">passo test</text><text x=\"110\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">python:3.12.16-slim</text><line x1=\"110\" y1=\"100\" x2=\"110\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><rect x=\"270\" y=\"44\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">passo build</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">cloud-builders/docker</text><line x1=\"360\" y1=\"100\" x2=\"360\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><rect x=\"520\" y=\"44\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depois do último passo</text><text x=\"610\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">push images</text><line x1=\"610\" y1=\"100\" x2=\"610\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><line x1=\"202\" y1=\"72\" x2=\"268\" y2=\"72\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><text x=\"235.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">exit 0</text><line x1=\"452\" y1=\"72\" x2=\"518\" y2=\"72\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><text x=\"485.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">exit 0</text><rect x=\"20\" y=\"150\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/workspace</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualquer outro status de saída: o build para ali, como FAILURE, e nada é enviado</text></svg>", "caption": "Cada passo é um contêiner novo, da própria imagem. Só /workspace sobrevive de um para o seguinte."}
```

A imagem errada comum é a de uma máquina com um script longo, como um laptop que alguém mantém
arrumado. Os contêineres são o motivo de essa imagem falhar: um passo não pode instalar uma
ferramenta para os passos depois dele, porque o seguinte começa da própria imagem. Uma ferramenta de
que você precisa em três passos está na imagem dos três.

## A API da loja

Este curso opera uma pequena loja. A API dela é um arquivo Python com duas rotas, escrito só com a
biblioteca padrão, para que nada precise ser instalado para rodá-lo. Crie o diretório
`~/gcp/shop/api` e ponha estes quatro arquivos nele:

```python
# shop/api/app.py
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

PRODUCTS = [
    {"id": "p-001", "name": "Notebook", "price_cents": 2490},
    {"id": "p-002", "name": "Pencil case", "price_cents": 1890},
]


def route(path):
    if path == "/healthz":
        return 200, {"status": "ok"}
    if path == "/products":
        return 200, PRODUCTS
    return 404, {"error": "not found"}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status, body = route(self.path)
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    HTTPServer(("", port), Handler).serve_forever()
```

```python
# shop/api/test_app.py
import unittest

from app import route


class RouteTest(unittest.TestCase):
    def test_health(self):
        self.assertEqual(route("/healthz"), (200, {"status": "ok"}))

    def test_products_have_prices_in_cents(self):
        status, body = route("/products")
        self.assertEqual(status, 200)
        self.assertTrue(all(isinstance(p["price_cents"], int) for p in body))

    def test_unknown_path(self):
        self.assertEqual(route("/nope")[0], 404)
```

```dockerfile
# shop/api/Dockerfile
FROM mirror.gcr.io/library/python:3.12.16-slim
WORKDIR /app
COPY app.py .
USER nobody
ENV PORT=8080
CMD ["python", "app.py"]
```

A imagem vem de `mirror.gcr.io`, a cópia que o Google mantém das imagens oficiais do Docker Hub. É a
mesma imagem que o Docker Hub serve, e baixá-la do espelho do Google evita o limite do Docker Hub para
downloads anônimos, que uma máquina de build compartilhada por muita gente atinge rápido. **Os preços
estão em centavos, como inteiros**, o que o segundo teste garante; a lição 23 volta ao porquê de
dinheiro nunca ser float.

## O arquivo de build

O build é descrito em `cloudbuild.yaml`, na raiz do repositório, um nível acima da API:

```yaml
# shop/cloudbuild.yaml
steps:
  - id: test
    name: mirror.gcr.io/library/python:3.12.16-slim
    dir: api
    entrypoint: python
    args: ["-m", "unittest", "-v"]

  - id: build
    name: gcr.io/cloud-builders/docker
    args:
      - build
      - -t
      - ${_REGION}-docker.pkg.dev/$PROJECT_ID/shop/api:$SHORT_SHA
      - api

images:
  - ${_REGION}-docker.pkg.dev/$PROJECT_ID/shop/api:$SHORT_SHA

substitutions:
  _REGION: southamerica-east1

serviceAccount: projects/planner-dev/serviceAccounts/shop-build@planner-dev.iam.gserviceaccount.com
options:
  logging: CLOUD_LOGGING_ONLY
```

Leia de cima para baixo:

- **`steps`** é a lista, executada em ordem. Cada passo tem um `id` que você escolhe, o `name` da
  imagem que ele roda e os `args` entregues a ela. `dir` é um diretório dentro de `/workspace` onde
  começar, e `entrypoint` substitui o comando da própria imagem.
- **`gcr.io/cloud-builders/docker`** é uma imagem que o Google publica para builds, com o cliente
  Docker dentro. O Cloud Build dá a um passo o daemon Docker da máquina de build, então este passo
  constrói uma imagem que os passos seguintes, e a lista `images`, conseguem ver.
- **`images`** lista as imagens que o Cloud Build envia ao registro depois que todos os passos tiveram
  sucesso, e as registra no resultado do build. Uma imagem que um passo constrói e ninguém lista é
  jogada fora junto com a máquina.
- **`$PROJECT_ID`, `$SHORT_SHA` e `${_REGION}`** são substituições, assunto da próxima seção.
- **`serviceAccount`** nomeia a identidade com que os passos agem. A lição 8 de `gcp-foundations` é
  sobre por que um build não deve rodar como uma conta que pode tudo, e `options.logging` não é
  opcional aqui: com uma conta de serviço própria, o Cloud Build recusa o build até você dizer para
  onde vão os logs, e `CLOUD_LOGGING_ONLY` os manda para o Cloud Logging, que a lição 9 lê.

## Os mesmos passos, à mão

**Nada no seu computador executa um `cloudbuild.yaml`.** O Google já publicou uma ferramenta que
fazia isso, `cloud-build-local`, e a aposentou; nenhum emulador a substitui. O que você pode fazer é o
que cada passo faz: rodar a imagem dele com o repositório montado em `/workspace`. Isso não é o Cloud
Build, e não mostra nada sobre gatilhos, permissões ou logs, mas é exatamente o que um passo é:

```
ana@laptop:~/gcp/shop$ find . -type f | sort
./api/Dockerfile
./api/app.py
./api/test_app.py
./cloudbuild.yaml
```

O primeiro passo roda os testes na imagem do Python, a partir de `/workspace/api`:

```
ana@laptop:~/gcp/shop$ docker run --rm -v "$PWD":/workspace -w /workspace/api mirror.gcr.io/library/python:3.12.16-slim python -m unittest -v
test_health (test_app.RouteTest.test_health) ... ok
test_products_have_prices_in_cents (test_app.RouteTest.test_products_have_prices_in_cents) ... ok
test_unknown_path (test_app.RouteTest.test_unknown_path) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

O `unittest` sai com 0, então o build continuaria. Se um teste tivesse falhado, ele sairia com 1, o
Cloud Build marcaria o passo e o build como `FAILURE`, e o segundo passo nunca teria começado. **Essa é
a única porta que um build tem**: um status de saída.

O segundo passo constrói a imagem com o nome pelo qual o registro vai conhecê-la, aqui com a tag
`local` no lugar de um commit, e o contêiner que ela gera responde como a API deve responder:

```
ana@laptop:~/gcp/shop$ docker build -q -t southamerica-east1-docker.pkg.dev/planner-dev/shop/api:local api
sha256:016bb774b74e180f15317c580c6ece56e1e90b9ccbc9a5c6cb4f536a0b9e7286
ana@laptop:~/gcp/shop$ docker run -d --rm --name api -p 8080:8080 southamerica-east1-docker.pkg.dev/planner-dev/shop/api:local
1c46ce94c2c672e080330043e42791557473884c32c1e3cbe17f50020402a536
ana@laptop:~/gcp/shop$ curl -s localhost:8080/products; echo
[{"id": "p-001", "name": "Notebook", "price_cents": 2490}, {"id": "p-002", "name": "Pencil case", "price_cents": 1890}]
```

**O nome da imagem é um endereço**: `southamerica-east1-docker.pkg.dev` é o Artifact Registry em São
Paulo, `planner-dev` o projeto, `shop` um repositório e `api` a imagem dentro dele. A lição 2 envia
para um endereço com esse formato. No Cloud Build o envio acontece depois do último passo, porque a
imagem está em `images`; aqui nada foi enviado, e a imagem fica no seu computador.
