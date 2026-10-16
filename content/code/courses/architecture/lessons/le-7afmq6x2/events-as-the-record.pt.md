---
title: Os eventos como registro
version: 1
---

Numa tabela de pedidos comum, acrescentar um item a um pedido roda um `UPDATE`, e a linha do pedido passa
a dizer o que há nele. O que ela dizia um minuto antes se foi. O **event sourcing** guarda a outra metade:
em vez de guardar o estado atual, guarda **toda mudança como um evento**, em ordem, e nunca muda nem apaga
um. O estado atual é o que você obtém reaplicando-os.

Faça um pedido, mude-o algumas vezes, e pague:

```
ana@vm:~/lab/events$ $O place o-1
o-1 v1: OrderPlaced
ana@vm:~/lab/events$ $O add o-1 coffee 2
o-1 v2: ItemAdded {"product": "coffee", "units": 2}
ana@vm:~/lab/events$ $O add o-1 tea 1
o-1 v3: ItemAdded {"product": "tea", "units": 1}
ana@vm:~/lab/events$ $O remove o-1 tea
o-1 v4: ItemRemoved {"product": "tea"}
ana@vm:~/lab/events$ $O add o-1 rice 3
o-1 v5: ItemAdded {"product": "rice", "units": 3}
ana@vm:~/lab/events$ $O pay o-1
o-1 v6: OrderPaid
ana@vm:~/lab/events$ $O add o-1 tea 1
o-1: is paid, cannot add
```

Cada comando carregou o pedido, conferiu as regras contra ele, e acrescentou um evento com o próximo
número de versão. O último comando foi recusado por uma regra: o pedido estava pago. Agora olhe o que o
banco guarda:

```
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT position, stream, version, type, data FROM events'
 position | stream | version |    type     |               data                
----------+--------+---------+-------------+-----------------------------------
        1 | o-1    |       1 | OrderPlaced | {}
        2 | o-1    |       2 | ItemAdded   | {"units": 2, "product": "coffee"}
        3 | o-1    |       3 | ItemAdded   | {"units": 1, "product": "tea"}
        4 | o-1    |       4 | ItemRemoved | {"product": "tea"}
        5 | o-1    |       5 | ItemAdded   | {"units": 3, "product": "rice"}
        6 | o-1    |       6 | OrderPaid   | {}
(6 rows)
```

Essa tabela é a verdade inteira sobre o pedido, e **não há linha em lugar nenhum dizendo "o-1 está pago
com dois cafés e três arrozes"**. O `show` calcula isso:

```
ana@vm:~/lab/events$ $O show o-1
o-1 at v6: paid, coffee x2, rice x3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O fluxo de eventos do pedido o-1, como seis caixas em fila: v1 OrderPlaced, v2 ItemAdded coffee 2, v3 ItemAdded tea 1, v4 ItemRemoved tea, v5 ItemAdded rice 3, v6 OrderPaid. Embaixo, o estado obtido reaplicando-os: pago, café 2, arroz 3. Uma chave sob os três primeiros mostra que reaplicar só esses dá o pedido como era na versão 3: aberto, café 2, chá 1.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"24\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><text x=\"76\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">OrderPlaced</text><rect x=\"137\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"189\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v2</text><text x=\"189\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemAdded</text><text x=\"189\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">coffee 2</text><rect x=\"250\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"302\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v3</text><text x=\"302\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemAdded</text><text x=\"302\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tea 1</text><rect x=\"363\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v4</text><text x=\"415\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemRemoved</text><text x=\"415\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tea</text><rect x=\"476\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"528\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v5</text><text x=\"528\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemAdded</text><text x=\"528\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rice 3</text><rect x=\"589\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"641\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v6</text><text x=\"641\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">OrderPaid</text><path d=\"M24 118 L24 126 L362 126 L362 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"193\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reaplicar até v3: aberto, café 2, chá 1</text><rect x=\"200\" y=\"168\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">reaplicar tudo: pago, café 2, arroz 3</text></svg>", "caption": "Os eventos são o registro; o estado é um cálculo sobre eles. Pare o cálculo mais cedo e você tem o estado naquele momento."}
```

Os eventos têm nome no passado, `ItemAdded` e não `AddItem`, e isso é uma regra, não um estilo. Um
**comando** é um pedido que pode ser recusado, como o último `add` foi. Um **evento** é um fato que já
aconteceu e nunca é recusado nem mudado: o chá foi acrescentado na versão 3, e a remoção na versão 4 é um
segundo fato, não uma correção do primeiro.

Contadores trabalham assim há séculos. Um livro-razão nunca é editado; um erro é corrigido por um
lançamento novo, e o saldo é uma soma sobre os lançamentos. Os pagamentos da aula 7 já têm essa forma; o
event sourcing aplica a mesma forma a tudo.
