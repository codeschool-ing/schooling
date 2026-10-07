---
title: Quando um serviço ignora o flag
version: 2
---

A amostragem na cabeça só funciona se todo serviço obedece à decisão que recebe. **O rastro é guardado
ou descartado inteiro porque o flag viaja com ele**; um serviço com ideia própria quebra isso.

Aqui o `orders` ganha `always_on`, um amostrador que registra tudo e ignora qualquer pai. O override
ganha três linhas:

`~/shop/compose.override.yaml`

```yaml
services:
  storefront:
    environment:
      OTEL_TRACES_SAMPLER: parentbased_traceidratio
      OTEL_TRACES_SAMPLER_ARG: "0.1"
  orders:
    environment:
      OTEL_TRACES_SAMPLER: always_on
```

```sh
docker compose up -d orders
sleep 45
```

E a mesma consulta de dez rastros:

```
ana@obs:~/shop$ for t in $(docker compose logs --no-log-prefix --since 40s --until 15s storefront | grep "checkout finished" | jq -r .trace_id | tail -10); do printf "%s  " $t; curl -s localhost:16686/api/traces/$t | jq -r 'if .data then (.data[0] as $d | ($d.spans | map(.spanID)) as $ids | $d.spans | "\(length) spans, top: " + (map(select(.references == [] or (.references[0].spanID | IN($ids[]) | not))) | map($d.processes[.processID].serviceName + " " + .operationName) | join(", "))) else .errors[0].msg end'; done
508c536069559a630384c004c21965ac  8 spans, top: storefront POST /checkout
343519c740aad67188ebce4635a71211  7 spans, top: orders POST /orders
45d9681906d360b154286e13f2878494  7 spans, top: orders POST /orders
258b73709656841616ed9cb3725dd61a  6 spans, top: storefront POST /checkout
0b899824acab3c9e5fe60223898a2f4b  7 spans, top: orders POST /orders
ca6fc4c07fdec6205252047301f1f2bd  7 spans, top: orders POST /orders
ee87d19b1acc0bf336c7dda29d4f9cf1  7 spans, top: orders POST /orders
608bb9f2ca58bbcccb4448176950ee23  7 spans, top: orders POST /orders
a077ec50a8c43066fff61ebfd2b6bb52  7 spans, top: orders POST /orders
d327f72414490d1217784a591cbcb57e  8 spans, top: storefront POST /checkout
```

Sete dos dez são **rastros sem raiz**: a vitrine os descartou, e o `orders` os registrou mesmo
assim, sete spans do `POST /orders` para baixo. Os outros três estão inteiros, oito spans da vitrine
para baixo, ou seis para um checkout cujo cartão foi recusado e por isso não mandou e-mail. A
vitrine os guardou, e todo serviço obedeceu.

Nada falhou e nenhum serviço registrou reclamação. O armazenamento simplesmente se enche de rastros
que começam no meio: o span de cima deles é o `POST /orders` do `orders`, e ele aponta para um span
pai que nunca foi exportado. O Jaeger avisa sobre o pai ausente na interface. Um painel que conta
rastros os conta como inteiros, e um amostrador na cauda, na seção seguinte, os julgaria sem a raiz.

Isso acontece na prática de três jeitos:

- **Um serviço define o próprio amostrador**, como aqui, normalmente `always_on`, posto por alguém
  depurando o serviço.
- **Um serviço perde o contexto que chega**, o que a aula 4 mostrou como um rastro quebrado, e então
  toma uma decisão de raiz própria.
- **Dois serviços usam frações diferentes com um amostrador que não segue o pai.** Com
  `TraceIdRatioBased` puro em cada um, um serviço de baixo guardando 10% e um de cima guardando 50%
  concordam nos rastros abaixo de 10% e se dividem no resto.

A regra que evita os três: **amostrar na raiz, e usar um amostrador baseado no pai em todo o resto.**
Ele é o padrão em todo SDK por um motivo, e sobrescrevê-lo num serviço é uma decisão sobre todo rastro
que passa por ele.
