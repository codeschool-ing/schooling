---
title: Cloud Trace, e seguir uma requisição
version: 1
---

**Um trace é o registro de uma requisição enquanto ela atravessou o sistema: uma árvore de spans, cada um uma
operação com início, fim e o span que a chamou.** O checkout da loja chama a API, que chama o serviço de
pagamento e o banco; um trace de um checkout mostra os quatro como barras aninhadas num eixo de tempo, e qual
barra levou o tempo. As métricas dizem que o p99 é 2,4 segundos; um trace de uma dessas requisições lentas diz
para onde foram os 2,4 segundos. O Cloud Trace guarda e desenha traces, e **esta seção não foi executada**: o
Cloud Trace não tem emulador. A lição 12 produz traces de verdade no seu computador, com OpenTelemetry, e mostra
os spans deles.

## Como uma requisição carrega o trace

Um trace só sobrevive de um serviço para o seguinte porque cada requisição carrega o id dele num cabeçalho. O
cabeçalho padrão é o `traceparent`, da especificação W3C Trace Context:

```localised
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             │  └──────── trace id ──────────────┘ └ parent span ─┘ └ sampled
             └ version
```

Os balanceadores de carga do Google e o Cloud Run o leem, acrescentam o próprio span e o passam adiante; o
Google Cloud também aceita o cabeçalho antigo dele, `X-Cloud-Trace-Context`. **Um serviço que não repassa o
cabeçalho quebra o trace em dois**, e a segunda metade começa um trace novo que ninguém liga ao primeiro. Esse é
o motivo mais comum de um trace parar numa fronteira entre serviços.

## De uma linha de log ao trace dela

A primeira linha de log da lição 9 trazia:

```json
{"logging.googleapis.com/trace": "projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736"}
```

O valor é o id do trace do cabeçalho acima, escrito como nome de recurso. O Cloud Logging mostra uma entrada
assim com um link para o trace, e o Cloud Trace mostra, ao lado de cada span, as entradas de log escritas
durante ele. Esse par é o que transforma "o pedido o-1001 foi lento" no trace do pedido o-1001, e custa um campo
numa linha de log que o programa já escrevia.

## Amostragem, e quanto custa

Nem toda requisição é rastreada. A **decisão de amostragem** é o último campo do `traceparent`, `01` para
amostrada, tomada uma vez no início da requisição e respeitada por todo serviço depois dela, para que um trace
seja inteiro ou ausente. O Cloud Run amostra sozinho uma pequena parte das requisições; um programa
instrumentado com OpenTelemetry decide com o seu sampler (lição 12).

Pela página de preços, lida em 30 de outubro de 2026, o Cloud Trace cobra **0,20 USD por milhão de spans**
depois dos primeiros 2,5 milhões por conta de faturamento por mês. O checkout da loja tem uns quatro spans; a
quarenta checkouts por minuto e todos rastreados, são 40 × 4 × 60 × 730 = 7.008.000 spans por mês, 4,5 milhões
acima da franquia, ou cerca de 0,90 USD. Amostrar uma requisição em dez mantém isso dentro da franquia.
