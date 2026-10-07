---
title: Lendo um rastro
version: 2
---

Uma visão de rastro parece uma linha do tempo, e o hábito que ela convida é ler a barra mais longa.
**A barra mais longa quase sempre é a raiz**, porque um pai dura pelo menos tanto quanto os filhos
que ele espera, então ela não diz nada sobre onde o tempo foi parar. A pergunta a fazer a cada span é
quanto da duração dele foi dele mesmo: o **tempo próprio**, a parte não passada dentro de um span filho.

A interface do Jaeger não mostra o tempo próprio, então ele é calculado aqui com um pequeno programa
`jq` sobre o rastro como a API do Jaeger o devolve. Salve-o como `~/shop/selftime.jq`:

```
# One line per span of a Jaeger trace: service, name, duration, and self time,
# the part of the duration not spent inside a child span.
.data[0] as $t
| ($t.spans | map({key: .spanID, value: .}) | from_entries) as $span
| ($t.spans | map({key: .spanID, value: 0}) | from_entries) as $zero
| (reduce ($t.spans[] | select(.references | length > 0)) as $c ($zero;
     $span[$c.references[0].spanID] as $p
     | (([$c.startTime + $c.duration, $p.startTime + $p.duration] | min)
        - ([$c.startTime, $p.startTime] | max)) as $inside
     | .[$p.spanID] += ([$inside, 0] | max))) as $waited
| $t.spans | sort_by(.startTime) | .[]
| [$t.processes[.processID].serviceName, .operationName,
   "\(.duration / 1000 | floor) ms", "self \((.duration - $waited[.spanID]) / 1000 | floor) ms"]
| @tsv
```

Ele monta uma tabela de todo span por id, depois percorre cada filho e soma ao pai **a parte do
filho que cai dentro do intervalo do próprio pai**. Um filho que começa depois de o pai terminar,
como uma mensagem tirada de uma fila, não soma nada. O que sobra de cada duração é o tempo próprio.

A loja roda com o payments atrasado em 400 ms, e cinco clientes simulados por segundo estão comprando.
Para montar isso, inicie o laboratório de novo do zero e salve antes este override. Ele liga um
recurso do Prometheus que é o assunto da última seção desta aula, e o Prometheus precisa dele desde o
começo, antes do tráfego que vai ler:

`~/shop/compose.override.yaml`

```yaml
services:
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage]
```

Depois deixe o payments lento, reinicie o Prometheus com o override, ponha os clientes para rodar por
vinte e cinco minutos, e um minuto e meio depois escolha um dos checkouts deles no log da vitrine pela
última linha, com o `last_trace` da aula 3:

```sh
echo '{"latency_ms": 400}' > faults/payments.json
docker compose up -d prometheus
docker compose run -d --rm loadgen python -m loadgen.load 5 1500
sleep 90
TRACE=$(last_trace)
```

O `$TRACE` vai onde as transcrições desta aula têm o id desse checkout:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/2317d16ea481cf7a0350d6d965f983e9 | jq -r -f selftime.jq
storefront	POST /checkout	439 ms	self 3 ms
orders	POST /orders	436 ms	self 25 ms
orders	INSERT	1 ms	self 1 ms
orders	POST	404 ms	self 3 ms
payments	POST /charge	401 ms	self 0 ms
payments	wait for the card network	400 ms	self 400 ms
orders	UPDATE	1 ms	self 1 ms
mailer	orders.placed process	20 ms	self 0 ms
mailer	send confirmation	20 ms	self 20 ms
```

Leia a terceira coluna de cima para baixo e todo span parece culpado: a vitrine levou 439 ms, o
orders 436, a chamada ao payments 404. **A quarta coluna diz que quase nenhum deles fez alguma
coisa.** A vitrine gastou 3 ms próprios, e o `POST /charge` do payments, nenhum. Os 400 ms estão
todos dentro de um span, `wait for the card network`, que o código do payments abre à mão em volta
da chamada que ele não consegue enxergar por dentro. Essa é a resposta inteira, e ela é uma linha de
nove.

Duas linhas merecem um segundo olhar:

- **O `POST /orders` tem 25 ms de tempo próprio** que nenhum filho explica. O código diz o que é:
  depois do `UPDATE`, o `orders` abre uma conexão nova com o RabbitMQ para cada mensagem que publica, e
  nada instrumenta o `pika`, como disse a aula 4. O tempo próprio é onde aparece o trabalho não
  instrumentado, como uma lacuna que não pertence a ninguém abaixo.
- **Os dois spans do mailer estão no rastro mas não na duração dele.** Eles começaram depois de o
  checkout responder, porque a mensagem esperou numa fila, e a regra de sobreposição do programa acima
  não lhes dá nada para descontar do pai. Eles pertencem ao que o pedido causou, não ao que o cliente
  esperou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"Os nove spans do checkout, cada um como duas barras. O contorno é a duração do span; a parte cheia é o tempo próprio, o tempo não passado dentro de um filho. storefront POST /checkout: 439 ms, próprio 3 ms. orders POST /orders: 436 ms, próprio 25 ms. orders INSERT: 1 ms, próprio 1 ms. orders POST: 404 ms, próprio 3 ms. payments POST /charge: 401 ms, próprio 0 ms. payments wait for the card network: 400 ms, próprio 400 ms. orders UPDATE: 1 ms, próprio 1 ms. mailer orders.placed process: 20 ms, próprio 0 ms. mailer send confirmation: 20 ms, próprio 20 ms. Só o span wait for the card network está cheio quase de ponta a ponta.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"300\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duração</text><text x=\"380\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tempo próprio</text><text x=\"16\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">storefront</text><text x=\"96\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /checkout</text><rect x=\"300\" y=\"52\" width=\"340.0\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"52\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"59\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 / 439 ms</text><text x=\"16\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /orders</text><rect x=\"300\" y=\"78\" width=\"337.6765375854214\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"78\" width=\"19.362186788154897\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25 / 436 ms</text><text x=\"16\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><rect x=\"300\" y=\"104\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"104\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"111\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 / 1 ms</text><text x=\"16\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST</text><rect x=\"300\" y=\"130\" width=\"312.89293849658316\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"130\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"137\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 / 404 ms</text><text x=\"16\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payments</text><text x=\"96\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /charge</text><rect x=\"300\" y=\"156\" width=\"310.56947608200454\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 / 401 ms</text><text x=\"16\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payments</text><text x=\"96\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">wait for the card network</text><rect x=\"300\" y=\"182\" width=\"309.79498861047836\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"182\" width=\"309.79498861047836\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"189\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400 / 400 ms</text><text x=\"16\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orders</text><text x=\"96\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE</text><rect x=\"300\" y=\"208\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"208\" width=\"3\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 / 1 ms</text><text x=\"16\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">mailer</text><text x=\"96\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders.placed process</text><rect x=\"300\" y=\"234\" width=\"15.489749430523919\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"241\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 / 20 ms</text><text x=\"16\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">mailer</text><text x=\"96\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send confirmation</text><rect x=\"300\" y=\"260\" width=\"15.489749430523919\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"300\" y=\"260\" width=\"15.489749430523919\" height=\"14\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"700\" y=\"267\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 / 20 ms</text></svg>", "caption": "Toda barra menos uma está quase vazia: os spans acima da espera duraram tanto quanto ela, e quase nada fizeram sozinhos. As barras do mailer aparecem inteiras, embora tenham rodado depois de o checkout responder."}
```
