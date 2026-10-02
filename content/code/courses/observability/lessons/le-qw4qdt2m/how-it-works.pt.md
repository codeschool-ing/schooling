---
title: Como um serviço ganha spans que nunca pediu
version: 1
---

O `orders` não importa tracer nem abre span, e o rastro da aula 1 ainda tinha quatro spans dele. A
diferença é uma palavra na frente do comando:

```
ana@obs:~/shop$ grep -A3 '^  orders:' compose.yaml
  orders:
    <<: *shop
    command: opentelemetry-instrument waitress-serve --port 8081 --threads 16 orders.app:app
    environment:
```

**O `opentelemetry-instrument` roda antes do programa e o modifica.** É um pequeno lançador que
configura o SDK e depois inicia o comando de verdade, o `waitress-serve`, no mesmo processo. Entre
uma coisa e outra ele faz o passo que a aula 2 nunca teve. Para cada biblioteca que sabe
instrumentar, substitui as funções dela por invólucros que abrem um span, chamam a original e
fecham o span. Isso se chama **monkey-patching**, e o Python permite porque as funções de um módulo
são atributos que qualquer um pode reatribuir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O que o opentelemetry-instrument faz antes de o programa rodar, em cinco passos da esquerda para a direita. Um: ler as variáveis de ambiente OTEL_. Dois: montar o SDK a partir delas, provider, processor e exporter. Três: achar todo pacote de instrumentação instalado. Quatro: cada um envolve as funções da sua biblioteca: Flask, requests, psycopg. Cinco: iniciar o programa de verdade, o waitress-serve com orders.app, cujo código chama as funções envolvidas sem saber.\"><defs><marker id=\"auto-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 ler</text><text x=\"80.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variáveis OTEL_</text><rect x=\"160\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 montar o SDK</text><text x=\"220.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provider, exporter</text><rect x=\"300\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 achar</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">instrumentações</text><rect x=\"440\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 envolver</text><text x=\"500.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Flask, requests,</text><rect x=\"580\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5 rodar</text><text x=\"640.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders.app</text><text x=\"500\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">psycopg</text><path d=\"M142 115 L158 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><path d=\"M282 115 L298 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><path d=\"M422 115 L438 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><path d=\"M562 115 L578 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">opentelemetry-instrument waitress-serve ... orders.app:app</text><path d=\"M20 190 L280 190\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"150\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que a aula 2 fez à mão</text><path d=\"M300 190 L560 190\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"430\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">novo: acha e modifica</text><text x=\"430\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as bibliotecas importadas</text></svg>", "caption": "Tudo o que a aula 2 escreveu à mão em common/tracing.py, feito a partir do ambiente, mais o passo que a aula 2 nunca teve: modificar as bibliotecas que o código importa.", "same": ["Flask, requests,", "orders.app", "provider, exporter", "psycopg"]}
```

Quais bibliotecas são modificadas é decidido pelo que está instalado. Cada instrumentação é um
pacote à parte, e o lançador carrega todo que encontrar:

```
ana@obs:~/shop$ docker compose exec orders pip list 2>/dev/null | grep -i opentelemetry-instrumentation
opentelemetry-instrumentation            0.66b0
opentelemetry-instrumentation-dbapi      0.66b0
opentelemetry-instrumentation-flask      0.66b0
opentelemetry-instrumentation-psycopg    0.66b0
opentelemetry-instrumentation-requests   0.66b0
opentelemetry-instrumentation-wsgi       0.66b0
```

O Flask para as requisições que chegam, o `requests` para as chamadas que saem, o psycopg para o
banco. Os pacotes `wsgi` e `dbapi` são as camadas genéricas sobre as quais o primeiro e o último
são construídos. A imagem os instalou porque os requisitos dela os nomeavam. Em vez disso, o
`opentelemetry-bootstrap`, que vem com o lançador, pode ler o que um programa tem
instalado e imprimir os pacotes de instrumentação correspondentes.

**Todo o resto vem do ambiente**, o mesmo SDK que a aula 2 montou à mão, descrito por variáveis em
vez de código:

```
ana@obs:~/shop$ docker compose exec orders env | grep ^OTEL_ | sort
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_LOGS_EXPORTER=none
OTEL_METRICS_EXPORTER=none
OTEL_PYTHON_FLASK_EXCLUDED_URLS=health,metrics
OTEL_SERVICE_NAME=orders
OTEL_TRACES_EXPORTER=otlp
```

`OTEL_SERVICE_NAME` vira o `service.name` do resource. O exporter é OTLP por HTTP até o Collector,
e métricas e logs ficam desligados porque a loja cuida deles do seu jeito. Nenhuma linha de
`orders/app.py` menciona nada disso.
