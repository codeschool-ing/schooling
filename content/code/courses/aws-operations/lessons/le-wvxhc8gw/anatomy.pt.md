---
title: O que é uma métrica, e o que faz duas serem diferentes
version: 1
---

Uma métrica do CloudWatch é uma série de números ao longo do tempo, e a imagem comum dela para aí: um
nome, como `Orders`, e os valores. **O nome é um terço da identidade.** Uma métrica é identificada pelo
**namespace**, pelo **nome** e pelas **dimensões** juntos, e mudar qualquer um dos três faz uma métrica
diferente, com histórico próprio e linha própria na fatura.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma métrica desenhada como três caixas: namespace Shop, nome Orders, dimensões Service=api e Stage=prod. Abaixo, três linhas. Shop Orders com Service=api e Stage=prod tem 12 pedidos. Shop Orders com Service=api e Stage=staging tem 3. Shop Orders só com Service=api nunca foi publicada, e na AWS não tem dados.\"><defs><marker id=\"mid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">três partes fazem uma métrica</text><rect x=\"20\" y=\"44\" width=\"140\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">namespace</text><text x=\"90.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Shop</text><rect x=\"180\" y=\"44\" width=\"140\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nome</text><text x=\"250.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Orders</text><rect x=\"340\" y=\"44\" width=\"360\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dimensões</text><text x=\"520.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Service=api, Stage=prod</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Mude qualquer parte e é outra métrica, com histórico próprio e linha própria na fatura:</text><rect x=\"20\" y=\"150\" width=\"680\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop  Orders  Service=api, Stage=prod</text><text x=\"688\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">12 pedidos</text><rect x=\"20\" y=\"178\" width=\"680\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop  Orders  Service=api, Stage=staging</text><text x=\"688\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">3 pedidos</text><rect x=\"20\" y=\"206\" width=\"680\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop  Orders  Service=api</text><text x=\"688\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nunca publicada: sem dados na AWS</text></svg>", "caption": "Uma consulta nomeia uma métrica exatamente. O CloudWatch só soma métricas quando pedem, com matemática ou uma busca.", "same": ["namespace"]}
```

- o **namespace** é um contêiner, `AWS/EC2` para as métricas da própria AWS e o que você escolher,
  aqui `Shop`, para as suas;
- o **nome** diz o que é medido: `Orders`, `Latency`;
- as **dimensões** são pares nome-valor que dizem em que coisa a medida foi feita: `Service=api`,
  `Stage=prod`. Até 30 por métrica.

Cada ponto de dados traz um timestamp, um valor e uma unidade. **O período e a estatística não fazem
parte dos dados**: são escolhidos quando alguém lê. Os mesmos pontos podem ser lidos como soma por
minuto, média por hora ou máximo por dia.

## Publicando duas, e pedindo três

```
ana@laptop:~/aws/metrics$ aws cloudwatch put-metric-data --namespace Shop --metric-name Orders --dimensions Service=api,Stage=prod --unit Count --value 12
ana@laptop:~/aws/metrics$ aws cloudwatch put-metric-data --namespace Shop --metric-name Orders --dimensions Service=api,Stage=staging --unit Count --value 3
ana@laptop:~/aws/metrics$ aws cloudwatch list-metrics --namespace Shop --query 'Metrics[].Dimensions[].[Name,Value]' --output text
Service	api
Stage	prod
Service	api
Stage	staging
```

Dois pontos com o mesmo namespace e o mesmo nome e valores diferentes de `Stage` fizeram **duas
métricas**, e a listagem mostra os dois conjuntos de dimensões. Agora leia de volta de três jeitos,
nos últimos dez minutos:

```
ana@laptop:~/aws/metrics$ START=$(date -u -d "-10 min" +%FT%TZ); END=$(date -u -d "+1 min" +%FT%TZ)
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --dimensions Name=Service,Value=api Name=Stage,Value=prod --start-time $START --end-time $END --period 600 --statistics Sum --query 'Datapoints[].Sum'
[
    12.0
]
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --dimensions Name=Service,Value=api --start-time $START --end-time $END --period 600 --statistics Sum --query 'Datapoints[].Sum'
[
    15.0
]
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --start-time $START --end-time $END --period 600 --statistics Sum --query 'Datapoints[].Sum'
[
    15.0
]
```

Com as duas dimensões, os 12 pedidos de produção. Só com `Service=api`, e sem dimensão nenhuma, **o
moto responde 15**: ele soma toda métrica cujas dimensões incluem as pedidas. **A AWS não soma.** No
CloudWatch, a consulta nomeia uma métrica exatamente, e uma métrica com menos dimensões é outra
métrica, que ninguém publicou, então o segundo e o terceiro comandos devolvem uma lista vazia. Isso não
foi executado aqui, e é o comportamento a esperar: um painel que mostra zero pedidos porque uma
dimensão ficou fora da consulta é um dos jeitos mais comuns de um gráfico mentir, e ele mente ficando
vazio. Somar métricas através de uma dimensão é algo que você pede, com matemática de métricas ou uma
expressão `SEARCH`, nunca algo que o CloudWatch faz sozinho.

## Resolução e retenção

Um ponto publicado com a **resolução padrão** é guardado por minuto; com `--storage-resolution 1`,
**alta resolução**, por segundo, o que custa mais para alarmar. O CloudWatch depois guarda menos
detalhe conforme os dados envelhecem, que é o comportamento documentado da AWS e não algo executado
aqui:

| idade dos dados | menor período disponível |
|---|---|
| menos de 3 horas | 1 segundo, para métricas de alta resolução |
| menos de 15 dias | 1 minuto |
| menos de 63 dias | 5 minutos |
| menos de 15 meses | 1 hora |

Então uma pergunta sobre um pico de três meses atrás só pode ser respondida em horas, e um gráfico
minuto a minuto do trimestre passado não existe. **Exporte o que precisa guardar em detalhe** antes que
envelheça, que é o que a lição 12 faz com os números de que um orçamento de erro é feito.
