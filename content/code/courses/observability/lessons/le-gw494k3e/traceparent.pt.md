---
title: O cabeçalho traceparent
version: 1
---

Cada serviço guarda o seu span corrente na própria memória, como a aula 2 mostrou, e memória não
atravessa a rede. **O que atravessa é um cabeçalho.** O `orders` por acaso guarda o que recebeu com
cada pedido, numa coluna própria, então o cabeçalho pode ser lido direto do banco depois de um
checkout:

```
ana@obs:~/shop$ docker compose exec postgres psql -U shop -tAc 'SELECT id, traceparent FROM orders ORDER BY id DESC LIMIT 1'
1|00-f1523e868eabe70f75294e789580216e-b0844e71b749fd8f-03
```

Essa string é o cabeçalho **`traceparent`** definido pela recomendação Trace Context do W3C, e todo
SDK do OpenTelemetry o escreve e o lê. Ele tem quatro campos separados por hífens:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O cabeçalho traceparent que o orders recebeu, separado nos seus quatro campos. 00 é a versão. f1523e868eabe70f75294e789580216e, 32 dígitos hexadecimais, é o id do rastro, o mesmo em todo serviço. b0844e71b749fd8f, 16 dígitos, é o id do pai: o id do span da vitrine que fez a chamada. 03 são as flags: o bit 1 diz que o rastro é amostrado, o bit 2 que o id do rastro é aleatório.\"><defs><marker id=\"tp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">traceparent: 00-f1523e868eabe70f75294e789580216e-b0844e71b749fd8f-03</text><rect x=\"20\" y=\"80\" width=\"100\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">versão</text><text x=\"70.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00</text><text x=\"70.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sempre 00 hoje</text><path d=\"M70.0 44 L70.0 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><rect x=\"130\" y=\"80\" width=\"250\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">id do rastro</text><text x=\"255.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32 dígitos hex</text><text x=\"255.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o mesmo em todo serviço</text><path d=\"M255.0 44 L255.0 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><rect x=\"390\" y=\"80\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">id do pai</text><text x=\"475.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 dígitos hex</text><text x=\"475.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o id do span de quem chamou</text><path d=\"M475.0 44 L475.0 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><rect x=\"570\" y=\"80\" width=\"135\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"637.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">flags</text><text x=\"637.5\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">03</text><text x=\"637.5\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">amostrado, id aleatório</text><path d=\"M637.5 44 L637.5 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a vitrine o escreveu a partir do span corrente; o orders o lê e faz desse span o pai do seu</text></svg>", "caption": "Cinquenta e cinco caracteres levam tudo de que um serviço precisa para entrar num rastro: qual rastro, e qual span é o pai.", "same": ["flags"]}
```

O segundo campo é o id do rastro do checkout. O terceiro não é, em geral, o primeiro span do
rastro: **é o span que fez a chamada**, qualquer que fosse o corrente quando a requisição saiu. O
Jaeger confirma, com os três primeiros spans do mesmo rastro:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f1523e868eabe70f75294e789580216e | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[:3][] | [$t.processes[.processID].serviceName, .operationName, .spanID] | @tsv'
storefront	POST /checkout	b0844e71b749fd8f
orders	POST /orders	f88ce9d4a6b5790a
orders	INSERT	da0ba127ae104cef
```

`b0844e71b749fd8f` é o `POST /checkout` da vitrine, o span que era o corrente quando a vitrine
chamou o `orders`. Ele é o pai do `POST /orders` do próprio `orders`. Cada salto reescreve o
terceiro campo com o id do seu próprio span, para que o serviço seguinte pendure seus spans debaixo
do pai certo, enquanto o segundo campo nunca muda.

O último campo leva a decisão de amostragem, de que a aula 12 depende: o bit mais baixo diz *este
rastro está sendo registrado*, então todo serviço adiante o registra também. O bit acima dele,
ligado aqui, diz que o id do rastro foi gerado ao acaso, algo em que alguns esquemas de amostragem
se apoiam.

Quais cabeçalhos um SDK escreve é um ajuste, `OTEL_PROPAGATORS`, e o laboratório o deixa no padrão:

```
ana@obs:~/shop$ docker compose exec orders env | grep OTEL_PROPAGATORS || echo 'OTEL_PROPAGATORS not set'
OTEL_PROPAGATORS not set
```

Sem definir quer dizer `tracecontext,baggage`: o `traceparent` do W3C acima e um segundo cabeçalho,
`baggage`, de que trata a última seção desta aula. Existem outros formatos, e o **B3** do Zipkin é o
mais encontrado. Um sistema migrando entre eles pode listar dois propagadores, para que todo serviço
escreva os dois até o último antigo sumir. A aula 11 encontra o B3.
