---
title: Costuras portáveis, e quanto custa a portabilidade
version: 1
---

A resposta ao lock-in de API costuma vir como uma escolha de serviço: pegue o portável. **A
resposta melhor é escolher onde o provedor pode aparecer no seu código.** Uma costura é a linha
entre a parte do programa que sabe o que a loja faz e a parte que sabe onde ela roda. Desenhe essa
linha uma vez, mantenha o provedor de um lado dela, e mudar passa a ser reescrever o lado fino.

## O orçamento da loja, em três arquivos

A regra que importa à loja é um orçamento: uma lista de itens entra, um total em centavos sai. Ela
vai num arquivo que não importa nada da AWS e nada sobre HTTP:

```python
# orders.py
"""The shop's order rules. Nothing here knows where it runs."""

PRICES = {"tee": 7990, "mug": 3490, "cap": 5990}   # cents


def quote(order):
    """Status and body for an order such as {"items": {"tee": 2, "mug": 1}}."""
    items = order.get("items") or {}
    unknown = sorted(set(items) - set(PRICES))
    if unknown:
        return 400, {"error": "unknown item: " + ", ".join(unknown)}
    total = sum(PRICES[name] * count for name, count in items.items())
    return 200, {"items": sum(items.values()), "total_cents": total}
```

O Lambda chega a ela por um handler. O event tem o formato que uma function URL ou uma HTTP API
manda, com o corpo da requisição como string, e a resposta tem o formato que elas esperam de volta:

```python
# lambda_app.py
import json

from orders import quote


def handler(event, context):
    status, body = quote(json.loads(event.get("body") or "{}"))
    return {"statusCode": status,
            "headers": {"content-type": "application/json"},
            "body": json.dumps(body)}
```

Um contêiner chega a ela por um servidor web. Este usa só a biblioteca padrão do Python, o que basta
para mostrar a costura; um serviço real usaria um framework, e a costura seria a mesma:

```python
# server.py
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

from orders import quote


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        size = int(self.headers.get("content-length", 0))
        status, body = quote(json.loads(self.rfile.read(size) or b"{}"))
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


HTTPServer(("127.0.0.1", 8008), Handler).serve_forever()
```

Salve os três num mesmo diretório, `~/aws/shop`.

## A mesma regra, rodando dos dois jeitos

Como servidor, iniciado em segundo plano com o log mandado para um arquivo, e consultado para um
orçamento:

```
ana@laptop:~/aws/shop$ python3 server.py 2> server.log &
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:8008/quote -d '{"items": {"tee": 2, "mug": 1}}'; echo
{"items": 3, "total_cents": 19470}
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:8008/quote -d '{"items": {"hat": 1}}'; echo
{"error": "unknown item: hat"}
ana@laptop:~/aws/shop$ kill %1
```

Como função Lambda, na imagem base da AWS com o Runtime Interface Emulator que a aula 14 apresentou.
**Esta parte roda de verdade**: é o runtime que a AWS publica, no seu laptop, e o event é o que uma
function URL entregaria:

```
ana@laptop:~/aws/shop$ docker run --rm -d --name shop -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 lambda_app.handler > /dev/null
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"body": "{\"items\": {\"tee\": 2, \"mug\": 1}}"}'; echo
{"statusCode": 200, "headers": {"content-type": "application/json"}, "body": "{\"items\": 3, \"total_cents\": 19470}"}
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"body": "{\"items\": {\"hat\": 1}}"}'; echo
{"statusCode": 400, "headers": {"content-type": "application/json"}, "body": "{\"error\": \"unknown item: hat\"}"}
ana@laptop:~/aws/shop$ docker stop shop
shop
```

Os mesmos 19.470 centavos, e o mesmo erro para um item que a loja não vende, saíram de dois
runtimes que não têm nada em comum além do `orders.py`. Nenhum dos adaptadores contém uma regra da
loja.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas fronteiras tracejadas lado a lado: à esquerda, um ambiente de execução do Lambda com lambda_app.py, que recebe um event e devolve um dicionário; à direita, um contêiner em qualquer provedor com server.py, que recebe HTTP e devolve HTTP. Entre os dois, sem pertencer a nenhum, orders.py com a regra da loja. Uma seta vai de cada adaptador até orders.py. Notas embaixo: a costura são duas linhas em cada adaptador, o import e a chamada, e sair reescreve um adaptador, nunca a regra.\"><defs><marker id=\"l24s-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um ambiente de execução do Lambda</text><rect x=\"400\" y=\"30\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"415\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um contêiner, em qualquer provedor</text><rect x=\"45\" y=\"80\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lambda_app.py</text><text x=\"120\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entra event, sai dict</text><rect x=\"525\" y=\"80\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">server.py</text><text x=\"600\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entra HTTP, sai HTTP</text><rect x=\"285\" y=\"180\" width=\"150\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders.py</text><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a regra da loja</text><path d=\"M120 131 L120 207 L283 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24s-phosphor)\"></path><path d=\"M600 131 L600 207 L437 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24s-phosphor)\"></path><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a costura: duas linhas em cada adaptador, o import e a chamada</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sair reescreve um adaptador, nunca a regra</text></svg>", "caption": "Dois runtimes, uma regra. Cada adaptador conhece o seu runtime e alcança a regra por um import e uma chamada."}
```

## Costuras que valem a pena

A mesma ideia vale onde quer que o provedor fosse, de outro modo, entrar no código:

- **a imagem** é a costura da computação. Uma imagem OCI construída a partir de um Dockerfile roda
  no Fargate, no EKS, no App Runner, num laptop e no serviço de contêineres de qualquer outro
  provedor; a task definition em volta dela é a parte que fica para trás;
- **protocolos abertos** são a costura do tráfego: HTTP na entrada, SQL para o banco, e um cliente de
  fila atrás de uma interface sua, em vez de chamadas ao SQS espalhadas pelo código;
- **um adaptador fino em volta do SDK** é a costura do armazenamento: uma função
  `save_report(name, data)` que chama o S3 num lugar só, para que, no dia em que os relatórios
  mudarem de lugar, uma função mude.

## Quanto custa a portabilidade

**Uma costura é código, e código se paga.** Os adaptadores acima são pequenos porque a regra é
pequena; o preço cresce a cada recurso da plataforma que você decide não usar diretamente. Uma
equipe que embrulha o Step Functions numa camada de fluxo própria para poder sair um dia escreveu
um motor de fluxo, e vai mantê-lo em todos os dias em que não sair.

O erro oposto é igualmente real. Recusar todo serviço gerenciado em nome da portabilidade quer dizer
rodar a própria fila, o próprio agendador e o próprio banco de dados em instâncias, o que custa mais
todo mês do que a maioria das saídas jamais custaria. **A portabilidade vale o preço onde sair é
provável ou caro, e em nenhum outro lugar**, e a próxima seção transforma essa frase em números.
