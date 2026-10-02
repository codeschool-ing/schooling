---
title: Links: quando um trabalho tem muitas causas
version: 1
---

Um pai diz *este span foi causado por aquele*, e um span tem no máximo um. Certos trabalhos não
cabem nisso. **Uma tarefa que processa um lote de vinte e dois pedidos foi causada, de certo modo,
por vinte e duas requisições.** Fazê-la filha de uma delas seria mentir sobre as outras vinte e uma,
e fazê-la filha de todas é impossível. A resposta do OpenTelemetry é o **link**: uma referência de
um span a outro span, em qualquer rastro, que diz *este dizia respeito àquele* sem fazer deles um
rastro só.

O relatório noturno é o caso do laboratório. Ele conta os pedidos desde uma data e, para cada um,
acrescenta um link para o rastro da requisição que o criou. Consegue fazer isso porque o `orders`
guardou o `traceparent` de cada pedido. Depois de vinte e dois checkouts, o relatório é rodado à
mão:

```
ana@obs:~/shop$ docker compose run --rm report 2>&1 | grep -v Container | jq -c '{message, orders, paid, trace_id}'
{"message":"report written","orders":22,"paid":22,"trace_id":"2463827ff26f4bee6e7636585987181f"}
```

O span dele leva um link por pedido, e o Jaeger os guarda como referências do tipo `FOLLOWS_FROM`,
o nome que ele dá a um link:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/2463827ff26f4bee6e7636585987181f | jq -c '.data[0].spans[] | {operationName, references: (.references | length), refType: (.references | map(.refType) | unique)}'
{"operationName":"nightly report","references":22,"refType":["FOLLOWS_FROM"]}
```

Os ids de rastro para os quais ele aponta são os dos próprios checkouts, na ordem em que os pedidos
foram guardados:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/2463827ff26f4bee6e7636585987181f | jq -r '.data[0].spans[0].references[:3][].traceID'
f1523e868eabe70f75294e789580216e
ae937cc824d4843fbac8e390ddb3cc0c
f8cdb58e9faf2978f1d207747f46300b
ana@obs:~/shop$ docker compose exec postgres psql -U shop -tAc 'SELECT id, split_part(traceparent, chr(45), 2) FROM orders ORDER BY id LIMIT 3'
1|f1523e868eabe70f75294e789580216e
2|ae937cc824d4843fbac8e390ddb3cc0c
3|f8cdb58e9faf2978f1d207747f46300b
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Pai contra link. À esquerda, o rastro de um checkout: POST /checkout é pai de POST /orders, que é pai do span do mailer, mesmo que o mailer tenha rodado 22,8 segundos depois, após a fila: uma requisição, um rastro. À direita, o relatório noturno: rastro próprio, sem pai, e links tracejados para os rastros dos 22 pedidos que ele contou. Um link diz que este trabalho dizia respeito àqueles spans; não os torna um rastro só.\"><defs><marker id=\"pl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um pai: uma requisição</text><rect x=\"60\" y=\"50\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /checkout</text><text x=\"170.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storefront</text><rect x=\"60\" y=\"120\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /orders</text><text x=\"170.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"60\" y=\"220\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders.placed process</text><text x=\"170.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mailer, 22,8 s depois</text><path d=\"M170 92 L170 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M170 162 L170 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><text x=\"240\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pela fila</text><text x=\"540\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">links: muitas causas, uma tarefa</text><rect x=\"450\" y=\"220\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nightly report</text><text x=\"540.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">report, sem pai</text><rect x=\"370\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"400.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pedido 1</text><path d=\"M540 218 L400 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><rect x=\"450\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"480.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">…</text><path d=\"M540 218 L480 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><rect x=\"530\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">…</text><path d=\"M540 218 L560 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><rect x=\"610\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"640.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pedido 22</text><path d=\"M540 218 L640 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><text x=\"540\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22 links, um por pedido contado</text></svg>", "caption": "Uma causa e um efeito é um pai. Muitas causas por trás de um trabalho, ou nenhuma, é uma raiz com links.", "same": ["POST /checkout", "POST /orders", "nightly report", "orders", "orders.placed process", "storefront"]}
```

Um backend usa os links para passar entre os dois tipos de rastro. Ele vai do span do relatório aos
checkouts que ele contou e, onde o backend suportar, de um checkout a todo lote que mexeu nele
depois. **Nenhum rastro cresce**: o rastro do relatório tem um span, e o de cada checkout é
exatamente o que era. Essa é a diferença para um pai, e é por isso que links servem para lotes,
convergências e qualquer outra coisa em que muitas requisições alimentam um trabalho.
