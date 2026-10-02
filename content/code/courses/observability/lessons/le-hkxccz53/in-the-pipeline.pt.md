---
title: Removendo na esteira, e o que isso deixa passar
version: 1
---

A segunda defesa fica no Collector, por onde passam as linhas de todo serviço, tenha o código dele
sido cuidadoso ou não. O filtro foi tirado de novo do `logs.py` para mostrar a esteira trabalhando
sozinha. Um terceiro arquivo do Collector acrescenta duas instruções ao processor `transform`, antes
de o JSON ser interpretado, para que os campos interpretados saiam do texto já limpo:

```
ana@obs:~/shop$ diff otel/collector-logs.yaml otel/collector-redact.yaml
35a36,37
>           - replace_pattern(body, "\\b(?:\\d[ -]?){12,15}(\\d{4})\\b", "**** $$1")
>           - replace_pattern(body, "Bearer [A-Za-z0-9._-]+", "Bearer [removed]")
```

O `replace_pattern` reescreve o corpo da linha com uma expressão regular: números com formato de cartão
mantêm os quatro últimos dígitos, e o que vier depois de `Bearer` é substituído. `$$1` é o primeiro
grupo capturado, com o cifrão dobrado porque o Collector expande `$` nos seus arquivos de configuração.
O Collector é recriado com este arquivo, a vitrine reiniciada, e um checkout enviado:

```
ana@obs:~/shop$ sed -i 's#collector-logs.yaml#collector-redact.yaml#' compose.override.yaml && docker compose up -d otel-collector 2>&1 | tail -1
 Container shop-otel-collector-1 Started 
ana@obs:~/shop$ docker compose restart storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d @checkout.json
{"id":2703,"qty":1,"sku":"kettle","status":"paid"}
```

O que o Loki recebeu:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="storefront"} | json | message="request"' --data-urlencode since=5m --data-urlencode limit=1 | jq -r '.data.result[].values[][1]' | jq -c '{card: .body.card, auth: .headers.Authorization}'
{"card":"**** 1111","auth":"Bearer [removed]"}
```

**Mascarado.** E o que o próprio contêiner escreveu, lido na máquina com `docker compose logs`:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep '"request"' | tail -1 | jq -c '{card: .body.card, auth: .headers.Authorization}'
{"card":"4111 1111 1111 1111","auth":"Bearer sk_live_9f8e7d6c5b4a"}
```

**Não mascarado.** A esteira só limpa o que passa por ela. O log do próprio contêiner na máquina, um
dump de falha, um desenvolvedor rodando o serviço à mão, qualquer coisa que leia a saída do processo
antes do Collector, ainda tem o segredo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Onde um segredo escrito pela vitrine vai parar, e que defesa cobre que lugar. A linha da vitrine vai primeiro ao log do próprio contêiner na máquina, depois pelo Collector, depois ao Loki e ao Elasticsearch. Um filtro no código remove o segredo antes de a linha existir em qualquer lugar. A redação no Collector o remove só do que o Collector repassa: o log do próprio contêiner na máquina ainda o guarda.\"><defs><marker id=\"lk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"80.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escreve a linha</text><rect x=\"180\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">log do contêiner</text><text x=\"255.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na máquina</text><rect x=\"180\" y=\"120\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Collector</text><text x=\"255.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replace_pattern</text><rect x=\"380\" y=\"100\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loki</text><rect x=\"380\" y=\"160\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Elasticsearch</text><path d=\"M142 120 L178 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M142 140 L178 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M332 150 L378 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M332 155 L378 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M20 225 L510 225\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"265\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um filtro no código: toda cópia sai limpa</text><path d=\"M180 262 L510 262\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"345\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">redação no Collector: só o que ele repassa</text><text x=\"600\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ainda tem o segredo</text><text x=\"600\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">se só o Collector redige</text><path d=\"M520 60 L334 55\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#lk-ah)\"></path></svg>", "caption": "Duas defesas, duas coberturas. A do código cobre toda cópia; a da esteira cobre toda cópia depois da esteira, e é por isso que ela é a segunda linha e não a primeira.", "same": ["Collector", "Elasticsearch", "Loki", "replace_pattern", "storefront"]}
```

É por isso que a ordem importa: **o código é a primeira defesa e a esteira é a segunda**. A esteira
pega o serviço que alguém esqueceu de atualizar e a biblioteca que registra sozinha. O código pega
tudo, em todo lugar para onde a linha vai. O Collector também traz um processor dedicado, o
`redaction`, construído em torno de uma lista de nomes de atributo permitidos, que é ainda mais
rígido: o que não está na lista é descartado.