---
title: Onde ela para
version: 2
---

A instrumentação automática vê um serviço pelas bordas, e é boa nelas. **Ela para em três
lugares**, e cada um é uma pergunta que uma investigação real faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O que a instrumentação automática vê no orders. O serviço é uma caixa. As bordas são vistas: a requisição chegando pelo Flask, as consultas saindo pelo psycopg, a chamada ao payments saindo pelo requests. Dentro da caixa, sem ser visto: que pedido é este, que produto, a decisão de publicar na fila, e a própria publicação, porque nenhuma instrumentação para o cliente da fila está instalada.\"><defs><marker id=\"edge-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"220\" y=\"60\" width=\"280\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que pedido, que produto</text><text x=\"360\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pago ou recusado, e por quê</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a decisão de publicar</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">não visto</text><rect x=\"30\" y=\"120\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /orders</text><text x=\"100.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Flask, visto</text><path d=\"M172 145 L218 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#edge-ah)\"></path><rect x=\"550\" y=\"70\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">INSERT, UPDATE</text><text x=\"625.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">psycopg, visto</text><rect x=\"550\" y=\"130\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /charge</text><text x=\"625.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests, visto</text><rect x=\"550\" y=\"190\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"625.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">publicar</text><text x=\"625.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pika, não visto</text><path d=\"M502 92 L548 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#edge-ah)\"></path><path d=\"M502 152 L548 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#edge-ah)\"></path><path d=\"M502 212 L548 212\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#edge-ah)\"></path></svg>", "caption": "A instrumentação automática desenha as bordas de um serviço: todo lugar em que ele encontra uma biblioteca que alguém instrumentou. O que acontece entre as bordas é assunto do próprio código, e só o código pode dizê-lo.", "same": ["INSERT, UPDATE", "POST /charge", "POST /orders"]}
```

**Ela não sabe do que a requisição tratava.** Estes são todos os atributos que o span
`POST /orders` carregava, só as chaves:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/09839a6961d8e8d4b0f0c10ba65e358c | jq -r '[.data[0].spans[] | select(.operationName == "POST /orders") | .tags[].key] | join(" ")'
otel.scope.name otel.scope.version http.flavor http.host http.method http.route http.scheme http.server_name http.status_code http.target http.user_agent net.host.name net.host.port net.peer.ip net.peer.port span.kind
```

Dezesseis chaves, e fora o nome e a versão do próprio tracer todas falam de HTTP e de rede: o método, a rota, o host, a porta, o endereço do
cliente. Nada diz que pedido era, que produto, quanto, nem se foi pago. O Flask não tem como saber:
um pedido é uma ideia da loja, não do framework web. Então *"mostre os rastros de pedidos de
chaleira"* não tem resposta neste serviço, e a vitrine só conseguia responder porque alguém
escreveu `shop.sku` à mão.

**Ela não atravessa um cliente para o qual não há instrumentação.** O `orders` publica cada pedido
pago no RabbitMQ pelo `pika`, e nenhuma instrumentação para o `pika` está instalada. No laboratório,
duas linhas de `publish()` levam o rastro adiante assim mesmo, escritas à mão. Aqui uma delas é
apagada, para que o serviço fique exatamente como a instrumentação automática sozinha o deixaria.
Guarde uma cópia antes, para devolvê-la depois:

```sh
cp services/orders/app.py /tmp/orders.app.py
```

```
ana@obs:~/shop$ grep -n 'propagate' services/orders/app.py
15:from opentelemetry import propagate
34:    propagate.inject(headers)
ana@obs:~/shop$ sed -i '/propagate.inject(headers)/d' services/orders/app.py && docker compose restart orders 2>&1 | tail -1
 Container shop-orders-1 Started 
```

Um checkout é enviado, e o id de rastro que a vitrine registrou é comparado com o que o mailer
registrou para o mesmo pedido:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r '.trace_id'
a4d8efca1813239ebdbc363181dec65f
ana@obs:~/shop$ docker compose logs --no-log-prefix mailer | grep 'confirmation sent' | tail -1 | jq -r '.trace_id'
ebc950ea40b39675d6cab734439f924f
ana@obs:~/shop$ curl -s localhost:16686/api/traces/ebc950ea40b39675d6cab734439f924f | jq -r '.data[0] as $t | $t.spans[] | [$t.processes[.processID].serviceName, .operationName, (.references | length | tostring) + " parent"] | @tsv'
mailer	send confirmation	1 parent
mailer	orders.placed process	0 parent
```

**Dois ids de rastro diferentes para um checkout**, e o span de consumo do mailer não tem pai: ele
virou a raiz de um rastro próprio. Nada falhou e nada reclamou. O rastro do checkout simplesmente
termina no `orders`, e o e-mail de confirmação vive num rastro que ninguém olhando o checkout vai
achar. A aula 4 é inteira sobre isso, incluindo o pacote de instrumentação que existe para o `pika`
e por que o laboratório escreve as duas linhas em vez de usá-lo.

**Ela não vê dentro das suas próprias funções.** Um laço que recalcula descontos, uma consulta a
um cache num dicionário, uma chamada a uma biblioteca que ninguém instrumentou: para a instrumentação
automática tudo isso é o intervalo entre dois spans. No rastro da aula 1 a parte lenta foi achada
porque o código do payments tinha envolvido a espera num span próprio. Se a espera estivesse lá sem
span em volta, o rastro teria mostrado `POST /charge` levando 1501 ms e nada dentro dele.

Devolva a linha, e reinicie o `orders`, antes de qualquer outra coisa desta aula:

```sh
cp /tmp/orders.app.py services/orders/app.py && docker compose restart orders
```
