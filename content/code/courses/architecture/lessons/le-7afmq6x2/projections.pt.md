---
title: Projeções, o lado de leitura
version: 1
---

Reaplicar um fluxo responde perguntas sobre um pedido. Não responde "quantas unidades de chá vendemos",
o que exigiria reaplicar todo pedido a cada requisição. Esse é o trabalho do lado de leitura. Uma
**projeção** lê os eventos em ordem e mantém um modelo de leitura atualizado: aqui `order_summary`, uma
linha por pedido, e `units_sold`, uma linha por produto.

Faça um segundo pedido, depois rode a projeção e olhe o que ela construiu:

```
ana@vm:~/lab/events$ $O place o-2
o-2 v1: OrderPlaced
ana@vm:~/lab/events$ $O add o-2 tea 4
o-2 v2: ItemAdded {"product": "tea", "units": 4}
ana@vm:~/lab/events$ $O project
applied 8 events, checkpoint now at 8
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM order_summary' -c 'SELECT * FROM units_sold'
 id  | status | items | cents 
-----+--------+-------+-------
 o-1 | paid   |     5 |  7950
 o-2 | open   |     4 |  7560
(2 rows)

 product | units 
---------+-------
 coffee  |     2
 rice    |     3
(2 rows)
```

Oito eventos foram aplicados, e o checkpoint registra que a projeção viu até a posição 8. A
`order_summary` tem o formato da página do pedido; a `units_sold` conta só pedidos pagos, então o chá do
o-2 ainda não está nela. Nenhuma das tabelas é fonte de verdade: cada uma é **um cache de uma pergunta,
construído a partir dos eventos**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A projeção lê a tabela de eventos a partir de logo depois do seu checkpoint, a posição 8, até o fim, a posição 9, aplica cada evento aos modelos de leitura, e move o checkpoint para 9, tudo numa transação.\"><defs><marker id=\"l13-projection-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-projection-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">events</text><rect x=\"30\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"74\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"118\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"136\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"162\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"206\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"224\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"250\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"268\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"294\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"312\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><rect x=\"338\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><rect x=\"382\" y=\"48\" width=\"36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">9</text><text x=\"356\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">checkpoint: 8</text><path d=\"M356 90 L356 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-projection-ah-amber)\"></path><rect x=\"460\" y=\"120\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">order_summary</text><text x=\"570\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">units_sold</text><path d=\"M436 80 L436 155 L458 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-projection-ah-phosphor)\"></path><text x=\"250\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma transação: aplicar 9, checkpoint 9</text></svg>", "caption": "Uma projeção é um consumidor com um marcador. Mover o marcador na mesma transação dos modelos de leitura é o que torna uma queda inofensiva."}
```

Agora pague o o-2. Os modelos de leitura não mudam até a projeção rodar de novo, e aí ela aplica só o que
é novo:

```
ana@vm:~/lab/events$ $O pay o-2
o-2 v3: OrderPaid
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM units_sold'
 product | units 
---------+-------
 coffee  |     2
 rice    |     3
(2 rows)

ana@vm:~/lab/events$ $O project
applied 1 events, checkpoint now at 9
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM units_sold'
 product | units 
---------+-------
 coffee  |     2
 rice    |     3
 tea     |     4
(3 rows)
```

Entre o comando e a projeção, a `units_sold` estava errada, e nada nela dizia isso: a janela da aula 9 de
novo, e o motivo de uma tela que mostra um modelo de leitura logo depois de um comando dever usar a
resposta do comando. Em produção uma projeção roda o tempo todo, como consumidora dos eventos, e a janela
é o quanto ela estiver atrasada.

O checkpoint se move **na mesma transação** dos modelos de leitura que descreve. Se a projeção caísse no
meio de um lote, os dois voltariam juntos, e a próxima execução começaria do checkpoint antigo e
aplicaria o lote de novo do zero. Guardar o checkpoint em qualquer outro lugar deixaria uma queda tirar os
dois de sincronia, e um evento seria contado duas vezes ou nenhuma: o problema da aula 7, resolvido do
mesmo jeito.
