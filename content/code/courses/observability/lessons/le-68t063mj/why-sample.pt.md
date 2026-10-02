---
title: Por que rastros são amostrados
version: 1
---

A aula 1 pôs os rastros na ponta cara da tabela dela: um span por passo, para toda requisição
rastreada. Eis o que isso significa no laboratório, com cinco clientes simulados comprando e todo
rastro guardado:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))'
  4.533333333333333
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  35.53333333333333
```

Uns quatro e meio checkouts por segundo viram 35,5 spans por segundo chegando ao Collector, uns oito
por checkout depois de contadas as recusas, o mailer e as chamadas ao banco. Isso dá uns três
milhões de spans por dia vindos de uma loja quase parada. **Um span é muito maior que uma amostra de
métrica**: leva um nome, dois ids, dois timestamps, um status e todo atributo que alguém
acrescentou.

Três coisas crescem com ele: o trabalho do Collector, a rede entre ele e o armazenamento, e o
armazenamento, que precisa indexar todo span para que as buscas da aula 11 sejam rápidas. Uma
métrica não cresce com o tráfego, como a aula 6 mostrou: o custo dela são as combinações de labels.
Um rastro cresce com cada requisição, e é por isso que **os rastros são o sinal que se amostra**. As
métricas ficam inteiras, e os logs, como mostrou a aula 8, só são raleados nos níveis mais
rotineiros.

Amostrar não é o mesmo que perder dados ao acaso. É uma decisão sobre quais requisições valem ser
guardadas como uma história inteira. O resto da aula trata dos dois lugares onde essa decisão pode
ser tomada: **na cabeça**, quando a requisição começa, e **na cauda**, quando ela terminou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um checkout num eixo de tempo, e o momento em que cada tipo de amostragem decide. A amostragem na cabeça decide no primeiro span da vitrine, antes de orders, payments ou o mailer fazerem qualquer coisa, então não tem como saber se o checkout vai ser lento ou falhar. A decisão viaja no traceparent para todo serviço. A amostragem na cauda decide no Collector depois de uma espera de dez segundos desde o primeiro span do rastro, quando todo span já chegou, então pode guardar erros e rastros lentos.\"><defs><marker id=\"hd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M150 230 L690 230\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#hd-ah)\"></path><text x=\"690\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><text x=\"20\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storefront</text><rect x=\"150.0\" y=\"60\" width=\"176.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"152.0\" y=\"94\" width=\"172.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">payments</text><rect x=\"162.0\" y=\"128\" width=\"160.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mailer</text><rect x=\"330.0\" y=\"162\" width=\"8.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M150 40 L150 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"154\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cabeça: decide aqui, ainda sem saber nada</text><path d=\"M550.0 40 L550.0 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"546.0\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">cauda: decide aqui,</text><text x=\"546.0\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">depois do decision_wait</text><text x=\"170\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a decisão vai no traceparent para todo serviço</text></svg>", "caption": "A amostragem na cabeça decide primeiro e não sabe nada; a da cauda decide por último e sabe tudo, ao preço de segurar todo rastro até lá."}
```

A troca está na figura. A cabeça é o lugar mais barato para decidir, porque um rastro não guardado
não custa nada desde o primeiro span. Mas nada aconteceu ainda, então a decisão não pode depender do
que vai acontecer. A cauda pode guardar exatamente as falhas e as requisições lentas, mas só
recebendo todo span antes.