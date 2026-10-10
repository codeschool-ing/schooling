---
title: Dois escritores, um pedido
version: 1
---

Um comando carrega o pedido, decide, e acrescenta. Entre carregar e acrescentar, outra pessoa pode ter
acrescentado: um cliente põe café pelo celular enquanto a mesma cesta no notebook põe chá. Numa tabela
comum, o segundo `UPDATE` sobrescreveria o primeiro em silêncio, que é a escrita perdida da aula 9 dentro
de um banco só.

O event sourcing tem uma resposta natural. Todo acréscimo diz **que versão espera estar escrevendo**, e
`UNIQUE (stream, version)` recusa uma segunda versão 2. Faça o o-3, depois mande dois comandos com meio
segundo de diferença, cada um pensando dois segundos entre carregar e acrescentar:

```
ana@vm:~/lab/events$ $O place o-3
o-3 v1: OrderPlaced
ana@vm:~/lab/events$ $O add o-3 tea 2 --think & sleep 0.5; $O add o-3 coffee 1 --think; wait
o-3 v2: ItemAdded {"product": "tea", "units": 2}
o-3: changed by somebody else since version 1; load it and try again

ana@vm:~/lab/events$ $O show o-3
o-3 at v2: open, tea x2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois escritores e um pedido. Os dois carregam o o-3 na versão 1. O primeiro acrescenta a versão 2 e consegue. O segundo também tenta acrescentar a versão 2, a restrição única a recusa, e ele ouve que o pedido mudou desde a versão 1.\"><defs><marker id=\"l13-conflict-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-conflict-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-conflict-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"35\" y=\"26\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escritor A</text><path d=\"M110 56 L110 226\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"285\" y=\"26\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">eventos do o-3</text><path d=\"M360 56 L360 226\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"535\" y=\"26\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escritor B</text><path d=\"M610 56 L610 226\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M357 80 L113 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-conflict-ah-paper-dim)\"></path><text x=\"235\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">carregar: v1</text><path d=\"M363 80 L607 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-conflict-ah-paper-dim)\"></path><text x=\"485\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">carregar: v1</text><path d=\"M113 130 L357 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-conflict-ah-phosphor)\"></path><text x=\"235\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">acrescentar v2</text><text x=\"368\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">v2 gravada</text><path d=\"M607 180 L363 180\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-conflict-ah-amber)\"></path><text x=\"485\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">acrescentar v2</text><text x=\"485\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado: mudou desde v1</text></svg>", "caption": "Concorrência otimista: cada acréscimo diz que versão esperava, e o segundo escritor a chegar é recusado em vez de sobrescrever o primeiro em silêncio."}
```

Os dois carregaram a versão 1. O chá chegou primeiro e virou a versão 2. O acréscimo do café também
reivindicou a versão 2, a restrição o recusou, e o comando disse isso em vez de sobrescrever qualquer
coisa. Isso é **concorrência otimista**: nada fica travado enquanto uma pessoa ou um programa pensa, e a
colisão rara é detectada no fim e devolvida. A resposta de costume é carregar o pedido de novo, conferir
se o comando ainda faz sentido contra o estado novo, e tentar mais uma vez, o que aqui daria certo e
acrescentaria o café como versão 3.

O fluxo é a unidade de consistência. Dentro de um pedido, toda mudança é conferida contra todas as
anteriores; **entre pedidos, nada é**, porque nenhum comando carrega dois fluxos. Uma regra que atravessa
vários fluxos, como "nunca vender mais café do que há no estoque" quando cada pedido é o seu próprio
fluxo, precisa de um fluxo que seja dono da regra (um fluxo de estoque em que todo pedido tem de
acrescentar) ou da saga da aula 14.
