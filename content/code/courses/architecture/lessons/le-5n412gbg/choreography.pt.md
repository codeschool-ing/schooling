---
title: Coreografia
version: 1
---

O outro jeito de rodar uma saga não tem orquestrador. Cada serviço escuta os eventos que lhe dizem
respeito, faz o seu passo, e publica o que aconteceu; o próximo serviço reage a isso. **O plano existe só
como a soma das reações**: o estoque reage a `OrderPlaced`, pagamentos a `StockReserved`, entregas a
`PaymentCharged`, e as compensações também são reações, pagamentos a `ShippingFailed` e o estoque a
`PaymentFailed` e `PaymentRefunded`. Olhe a linha `listen(...)` no fim de cada serviço: é a coreografia
inteira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Coreografia. Eventos passam entre três serviços sem orquestrador. OrderPlaced chega ao estoque, que publica StockReserved. Pagamentos reage e publica PaymentCharged. Entregas reage e publica ShippingFailed para uma cidade não atendida. Pagamentos reage reembolsando e publica PaymentRefunded; o estoque reage liberando e publica StockReleased.\"><defs><marker id=\"l14-choreography-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-choreography-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"26\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estoque</text><path d=\"M110 56 L110 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"290\" y=\"26\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pagamentos</text><path d=\"M360 56 L360 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"540\" y=\"26\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entregas</text><path d=\"M610 56 L610 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OrderPlaced →</text><path d=\"M113 96 L357 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-phosphor)\"></path><text x=\"235.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">StockReserved</text><path d=\"M363 132 L607 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-phosphor)\"></path><text x=\"485.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">PaymentCharged</text><path d=\"M607 168 L363 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-amber)\"></path><text x=\"485.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ShippingFailed</text><path d=\"M357 204 L113 204\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-choreography-ah-amber)\"></path><text x=\"235.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">PaymentRefunded</text><text x=\"120\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">StockReleased</text></svg>", "caption": "Numa coreografia cada serviço reage aos eventos anteriores. O plano do checkout existe só como a soma dessas reações."}
```

Faça três pedidos do jeito coreografado: um que dá certo, um para uma cidade sem entregas, e um com
cartão recusado. O `place.py` só publica `OrderPlaced` e termina:

```
ana@vm:~/lab/saga$ $R place.py o-6; $R place.py o-7 --city Noronha; $R place.py o-8 --card 4000-0002
07:34:18.600 checkout: OrderPlaced o-6
07:34:19.755 checkout: OrderPlaced o-7
07:34:20.781 checkout: OrderPlaced o-8
```

Nada na tela diz como eles terminaram. O único jeito de descobrir é juntar os logs dos serviços, em ordem
de tempo:

```
ana@vm:~/lab/saga$ docker compose logs --no-log-prefix stock payments shipping | sort
07:34:18.611 stock: StockReserved o-6
07:34:18.625 payments: PaymentCharged o-6
07:34:18.641 shipping: ShippingScheduled o-6
07:34:19.775 stock: StockReserved o-7
07:34:19.783 payments: PaymentCharged o-7
07:34:19.795 shipping: ShippingFailed o-7
07:34:19.807 payments: PaymentRefunded o-7
07:34:19.820 stock: StockReleased o-7
07:34:20.789 stock: StockReserved o-8
07:34:20.797 payments: PaymentFailed o-8
07:34:20.806 stock: StockReleased o-8
```

O o-6 foi até o fim. O o-7 foi cobrado, falhou na entrega, foi reembolsado, e teve o estoque liberado. O
cartão do o-8 foi recusado e o estoque dele liberado. Os mesmos resultados da saga orquestrada, sem
nenhum componente que conhecesse o plano.

Essa é a força e a fraqueza numa coisa só. **Acrescentar um passo é acrescentar um ouvinte**: um serviço
de fidelidade que dá pontos em `ShippingScheduled` não exige mudança em lugar nenhum. E **ninguém sabe o
estado de um pedido**: para responder "o que aconteceu com o o-7?" você acabou de fazer o que o suporte
teria de fazer, juntar logs de três serviços e lê-los em ordem. O id de correlação da aula 5, levado em
todo evento, é o que torna isso possível; uma coreografia sem ele é um conjunto de logs que ninguém
consegue juntar.
